#' Split rows and columns into slices
#'
#' Slices are separated by a gap and keep square cells. Give a grouping
#' vector, or an integer to cut the dendrogram (a default one is computed when
#' none was added).
#'
#' @param rows,cols `NULL`, an integer number of clusters, or a vector (or
#'   factor) of group labels, named by row/column or in matrix order.
#' @param gap Gap between slices in millimetres.
#' @param labels Show slice labels as strips.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
#' ggcalor(m) + calor_dendro(rows = TRUE) + calor_split(rows = 3)
#' ggcalor(m) + calor_split(cols = rep(c("ctrl", "treat"), each = 5))
#' @export
calor_split <- function(rows = NULL, cols = NULL, gap = 1.5, labels = TRUE) {
  structure(list(rows = rows, cols = cols, gap = gap, labels = labels),
            class = "calor_split")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_split <- function(object, plot, ...) {
  check_calor(plot, "calor_split()")
  st <- calor_state(plot)
  if (!is.null(object$rows)) st$split$rows <- object$rows
  if (!is.null(object$cols)) st$split$cols <- object$cols
  st$split$gap <- object$gap
  st$split$labels <- object$labels
  calor_state(plot) <- st
  plot
}

# Match a user-supplied vector to item names.
align_to_items <- function(v, items, what) {
  if (!is.null(names(v)) && all(items %in% names(v))) return(v[items])
  if (length(v) != length(items)) {
    cli::cli_abort("{.arg {what}} must have length {length(items)} or be named by {what}.")
  }
  stats::setNames(v, items)
}
