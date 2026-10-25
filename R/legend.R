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
  if (identical(object$type, "histogram") && isTRUE(st$categorical)) {
    cli::cli_abort("{.code calor_legend(\"histogram\")} needs numeric values; this heatmap is categorical.")
  }
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
  nb <- length(h$breaks)
  bars <- data.frame(xmin = h$breaks[-nb], xmax = h$breaks[-1], y = h$counts, fill = sc$map(h$mids))
  xs <- seq(lim[1], lim[2], length.out = 129)
  strip_h <- max(h$counts) * 0.16
  strip <- data.frame(xmin = xs[-129], xmax = xs[-1], fill = sc$map((xs[-129] + xs[-1]) / 2))
  br <- sc$get_breaks(); br <- br[!is.na(br)]
  labels <- sc$get_labels(br)
  count_breaks <- function(l) {
    b <- scales::breaks_extended(n = 3)(c(0, l[2]))
    b[b > 0 & b <= l[2]]
  }
  mt <- complete_theme(main@theme)
  txt <- calc_element("legend.text", mt)
  txt$size <- txt$size * 0.85
  line <- element_line(colour = "grey55", linewidth = 0.3)
  p <- ggplot() +
    # Outlines in the fill colour close the hairline seams between bins.
    geom_rect(data = bars, aes(xmin = .data$xmin, xmax = .data$xmax, ymin = 0, ymax = .data$y, fill = .data$fill),
              colour = bars$fill, linewidth = 0.2) +
    geom_rect(data = strip, aes(xmin = .data$xmin, xmax = .data$xmax, fill = .data$fill),
              ymin = -strip_h, ymax = 0, colour = strip$fill, linewidth = 0.2) +
    annotate("segment", x = lim[1], xend = lim[2], y = 0, yend = 0, colour = "white", linewidth = 0.4) +
    scale_fill_identity() +
    scale_x_continuous(breaks = br, labels = labels, limits = lim, expand = c(0, 0)) +
    scale_y_continuous(limits = c(-strip_h, max(h$counts) * 1.04), breaks = count_breaks,
                       expand = c(0, 0), name = "count") +
    theme_void() +
    theme(axis.text.x = txt, axis.text.x.bottom = element_text(margin = margin(t = 1)),
          axis.text.y = txt, axis.text.y.left = element_text(hjust = 1, margin = margin(r = 1)),
          axis.title.y = element_text(size = txt$size, colour = txt$colour, angle = 90, margin = margin(r = 2)),
          axis.ticks = line, axis.line.y = line,
          axis.ticks.length = grid::unit(0.7, "mm"),
          panel.widths = grid::unit(lg$width, "mm"), panel.heights = grid::unit(lg$height, "mm"),
          plot.margin = margin(0, 1, 0, 0))
  title <- main@labels$fill %||% "value"
  if (is.function(title)) title <- title("value")
  gt <- ggplotGrob(p)
  w <- sum(grid::convertWidth(gt$widths, "mm", valueOnly = TRUE))
  hh <- sum(grid::convertHeight(gt$heights, "mm", valueOnly = TRUE))
  main + guides(fill = "none", custom = guide_custom(
    gt, title = title, order = 1,
    width = grid::unit(w, "mm"), height = grid::unit(hh, "mm")
  ))
}
