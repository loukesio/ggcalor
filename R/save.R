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
  # ragg finds system fonts, so text is measured in the font it is drawn in.
  if (requireNamespace("ragg", quietly = TRUE)) {
    tmp <- tempfile(fileext = ".png")
    ragg::agg_png(tmp)
    on.exit({grDevices::dev.off(); unlink(tmp)}, add = TRUE)
  } else {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off(), add = TRUE)
  }
  g <- ggplot2::ggplotGrob(plot)
  abs_mm <- function(u) sum(vapply(seq_along(u), function(i)
    grid::convertUnit(u[i], "mm", valueOnly = TRUE), numeric(1)))
  sz <- c(abs_mm(g$widths), abs_mm(g$heights))
  # A title wider than the plot does not widen the gtable; the plot stays
  # centred on the page, so add the shortfall on both sides.
  sz[1] <- sz[1] + 2 * max(0, title_width_mm(plot, g) - sz[1])
  # Ring labels radiate beyond the panel and are not part of the gtable sizes.
  if (is_calor(plot) && !plot@coordinates$is_linear()) {
    th <- plot@theme
    size_pt <- th$axis.text.theta$size %||% th$axis.text$size %||% 8
    longest <- max(nchar(colnames(calor_state(plot)$matrix)), 1)
    pad <- longest * size_pt * 0.5 / 72.27 * 25.4 + 1
    sz <- sz + 2 * pad
  }
  # Rotated names of row tracks hang below the layout (patchwork::free), so
  # they are not in the gtable heights; make room for the longest one.
  if (is_calor(plot)) {
    st <- calor_state(plot)
    side_tracks <- c(st$anno$left, st$anno$right)
    names <- unlist(lapply(side_tracks, function(tr) tr$name))
    hang <- 0
    if (length(names) && any(nzchar(names))) {
      hang <- max(nchar(names)) * 7 * 0.55 / 72.27 * 25.4 + 2
      # Bars and boxplots put a value axis between the cells and the name.
      if (any(vapply(side_tracks, function(tr) tr$type %in% c("bar", "boxplot"), logical(1)))) hang <- hang + 6
    }
    # A calor_panel() brings its own value axis and title.
    for (tr in side_tracks) if (identical(tr$type, "panel")) hang <- max(hang, panel_hang_mm(tr))
    below <- sum(vapply(st$anno$bottom, function(tr) tr$size %||% 4, numeric(1)))
    sz[2] <- sz[2] + max(0, hang - below)
  }
  sz
}

# Width of the widest title, subtitle or caption plus the side margins.
title_width_mm <- function(plot, g) {
  idx <- which(g$layout$name %in% c("title", "subtitle", "caption"))
  if (!length(idx)) return(0)
  w <- max(vapply(idx, function(i) grid::convertWidth(grid::grobWidth(g$grobs[[i]]), "mm", valueOnly = TRUE),
                  numeric(1)))
  pm <- calc_element("plot.margin", complete_theme(plot$theme))
  w + grid::convertWidth(pm[2], "mm", valueOnly = TRUE) + grid::convertWidth(pm[4], "mm", valueOnly = TRUE)
}
