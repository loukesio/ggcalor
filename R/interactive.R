#' Interactive cells with ggiraph
#'
#' Turns the cells into 'ggiraph' interactive tiles with tooltips and linked
#' highlighting. Render with [calor_girafe()] or [ggiraph::girafe()].
#'
#' @param tooltip `NULL` for "row, column, value", or a function of
#'   `(row, col, value)` returning a character vector.
#' @param data_id What highlights together on hover: `"cell"`, `"row"` or
#'   `"col"`.
#' @param tracks Make categorical annotation tracks interactive too. With
#'   `data_id = "row"` or `"col"`, hovering a track cell highlights its row or
#'   column in the heatmap.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' if (requireNamespace("ggiraph", quietly = TRUE)) {
#'   m <- matrix(rnorm(50), 10, 5, dimnames = list(paste0("g", 1:10), paste0("s", 1:5)))
#'   p <- ggcalor(m) + calor_interactive(data_id = "row")
#'   calor_girafe(p)
#' }
#' @export
calor_interactive <- function(tooltip = NULL, data_id = c("cell", "row", "col"), tracks = TRUE) {
  data_id <- rlang::arg_match(data_id)
  rlang::check_installed("ggiraph", reason = "for interactive heatmaps.")
  structure(list(tooltip = tooltip, data_id = data_id, tracks = tracks), class = "calor_interactive")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_interactive <- function(object, plot, ...) {
  check_calor(plot, "calor_interactive()")
  st <- calor_state(plot)
  st$interactive <- unclass(object)
  calor_state(plot) <- st
  plot
}

# Replace the cell layer with an interactive tile layer at build time.
apply_interactive <- function(base, st, lr, lc) {
  it <- st$interactive
  if (is.null(it)) return(base)
  d <- base@data
  d$.tooltip <- if (is.function(it$tooltip)) {
    it$tooltip(as.character(d$.row), as.character(d$.col), d$.value)
  } else {
    val <- if (is.numeric(d$.value)) formatC(d$.value, digits = 3, format = "g") else as.character(d$.value)
    paste0(d$.row, "\n", d$.col, "\n", val)
  }
  d$.data_id <- switch(it$data_id,
    cell = paste(d$.row, d$.col, sep = "\r"),
    row = as.character(d$.row),
    col = as.character(d$.col)
  )
  base@data <- d
  cell <- st$cell
  if (identical(cell$shape, "square") && is.null(st$smooth)) {
    base@layers[[1]] <- ggiraph::geom_tile_interactive(
      aes(tooltip = .data$.tooltip, data_id = .data$.data_id),
      width = 1 - cell$gap, height = 1 - cell$gap, colour = cell$border,
      linewidth = if (is.na(cell$border)) 0 else 0.3
    )
  } else {
    # Circles, hexagons and smooth surfaces keep their own drawing; a clear
    # tile on top carries the tooltip, and calor_girafe() veils the rest.
    mapping <- aes(tooltip = .data$.tooltip, data_id = .data$.data_id)
    if (!is.null(st$smooth)) {
      # Smooth surfaces sit on numeric positions: columns left to right, rows
      # top to bottom.
      d$.sx <- match(as.character(d$.col), lc$order)
      d$.sy <- length(lr$order) + 1 - match(as.character(d$.row), lr$order)
      base@data <- d
      mapping <- aes(x = .data$.sx, y = .data$.sy, tooltip = .data$.tooltip, data_id = .data$.data_id)
    }
    base <- base + interactive_overlay(mapping, height = if (identical(cell$shape, "hex")) sqrt(3) / 2 else 1)
  }
  base
}

# A see-through interactive tile layer that only carries hover and tooltip.
interactive_overlay <- function(mapping, width = 1, height = 1, data = NULL) {
  ggiraph::geom_tile_interactive(mapping, data = data, width = width, height = height,
                                 fill = "white", alpha = 0, colour = NA)
}

#' Render an interactive heatmap
#'
#' Wraps [ggiraph::girafe()] with the plot's natural size and hover styling
#' that dims everything except the hovered cells.
#'
#' @param plot A [ggcalor()] plot with [calor_interactive()].
#' @param ... Passed to [ggiraph::girafe()].
#' @param hover_css CSS for hovered cells; `NULL` picks a default.
#' @param dim_css CSS for the other cells while hovering; `NULL` fades them,
#'   or veils them in white for waffles, hex and circle cells and smooth
#'   surfaces.
#' @return A 'girafe' htmlwidget.
#' @export
calor_girafe <- function(plot, ..., hover_css = NULL, dim_css = NULL) {
  rlang::check_installed("ggiraph", reason = "for interactive heatmaps.")
  # Plots drawn under a clear overlay (waffles, hex and circle cells, smooth
  # surfaces) dim by veiling the other cells in white instead of fading them.
  overlay <- if (is_calor(plot)) {
    !identical(calor_state(plot)$cell$shape, "square") || !is.null(calor_state(plot)$smooth)
  } else {
    any(vapply(plot@layers, function(l) inherits(l$geom, "GeomInteractiveTile") &&
                 identical(l$aes_params$alpha, 0), logical(1)))
  }
  hover_css <- hover_css %||% if (overlay) "stroke:#2B2B2B;stroke-width:1.2px;" else "stroke:black;stroke-width:1.2px;"
  dim_css <- dim_css %||% if (overlay) "fill:white;fill-opacity:0.6;" else "opacity:0.35;"
  sz <- calor_size(plot) / 25.4
  ggiraph::girafe(ggobj = plot, width_svg = sz[1] + 0.2, height_svg = sz[2] + 0.2, ...,
                  options = list(ggiraph::opts_hover(css = hover_css),
                                 ggiraph::opts_hover_inv(css = dim_css),
                                 ggiraph::opts_sizing(rescale = FALSE)))
}
