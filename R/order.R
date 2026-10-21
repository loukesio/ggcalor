#' Order rows and columns
#'
#' Sort the heatmap without drawing a tree. Ordering is resolved when the plot
#' is built, so it composes with [calor_dendro()]: a dendrogram wins for the
#' axis it clusters.
#'
#' @param rows,cols How to order. One of:
#'   * a statistic name: `"mean"`, `"sum"`, `"max"`, `"min"`, `"var"`, `"sd"`,
#'     `"median"`;
#'   * `"cluster"`: hierarchical-clustering leaf order, no tree drawn;
#'   * `"memo"`: the oncoprint sort. Items are ordered so that those with a
#'     value in the first row/column come first, then the second, and so on.
#'     Combine with `"sum"` on the other axis for a classic oncoprint;
#'   * a name: order rows by the values in that column, or columns by the
#'     values in that row;
#'   * a character vector of names or an integer vector: an explicit order;
#'   * a function taking the matrix and returning an order.
#'   `NULL` leaves the axis as is.
#' @param decreasing Sort statistics from largest to smallest.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
#' ggcalor(m) + calor_order(rows = "mean", cols = "cluster")
#' ggcalor(m) + calor_order(rows = "s1")
#' @export
calor_order <- function(rows = NULL, cols = NULL, decreasing = TRUE) {
  structure(list(rows = rows, cols = cols, decreasing = decreasing),
            class = "calor_order")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_order <- function(object, plot, ...) {
  check_calor(plot, "calor_order()")
  st <- calor_state(plot)
  if (!is.null(object$rows)) st$order$rows <- object[c("rows", "decreasing")]
  if (!is.null(object$cols)) st$order$cols <- object[c("cols", "decreasing")]
  calor_state(plot) <- st
  plot
}

# Resolve an order spec to a vector of names for one margin.
# `m` is oriented so that the things being ordered are rows.
resolve_order <- function(spec, m, decreasing = TRUE) {
  nm <- rownames(m)
  if (is.null(spec)) return(nm)
  if (is.function(spec)) {
    o <- spec(m)
    return(if (is.character(o)) o else nm[o])
  }
  if (is.numeric(spec)) return(nm[spec])
  if (length(spec) > 1) return(spec)
  stats_fun <- c(mean = "mean", sum = "sum", max = "max", min = "min",
                 var = "var", sd = "sd", median = "median")
  if (spec %in% names(stats_fun)) {
    f <- get(stats_fun[[spec]], envir = asNamespace("stats"), mode = "function",
             inherits = TRUE)
    v <- apply(m, 1, f, na.rm = TRUE)
    return(nm[order(v, decreasing = decreasing)])
  }
  if (spec == "cluster") {
    hc <- stats::hclust(stats::dist(m), "complete")
    return(nm[hc$order])
  }
  if (spec == "memo") {
    keys <- lapply(seq_len(ncol(m)), function(j) -m[, j])
    return(nm[do.call(order, keys)])
  }
  if (spec %in% colnames(m)) {
    return(nm[order(m[, spec], decreasing = decreasing)])
  }
  cli::cli_abort(c("Unknown order {.val {spec}}.",
    i = "Use a statistic name, {.val cluster}, a row/column name, a vector, or a function."))
}

#' Row and column order of a built heatmap
#'
#' Returns the final order after [calor_order()] and [calor_dendro()] have been
#' applied, so it can be reused elsewhere, like seaborn's `reordered_ind`.
#' @param plot A [ggcalor()] plot.
#' @return A list with `rows` and `cols`, character vectors of names.
#' @export
calor_order_of <- function(plot) {
  check_calor(plot, "calor_order_of()")
  st <- resolve_layout(calor_state(plot))
  list(rows = st$row_order, cols = st$col_order)
}

check_calor <- function(plot, what) {
  if (!is_calor(plot)) {
    cli::cli_abort("{.fn {what}} can only be added to a plot created by {.fn ggcalor}.")
  }
}
