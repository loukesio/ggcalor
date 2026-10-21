#' Cells: the geom behind ggcalor
#'
#' Draws one cell per (x, y) as a square, a rounded square or a circle. Used by
#' [ggcalor()]; exported so it can be reused on any discrete grid.
#'
#' @inheritParams ggplot2::geom_tile
#' @param shape `"square"`, `"circle"` or `"hex"` (pointy-top hexagons;
#'   [ggcalor()] lays the rows out in an offset lattice for these).
#' @param gap Gap between cells as a fraction of the cell (0 to 1).
#' @param radius Corner radius in millimetres for square cells.
#' @export
geom_cell <- function(mapping = NULL, data = NULL, stat = "identity",
                      position = "identity", ..., shape = "square", gap = 0,
                      radius = 0, na.rm = FALSE, show.legend = NA,
                      inherit.aes = TRUE) {
  layer(
    data = data, mapping = mapping, stat = stat, geom = GeomCell,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(shape = shape, gap = gap, radius = radius, na.rm = na.rm, ...)
  )
}

#' @rdname geom_cell
#' @format NULL
#' @usage NULL
#' @export
GeomCell <- ggproto("GeomCell", Geom,
  required_aes = c("x", "y"),
  default_aes = aes(fill = "grey70", colour = "white", linewidth = 0.3,
                    linetype = 1, alpha = NA, area = 1),
  draw_key = draw_key_rect,

  setup_data = function(data, params) {
    # `area` shrinks a cell: radius scales with sqrt(area) so area is honest.
    area <- data$area %||% 1
    half <- (1 - params$gap) / 2 * sqrt(pmin(pmax(area, 0.02), 1))
    data$xmin <- data$x - half; data$xmax <- data$x + half
    data$ymin <- data$y - half; data$ymax <- data$y + half
    data
  },

  draw_panel = function(self, data, panel_params, coord, shape = "square",
                        gap = 0, radius = 0, lineend = "butt", linejoin = "mitre") {
    if (!coord$is_linear()) {
      # Polar and other non-linear coords: let GeomRect munch the cells.
      return(GeomRect$draw_panel(data, panel_params, coord, lineend = lineend, linejoin = linejoin))
    }
    coords <- coord$transform(data, panel_params)
    gp <- grid::gpar(
      col = coords$colour, fill = fill_alpha(coords$fill, coords$alpha),
      lwd = coords$linewidth * .pt, lty = coords$linetype,
      lineend = lineend, linejoin = linejoin
    )
    cx <- (coords$xmin + coords$xmax) / 2
    cy <- (coords$ymin + coords$ymax) / 2
    w <- coords$xmax - coords$xmin
    h <- coords$ymax - coords$ymin
    if (shape == "circle") {
      return(grid::circleGrob(cx, cy, r = grid::unit(w / 2, "npc"), gp = gp))
    }
    if (shape == "hex") {
      # Pointy-top hexagon of width w: radius w / sqrt(3), six vertices.
      ang <- pi / 6 + (0:5) * pi / 3
      r <- (data$xmax - data$xmin) / 2 / sqrt(3) * 2  # in data units: width/sqrt(3)
      hex <- data.frame(
        x = rep(data$x, each = 6) + rep(r, each = 6) * cos(ang),
        y = rep(data$y, each = 6) + rep(r, each = 6) * sin(ang),
        id = rep(seq_along(data$x), each = 6)
      )
      hc <- coord$transform(hex, panel_params)
      return(grid::polygonGrob(hc$x, hc$y, id = hc$id, default.units = "npc", gp = gp))
    }
    if (radius > 0) {
      grobs <- lapply(seq_along(cx), function(i) grid::roundrectGrob(
        cx[i], cy[i], width = w[i], height = h[i], r = grid::unit(radius, "mm"),
        default.units = "npc",
        gp = grid::gpar(col = gp$col[i], fill = gp$fill[i], lwd = gp$lwd[i], lty = gp$lty[i])
      ))
      return(do.call(grid::grobTree, grobs))
    }
    grid::rectGrob(cx, cy, width = w, height = h, default.units = "npc", gp = gp)
  }
)
