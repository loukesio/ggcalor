#' Place and style row and column names
#'
#' Row names sit next to the cells, or outside the tracks on the chosen side;
#' column names the same. The style applies to both and is inherited by the
#' track names, so one call sets the typography of the whole figure. Anything
#' added later with `theme(axis.text = ...)` still wins.
#'
#' @param rows `"auto"`, `"left"`, `"right"` or `"none"`. Auto keeps names on
#'   the side without tracks, else outside the right tracks.
#' @param cols `"auto"`, `"top"`, `"bottom"` or `"none"`. Auto puts names on
#'   the side without tracks, else below.
#' @param size Text size in points.
#' @param colour Text colour.
#' @param face `"plain"`, `"bold"` or `"italic"`.
#' @param family Font family.
#' @param angle Angle of column names in degrees; row names stay horizontal.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
#' ggcalor(m) + calor_labels(rows = "right", cols = "bottom", angle = 45, face = "italic")
#' @export
calor_labels <- function(rows = c("auto", "left", "right", "none"), cols = c("auto", "top", "bottom", "none"),
                         size = NULL, colour = NULL, face = NULL, family = NULL, angle = NULL) {
  rows <- rlang::arg_match(rows)
  cols <- rlang::arg_match(cols)
  structure(list(rows = rows, cols = cols,
                 style = list(size = size, colour = colour, face = face, family = family, angle = angle)),
            class = "calor_labels")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_labels <- function(object, plot, ...) {
  check_calor(plot, "calor_labels()")
  st <- calor_state(plot)
  st$labels$rows <- object$rows
  st$labels$cols <- object$cols
  st$labels$style <- object$style
  calor_state(plot) <- st
  plot
}

# Apply calor_labels() to the main plot at build time: scale positions,
# hidden sides and the text style.
apply_label_spec <- function(base, st) {
  lb <- st$labels
  sty <- lb$style
  if (!is.null(sty)) {
    base <- base + theme(axis.text = element_text(size = sty$size, colour = sty$colour,
                                                  face = sty$face, family = sty$family))
    if (!is.null(sty$angle)) {
      a <- sty$angle %% 180
      flat <- a == 0; upright <- a == 90
      base <- base + theme(
        axis.text.x.top = element_text(angle = sty$angle, hjust = if (flat) 0.5 else 0, vjust = if (upright) 0.5 else 0),
        axis.text.x.bottom = element_text(angle = sty$angle, hjust = if (flat) 0.5 else 1, vjust = if (upright) 0.5 else 1)
      )
    }
  }
  if (identical(lb$cols, "none")) base <- base + theme(axis.text.x.top = element_blank(), axis.text.x.bottom = element_blank())
  if (identical(lb$rows, "none")) base <- base + theme(axis.text.y.left = element_blank(), axis.text.y.right = element_blank())
  if (lb$cols %in% c("top", "bottom") || lb$rows %in% c("left", "right")) {
    base@scales <- base@scales$clone()
    if (lb$cols %in% c("top", "bottom")) { xs <- base@scales$get_scales("x"); if (!is.null(xs)) xs$position <- lb$cols }
    if (lb$rows %in% c("left", "right")) { ys <- base@scales$get_scales("y"); if (!is.null(ys)) ys$position <- lb$rows }
  }
  base
}
