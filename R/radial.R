#' Lay the grid out as a ring
#'
#' Wraps [ggplot2::coord_radial()] with the settings a ring heatmap needs:
#' column labels radiate outward and stay readable, row labels sit in a small
#' gap of the ring, the legend sits below as a slim bar, and the grid is hidden.
#' Anything added afterwards with `theme()` or `guides()` still wins.
#'
#' Dendrograms and annotation tracks are not drawn in a ring.
#'
#' @param inner.radius Hole size as a fraction of the outer radius.
#' @param gap Sector left open, in radians, where the row labels are placed.
#' @param label_size Column label size in points.
#' @param legend Where the legend goes: `"bottom"` (a slim horizontal bar
#'   below the ring), `"right"`, or `"inside"` (in the hole).
#' @param ... Passed to [ggplot2::coord_radial()].
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' ring <- matrix(sample(c("a", "b", NA), 12 * 40, TRUE), 12, 40,
#'                dimnames = list(month.abb, paste0("country ", 1:40)))
#' ggcalor(ring, cell_size = 3, na_fill = "#EFECE6") + calor_radial()
#' ggcalor(global_temp[, 1:60], cell_size = 3) + calor_radial(legend = "right")
#' @export
calor_radial <- function(inner.radius = 0.4, gap = 0.12, label_size = 6,
                         legend = c("bottom", "right", "inside"), ...) {
  legend <- rlang::arg_match(legend)
  structure(list(inner.radius = inner.radius, gap = gap, label_size = label_size,
                 legend = legend, dots = list(...)), class = "calor_radial")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_radial <- function(object, plot, ...) {
  label_size <- object$label_size
  th <- theme(
    axis.text.theta = element_text(size = label_size, colour = calor_ink),
    axis.text.r = element_text(size = label_size - 1, colour = "#5A5A5A"),
    axis.ticks = element_blank(), panel.grid = element_blank(),
    legend.key.size = grid::unit(3, "mm"), legend.text = element_text(size = 7),
    legend.title = element_text(size = 8, face = "bold")
  )
  th <- th + switch(object$legend,
    bottom = theme(legend.position = "bottom", legend.title.position = "top"),
    right = theme(legend.position = "right"),
    inside = theme(legend.position = "inside", legend.position.inside = c(0.5, 0.5))
  )
  coord <- do.call(coord_radial, c(list(inner.radius = object$inner.radius, expand = FALSE,
                                        r.axis.inside = TRUE, start = object$gap / 2,
                                        end = 2 * pi - object$gap / 2), object$dots))
  parts <- list(coord, guides(theta = guide_axis_theta(angle = 90)), th)
  # A continuous fill gets a slim bar that suits the ring instead of the tall
  # default; a scale added later with its own guide still wins.
  st <- if (is_calor(plot)) calor_state(plot)
  if (!is.null(st) && !st$categorical && is.null(st$smooth)) {
    bar <- if (object$legend == "bottom") {
      guide_colourbar(direction = "horizontal", theme = theme(legend.key.width = grid::unit(40, "mm"),
                                                              legend.key.height = grid::unit(2.5, "mm")))
    } else {
      guide_colourbar(theme = theme(legend.key.height = grid::unit(25, "mm"),
                                    legend.key.width = grid::unit(2.5, "mm")))
    }
    parts <- c(parts, list(guides(fill = bar)))
  }
  for (part in parts) plot <- ggplot_add(part, plot, ...)
  plot
}
