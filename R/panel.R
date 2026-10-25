#' Attach your own ggplot beside the heatmap
#'
#' Puts any ggplot on one side of the heatmap and lines it up cell by cell.
#' Map the row names (for `"left"` and `"right"`) to `y`, or the column names
#' (for `"top"` and `"bottom"`) to `x`; ggcalor places each name at its row or
#' column, following the clustering, ordering and splits. Everything else
#' (geoms, the value axis, scales, theme, legend) stays as you wrote it.
#'
#' Names in the plot's data that are not in the heatmap are dropped with
#' ggplot2's usual warning. The along axis gets no labels or title of its own:
#' the heatmap's names are drawn once, on the outermost track.
#'
#' @param plot A ggplot with the row or column names mapped to `y` or `x`.
#' @param side `"right"`, `"left"`, `"top"` or `"bottom"`.
#' @param size Panel thickness in millimetres (width for left and right,
#'   height for top and bottom).
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- scale(as.matrix(mtcars[1:12, 1:6]))
#' cars <- data.frame(car = rownames(m), mpg = mtcars$mpg[1:12])
#' bar <- ggplot2::ggplot(cars, ggplot2::aes(mpg, car)) + ggplot2::geom_col()
#' ggcalor(m) + calor_dendro(rows = TRUE) + calor_panel(bar, side = "right")
#' @export
calor_panel <- function(plot, side = c("right", "left", "top", "bottom"), size = 25) {
  if (!ggplot2::is_ggplot(plot)) cli::cli_abort("{.arg plot} must be a ggplot.")
  side <- rlang::arg_match(side)
  structure(list(plot = plot, side = side, size = size), class = "calor_panel")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_panel <- function(object, plot, ...) {
  check_calor(plot, "calor_panel()")
  st <- calor_state(plot)
  tr <- list(name = "", type = "panel", plot = object$plot, side = object$side,
             size = object$size, show_legend = TRUE)
  st$anno[[object$side]] <- c(st$anno[[object$side]], list(tr))
  calor_state(plot) <- st
  plot
}

# The user's plot with its along axis mapped onto the heatmap layout: each
# name sits at its cell's position, gaps between slices included.
panel_plot <- function(tr, lay, cell_mm) {
  along_cols <- tr$side %in% c("top", "bottom")
  pos <- if (along_cols) lay$pos else lay$L + 1 - lay$pos
  args <- list(limits = lay$order, palette = function(n) pos,
               continuous.limits = c(0.5, lay$L + 0.5), expand = c(0, 0))
  along <- if (along_cols) do.call(scale_x_discrete, args) else do.call(scale_y_discrete, args)
  a <- if (along_cols) "x" else "y"
  sides <- if (along_cols) c("top", "bottom") else c("left", "right")
  els <- as.vector(outer(paste0("axis.", c("text", "ticks", "title", "line"), ".", a), sides, paste, sep = "."))
  blank <- stats::setNames(rep(list(element_blank()), length(els)), els)
  p <- tr$plot
  # Replace any along-axis scale the user set; a message about it is noise.
  p@scales <- p@scales$clone()
  p@scales$scales <- Filter(function(s) !a %in% s$aesthetics, p@scales$scales)
  p <- p + along + rlang::inject(theme(!!!blank)) +
    theme(plot.margin = margin(0.5, 0.5, 0.5, 0.5, "mm"))
  p + if (along_cols) {
    theme(panel.widths = grid::unit(lay$L * cell_mm, "mm"), panel.heights = grid::unit(tr$size, "mm"))
  } else {
    theme(panel.heights = grid::unit(lay$L * cell_mm, "mm"), panel.widths = grid::unit(tr$size, "mm"))
  }
}

# Height of a panel's value axis and title, which hang below a side panel.
panel_hang_mm <- function(tr) {
  g <- ggplot2::ggplotGrob(tr$plot)
  b <- max(g$layout$b[grepl("^panel", g$layout$name)])
  below <- g$heights[seq_along(g$heights) > b]
  if (!length(below)) return(0)
  sum(vapply(seq_along(below), function(i) grid::convertHeight(below[i], "mm", valueOnly = TRUE), numeric(1)))
}
