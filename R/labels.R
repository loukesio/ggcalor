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
#' @param every Show only every n-th name, counted from the first in the
#'   final order: one number for both axes, or a named vector such as
#'   `c(rows = 3, cols = 20)`. Useful for long runs of years or months.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
#' ggcalor(m) + calor_labels(rows = "right", cols = "bottom", angle = 45, face = "italic")
#' ggcalor(global_temp, cell_size = 2) + calor_labels(every = c(rows = 3, cols = 20))
#' @export
calor_labels <- function(rows = c("auto", "left", "right", "none"), cols = c("auto", "top", "bottom", "none"),
                         size = NULL, colour = NULL, face = NULL, family = NULL, angle = NULL,
                         every = NULL) {
  rows <- rlang::arg_match(rows)
  cols <- rlang::arg_match(cols)
  if (!is.null(every) && is.null(names(every))) every <- c(rows = every[[1]], cols = every[[1]])
  structure(list(rows = rows, cols = cols, every = every,
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
  st$labels$every <- object$every
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

# Keep every n-th name on an axis, counted along the final order.
thin_labels <- function(base, st, lr, lc) {
  every <- st$labels$every
  if (is.null(every)) return(base)
  base@scales <- base@scales$clone()
  for (ax in c("x", "y")) {
    n <- every[[if (ax == "x") "cols" else "rows"]]
    sc <- base@scales$get_scales(ax)
    if (is.null(n) || is.na(n) || n <= 1 || is.null(sc)) next
    ord <- if (ax == "x") lc$order else lr$order
    keep <- ord[seq(1, length(ord), by = n)]
    if (is.character(sc$labels)) {
      sc$labels[!sc$labels %in% keep] <- ""
    } else {
      # Each axis needs its own copy of `keep`, not the loop's last value.
      sc$labels <- local({
        k <- keep
        function(x) ifelse(x %in% k, x, "")
      })
    }
  }
  base
}
