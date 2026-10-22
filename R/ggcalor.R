#' Create a heatmap with square cells
#'
#' `ggcalor()` builds a heatmap as a grammar of cells. Cells are square by
#' default and sized in millimetres, so the plot sizes itself instead of the
#' device. The result is a `ggplot` object: add themes, scales, labels, and
#' `calor_*()` verbs with `+`.
#'
#' @param data A numeric or categorical matrix, a wide data frame, or a long
#'   data frame (then give `rows`, `cols`, `value`). Categorical values get a
#'   discrete fill; clustering, ordering and margins then use presence (1/0).
#' @param rows,cols,value Column names for long data. See [calor_matrix()].
#' @param cell_size Cell size in millimetres. Give one number for square cells
#'   or `c(width, height)`.
#' @param cell_gap Gap between cells as a fraction of the cell (0 to 1).
#' @param cell_shape `"square"`, `"circle"` or `"hex"`. Hexagons tile an
#'   offset lattice, so trees and tracks are not drawn with them.
#' @param cell_area Optional matrix of the same shape whose values (scaled to
#'   0 to 1) set each cell's area, for dot plots.
#' @param cell_radius Corner radius of square cells in millimetres.
#' @param scale Scale values by `"row"` or `"column"` before plotting, or
#'   `"none"`.
#' @param scale_method `"zscore"` or `"minmax"`. See [calor_scale()].
#' @param mask Optional logical matrix; `TRUE` cells are hidden (drawn as NA).
#' @param na_fill Fill colour for missing or masked cells.
#' @param border Colour of the cell border, or `NA` for none.
#' @param palette `"auto"` picks a diverging palette when values span zero
#'   and a sequential one otherwise. Any `scale_fill_*()` can be added later
#'   to override.
#' @param raster `"auto"` draws cells as a raster image when the matrix has
#'   more than `raster_threshold` cells, `"always"` or `"never"`. Raster cells
#'   have no gap, border or shape.
#' @param raster_threshold Cell count above which `"auto"` rasterises.
#' @param smooth `"none"` draws cells. `"contour"` interpolates and blurs the
#'   matrix into a surface drawn as filled contour bands; `"raster"` draws the
#'   same surface as a continuous image. Dendrograms and tracks still align.
#' @param smooth_sigma Blur radius in cells.
#' @param smooth_bins Number of contour bands.
#' @param labels Which labels to show: `"both"`, `"rows"`, `"cols"` or `"none"`.
#' @param label_position Where column labels go: `"auto"` (top, or bottom when
#'   a column dendrogram is present), `"top"` or `"bottom"`.
#' @return A `ggplot` object of class `calor`.
#' @examples
#' m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
#' ggcalor(m, cell_size = 6)
#' ggcalor(m, scale = "row") + calor_dendro(rows = TRUE, cols = TRUE, k = 3)
#' @export
ggcalor <- function(data, rows = NULL, cols = NULL, value = NULL,
                    cell_size = 5, cell_gap = 0, cell_shape = c("square", "circle", "hex"),
                    cell_radius = 0, cell_area = NULL,
                    scale = c("none", "row", "column"),
                    scale_method = c("zscore", "minmax"),
                    mask = NULL, na_fill = "grey92", border = "white",
                    palette = "auto", raster = c("auto", "never", "always"),
                    raster_threshold = 20000,
                    smooth = c("none", "contour", "raster"), smooth_sigma = 1, smooth_bins = 9,
                    labels = c("both", "rows", "cols", "none"),
                    label_position = c("auto", "top", "bottom")) {
  scale <- rlang::arg_match(scale)
  cell_shape <- rlang::arg_match(cell_shape)
  raster <- rlang::arg_match(raster)
  label_position <- rlang::arg_match(label_position)
  labels <- rlang::arg_match(labels)
  smooth <- rlang::arg_match(smooth)
  raw <- calor_matrix(data, rows, cols, value)
  categorical <- is.character(raw)
  if (categorical && scale != "none") cli::cli_abort("{.arg scale} needs numeric values.")
  if (categorical && smooth != "none") cli::cli_abort("{.arg smooth} needs numeric values.")
  m <- if (categorical) raw else calor_scale(raw, scale, scale_method)
  num <- numeric_proxy(m)   # clustering and ordering ignore the mask
  if (!is.null(mask)) {
    if (!identical(dim(mask), dim(m))) cli::cli_abort("{.arg mask} must have the same dimensions as the data.")
    m[mask] <- NA
  }
  if (length(cell_size) == 1) cell_size <- c(cell_size, cell_size)
  long <- matrix_to_long(m)
  if (!is.null(cell_area)) {
    if (!identical(dim(cell_area), dim(m))) cli::cli_abort("{.arg cell_area} must have the same dimensions as the data.")
    a <- as.vector(cell_area)
    long$.area <- (a - min(a, na.rm = TRUE)) / diff(range(a, na.rm = TRUE))
  }
  hex <- cell_shape == "hex"
  if (hex) long <- hex_positions(long, rownames(m), colnames(m))

  use_raster <- raster == "always" || (raster == "auto" && length(m) > raster_threshold)
  cells <- if (use_raster) {
    geom_raster()
  } else {
    geom_cell(shape = cell_shape, gap = cell_gap, radius = cell_radius,
              colour = border, linewidth = if (is.na(border)) 0 else 0.3)
  }
  if (!is.null(cell_area)) cells$mapping <- aes(area = .data$.area)
  if (smooth != "none") {
    sm <- list(type = smooth, sigma = smooth_sigma, bins = smooth_bins, upsample = 8)
    cells <- smooth_layer(smooth_field(m, sm), sm)
    keep <- function(x, ...) x   # never drop the surface's edge pixels
    scales <- list(
      scale_x_continuous(expand = c(0, 0), limits = c(0.5, ncol(m) + 0.5), breaks = seq_len(ncol(m)), labels = colnames(m),
                         oob = keep, position = if (label_position == "bottom") "bottom" else "top"),
      scale_y_continuous(expand = c(0, 0), limits = c(0.5, nrow(m) + 0.5), breaks = seq_len(nrow(m)), labels = rev(rownames(m)),
                         oob = keep)
    )
    mapping <- aes(x = .data$.col, y = .data$.row, fill = .data$.value)
    sizes <- theme(panel.widths = grid::unit(ncol(m) * cell_size[1], "mm"),
                   panel.heights = grid::unit(nrow(m) * cell_size[2], "mm"))
  } else if (hex) {
    hx <- hex_extent(nrow(m), ncol(m))
    scales <- list(
      scale_x_continuous(expand = c(0, 0), limits = hx$xlim, breaks = seq_len(ncol(m)) + 0.25, labels = colnames(m),
                         position = if (label_position == "bottom") "bottom" else "top"),
      scale_y_continuous(expand = c(0, 0), limits = hx$ylim, breaks = hx$ypos, labels = rownames(m))
    )
    mapping <- aes(x = .data$.x, y = .data$.y, fill = .data$.value)
    sizes <- theme(panel.widths = grid::unit(diff(hx$xlim) * cell_size[1], "mm"),
                   panel.heights = grid::unit(diff(hx$ylim) * cell_size[2], "mm"))
  } else {
    scales <- list(
      scale_x_discrete(expand = c(0, 0), position = if (label_position == "bottom") "bottom" else "top"),
      scale_y_discrete(expand = c(0, 0), limits = rev)
    )
    mapping <- aes(x = .data$.col, y = .data$.row, fill = .data$.value)
    sizes <- theme(panel.widths = grid::unit(ncol(m) * cell_size[1], "mm"),
                   panel.heights = grid::unit(nrow(m) * cell_size[2], "mm"))
  }
  p <- ggplot(long, mapping) +
    cells +
    scales +
    coord_cartesian(clip = "off") +
    labs(x = NULL, y = NULL, fill = "value") +
    theme_calor() +
    sizes

  if (labels %in% c("rows", "none")) {
    p <- p + theme(axis.text.x.top = element_blank(), axis.text.x.bottom = element_blank())
  }
  if (labels %in% c("cols", "none")) p <- p + theme(axis.text.y = element_blank())

  if (categorical) {
    # Keep NA out of the legend but still paint the cells.
    p <- p + scale_fill_calor_d(na.value = na_fill, na.translate = TRUE, limits = function(l) l[!is.na(l)])
  } else if (smooth == "contour") {
    p <- p + scale_fill_viridis_d(option = "turbo") + labs(fill = "value")
  } else if (identical(palette, "auto")) {
    rng <- range(m, na.rm = TRUE)
    p <- p + if (rng[1] < 0 && rng[2] > 0) {
      scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7", high = "#B2182B",
                           na.value = na_fill, guide = calor_colourbar())
    } else {
      scale_fill_viridis_c(option = "inferno", direction = -1, na.value = na_fill,
                           guide = calor_colourbar())
    }
  }

  class_calor(p, calor = list(
    matrix = m,
    raw = raw,
    num = num,
    categorical = categorical,
    cell_size = cell_size,
    cell = list(shape = cell_shape, gap = cell_gap, radius = cell_radius, border = border,
                raster = use_raster),
    smooth = if (smooth != "none") list(type = smooth, sigma = smooth_sigma, bins = smooth_bins, upsample = 8),
    label_position = label_position,
    row_order = rownames(m),
    col_order = colnames(m),
    order = list(rows = NULL, cols = NULL),
    dendro = list(rows = NULL, cols = NULL),
    split = list(rows = NULL, cols = NULL, gap = 1.5, labels = TRUE),
    anno = list(top = list(), bottom = list(), left = list(), right = list()),
    text = NULL,
    legend = list(type = "colourbar"),
    labels = list(rows = "auto", cols = "auto", style = NULL),
    interactive = NULL
  ))
}

#' A minimal theme for cell grids
#'
#' No grid, no axis lines, tick-less labels, legend on the right.
#' @param base_size Base font size.
#' @param base_family Base font family.
#' @return A theme object.
#' @export
theme_calor <- function(base_size = 10, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid = element_blank(),
      axis.ticks = element_blank(),
      axis.text = element_text(size = rel(0.8), colour = "grey20"),
      axis.text.y.left = element_text(hjust = 1, margin = margin(r = 2.5)),
      axis.text.y.right = element_text(hjust = 0, margin = margin(l = 2.5)),
      axis.text.x.top = element_text(angle = 90, hjust = 0, vjust = 0.5, margin = margin(b = 2.5)),
      axis.text.x.bottom = element_text(angle = 90, hjust = 1, vjust = 0.5, margin = margin(t = 2.5)),
      legend.key.size = grid::unit(4, "mm"),
      legend.title = element_text(size = rel(0.9), colour = "grey10"),
      legend.text = element_text(size = rel(0.8), colour = "grey20"),
      legend.spacing.y = grid::unit(3, "mm"),
      strip.text = element_text(size = rel(0.75), colour = "grey45", margin = margin(2, 2, 2, 2)),
      strip.background = element_blank(),
      strip.text.y = element_text(angle = -90),
      strip.placement = "outside",
      plot.background = element_rect(fill = "white", colour = NA),
      plot.margin = margin(5, 5, 5, 5)
    )
}

# Offset lattice for hexagons: odd rows shift right by half a cell, rows are
# sqrt(3)/2 apart. Row 1 is at the top.
hex_positions <- function(long, row_order, col_order) {
  i <- match(as.character(long$.row), row_order)
  j <- match(as.character(long$.col), col_order)
  n <- length(row_order)
  long$.x <- j + 0.5 * ((i - 1) %% 2)
  long$.y <- (n - i) * sqrt(3) / 2 + 1
  long
}
hex_extent <- function(nrow, ncol) {
  r <- 1 / sqrt(3)
  ypos <- (nrow - seq_len(nrow)) * sqrt(3) / 2 + 1
  list(xlim = c(0.5, ncol + 1), ylim = c(1 - r, max(ypos) + r), ypos = ypos)
}

#' Colour bar guide used by ggcalor
#'
#' A tall, narrow colour bar. Pass it as `guide` to any continuous fill scale
#' you add, to keep the look.
#' @param height,width Bar size in millimetres.
#' @param ... Passed to [ggplot2::guide_colourbar()].
#' @export
calor_colourbar <- function(height = 45, width = 3.5, ...) {
  guide_colourbar(theme = theme(legend.key.height = grid::unit(height, "mm"),
                                legend.key.width = grid::unit(width, "mm")), order = 1, ...)
}
