#' Histogram legend
#'
#' Replace the colour bar with a histogram of the values, coloured by the fill
#' scale and with the colour strip underneath. It joins the other legends.
#'
#' @param type `"histogram"` or `"colourbar"` (the default legend).
#' @param width,height Legend size in millimetres.
#' @param bins Number of histogram bins.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
#' ggcalor(m) + calor_legend("histogram")
#' @export
calor_legend <- function(type = c("histogram", "colourbar"), width = 32, height = 18, bins = 30) {
  type <- rlang::arg_match(type)
  structure(list(type = type, width = width, height = height, bins = bins), class = "calor_legend")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_legend <- function(object, plot, ...) {
  check_calor(plot, "calor_legend()")
  st <- calor_state(plot)
  st$legend <- unclass(object)
  calor_state(plot) <- st
  plot
}

# Swap the fill colourbar of `main` for a histogram legend drawn with the
# plot's own (trained) fill scale.
apply_histogram_legend <- function(main, st) {
  lg <- st$legend
  if (!identical(lg$type, "histogram")) return(main)
  sc <- main@scales$get_scales("fill")
  if (is.null(sc)) return(main)
  sc <- sc$clone()
  v <- as.vector(st$matrix); v <- v[is.finite(v)]
  sc$train(range(v))
  lim <- sc$get_limits()
  v <- pmin(pmax(v, lim[1]), lim[2])
  h <- graphics::hist(v, breaks = seq(lim[1], lim[2], length.out = lg$bins + 1), plot = FALSE)
  bars <- data.frame(x = h$mids, y = h$counts, w = diff(h$breaks), fill = sc$map(h$mids))
  xs <- seq(lim[1], lim[2], length.out = 128)
  strip_h <- max(h$counts) * 0.18
  strip <- data.frame(x = xs, fill = sc$map(xs))
  br <- sc$get_breaks(); br <- br[!is.na(br)]
  labels <- sc$get_labels(br)
  p <- ggplot() +
    geom_col(data = bars, aes(x = .data$x, y = .data$y, fill = .data$fill, width = .data$w), colour = NA) +
    geom_tile(data = strip, aes(x = .data$x, y = -strip_h / 2, fill = .data$fill),
              width = diff(xs)[1] * 1.05, height = strip_h, colour = NA) +
    scale_fill_identity() +
    scale_x_continuous(breaks = br, labels = labels, limits = lim, expand = c(0, 0)) +
    scale_y_continuous(limits = c(-strip_h, max(h$counts) * 1.05), expand = c(0, 0)) +
    theme_void() +
    theme(axis.text.x = element_text(size = 6.5, colour = "grey20", margin = margin(t = 1)),
          axis.ticks.x = element_line(colour = "grey40", linewidth = 0.3),
          axis.ticks.length.x = grid::unit(0.8, "mm"),
          panel.widths = grid::unit(lg$width, "mm"), panel.heights = grid::unit(lg$height, "mm"),
          plot.margin = margin(1, 2, 1, 2))
  title <- main@labels$fill %||% "value"
  if (is.function(title)) title <- title("value")
  main + guides(fill = "none", custom = guide_custom(
    ggplotGrob(p), title = title,
    width = grid::unit(lg$width + 4, "mm"), height = grid::unit(lg$height + 5, "mm")
  ))
}
