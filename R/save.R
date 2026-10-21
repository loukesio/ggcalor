#' Save a heatmap at its natural size
#'
#' Computes the device size from the cell size, trees, labels and legend, so
#' the file holds exactly the plot you built. Extra arguments go to
#' [ggplot2::ggsave()].
#'
#' @param plot A [ggcalor()] plot.
#' @param filename Output path; the extension picks the device.
#' @param pad Extra space around the plot, in millimetres.
#' @param ... Passed to [ggplot2::ggsave()], e.g. `dpi`.
#' @return The filename, invisibly.
#' @export
calor_save <- function(plot, filename, pad = 2, ...) {
  sz <- calor_size(plot)
  ggplot2::ggsave(filename, plot, width = sz[1] + 2 * pad, height = sz[2] + 2 * pad,
                  units = "mm", ...)
  invisible(filename)
}

#' Natural size of a heatmap in millimetres
#'
#' @param plot A [ggcalor()] plot.
#' @return A numeric vector `c(width, height)` in millimetres.
#' @export
calor_size <- function(plot) {
  # Building a grob needs a device; use a throwaway one so no Rplots.pdf appears.
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  g <- ggplot2::ggplotGrob(plot)
  abs_mm <- function(u) sum(vapply(seq_along(u), function(i)
    grid::convertUnit(u[i], "mm", valueOnly = TRUE), numeric(1)))
  sz <- c(abs_mm(g$widths), abs_mm(g$heights))
  # Ring labels radiate beyond the panel and are not part of the gtable sizes.
  if (is_calor(plot) && !plot@coordinates$is_linear()) {
    th <- plot@theme
    size_pt <- th$axis.text.theta$size %||% th$axis.text$size %||% 8
    longest <- max(nchar(colnames(calor_state(plot)$matrix)), 1)
    pad <- longest * size_pt * 0.5 / 72.27 * 25.4 + 1
    sz <- sz + 2 * pad
  }
  sz
}
