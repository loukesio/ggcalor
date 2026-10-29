#' The heatmap as a table with the cells as its panel
#'
#' Returns a gtable shaped like an ordinary ggplot whose only panel, named
#' `"panel"`, covers exactly the cells, while trees, tracks, names and legends
#' sit in the axis space around it. Tools that place or connect ggplots by
#' their panel, such as ggweave, can then treat a ggcalor plot like any other
#' plot. Cell coordinates run from 0.5 to the number of columns (or rows) plus
#' any split gaps, plus 0.5, and are stored in the `"calor_ranges"` attribute.
#'
#' @param plot A [ggcalor()] plot.
#' @return A gtable.
#' @seealso [calor_anchors()] for the positions of named rows and columns.
#' @examples
#' m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
#' g <- calor_gtable(ggcalor(m) + calor_dendro(rows = TRUE))
#' attr(g, "calor_ranges")
#' @export
calor_gtable <- function(plot) {
  check_calor(plot, "calor_gtable()")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  built <- ggplot2::ggplot_build(plot)
  cells_table(built, calor_compose(built), theme = plot@theme)
}

#' Positions of rows and columns, for connecting plots
#'
#' Gives the position of named rows or columns in the cell coordinates of
#' [calor_gtable()], after clustering, ordering and splitting, on one edge of
#' the cells. Use it as the anchors of a ggcalor plot in ggweave, to draw
#' threads from a row or column to the same item in another plot.
#'
#' @param plot A [ggcalor()] plot.
#' @param rows,cols Names of rows or columns. Give one of them.
#' @param side Edge of the cells the anchors sit on: `"left"` or `"right"` for
#'   rows (default `"right"`), `"top"` or `"bottom"` for columns (default
#'   `"bottom"`), or `"centre"` for the middle of the row or column.
#' @param outside If `TRUE` (default), anchors on an edge sit beyond the trees
#'   and tracks on that side, so threads do not cross them.
#' @param id Name of the identifier column.
#' @return A data frame with columns `id`, `x` and `y`.
#' @examples
#' m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
#' p <- ggcalor(m) + calor_dendro(rows = TRUE)
#' calor_anchors(p, rows = c("a", "c"))
#' @export
calor_anchors <- function(plot, rows = NULL, cols = NULL, side = NULL, outside = TRUE, id = "id") {
  check_calor(plot, "calor_anchors()")
  if (is.null(rows) == is.null(cols)) cli::cli_abort("Give one of {.arg rows} or {.arg cols}.")
  st <- calor_state(plot)
  lay <- resolve_layout(st)$lay
  lr <- lay$rows; lc <- lay$cols
  # Depth of the trees and tracks on one side, in cell units across that side.
  beyond <- function(side) {
    if (!outside) return(0)
    lay_s <- if (side %in% c("left", "right")) lc else lr
    tree <- (side == "left" && lr$show_tree) || (side == "top" && lc$show_tree)
    tree_mm <- if (tree) (if (side == "left") lr else lc)$dspec$size else 0
    tracks_mm <- sum(vapply(st$anno[[side]], function(tr) tr$size %||% 4, numeric(1)))
    (tree_mm + tracks_mm) / lay_s$cell_mm
  }
  if (!is.null(rows)) {
    side <- side %||% "right"
    side <- rlang::arg_match(side, c("right", "left", "centre"))
    miss <- setdiff(rows, lr$order)
    if (length(miss)) cli::cli_abort("Not rows of the heatmap: {.val {miss}}.")
    y <- lr$L + 1 - lr$pos[match(rows, lr$order)]
    x <- switch(side, right = lc$L + 0.5 + beyond("right"), left = 0.5 - beyond("left"),
                centre = (lc$L + 1) / 2)
    out <- data.frame(rows, x = x, y = y)
  } else {
    side <- side %||% "bottom"
    side <- rlang::arg_match(side, c("bottom", "top", "centre"))
    miss <- setdiff(cols, lc$order)
    if (length(miss)) cli::cli_abort("Not columns of the heatmap: {.val {miss}}.")
    x <- lc$pos[match(cols, lc$order)]
    y <- switch(side, bottom = 0.5 - beyond("bottom"), top = lr$L + 0.5 + beyond("top"),
                centre = (lr$L + 1) / 2)
    out <- data.frame(cols, x = x, y = y)
  }
  names(out)[1] <- id
  out
}
