#' Lay the grid out as a ring
#'
#' Wraps [ggplot2::coord_radial()] with the settings a ring heatmap needs:
#' column labels radiate outward and stay readable, row labels sit in a small
#' gap of the ring, the legend goes in the hole, and the grid is hidden.
#' Anything added afterwards with `theme()` or `guides()` still wins.
#'
#' Dendrograms and annotation tracks are not drawn in a ring.
#'
#' @param inner.radius Hole size as a fraction of the outer radius.
#' @param gap Sector left open, in radians, where the row labels are placed.
#' @param label_size Column label size in points.
#' @param legend `"inside"` (in the hole) or `"outside"` (ggplot2's default
#'   placement).
#' @param ... Passed to [ggplot2::coord_radial()].
#' @return A list of components to add to a [ggcalor()] plot with `+`.
#' @examples
#' ring <- matrix(sample(c("a", "b", NA), 12 * 40, TRUE), 12, 40,
#'                dimnames = list(month.abb, paste0("country ", 1:40)))
#' ggcalor(ring, cell_size = 3, border = "grey85", na_fill = "white") + calor_radial()
#' @export
calor_radial <- function(inner.radius = 0.4, gap = 0.12, label_size = 6,
                         legend = c("inside", "outside"), ...) {
  legend <- rlang::arg_match(legend)
  th <- theme(
    axis.text.theta = element_text(size = label_size, colour = "grey30"),
    axis.text.r = element_text(size = label_size - 1, colour = "grey50"),
    axis.ticks = element_blank(), panel.grid = element_blank(),
    legend.key.size = grid::unit(3, "mm"), legend.text = element_text(size = 7),
    legend.title = element_text(size = 8)
  )
  if (legend == "inside") {
    th <- th + theme(legend.position = "inside", legend.position.inside = c(0.5, 0.5))
  }
  list(
    coord_radial(inner.radius = inner.radius, expand = FALSE, r.axis.inside = TRUE,
                 start = gap / 2, end = 2 * pi - gap / 2, ...),
    guides(theta = guide_axis_theta(angle = 90)),
    th
  )
}
