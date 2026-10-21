#' Turn heatmap input into a long data frame
#'
#' Accepts a numeric matrix, a data frame in wide form (first column or row
#' names as row labels), or a long data frame with explicit row, column and
#' value columns.
#'
#' @param data A matrix or data frame.
#' @param rows,cols,value For long data, the column names (strings) holding
#'   row labels, column labels and cell values. Ignored for matrices.
#' @return A list with `matrix` (numeric, with dimnames) and `long`
#'   (data frame with `.row`, `.col`, `.value`).
#' @keywords internal
calor_matrix <- function(data, rows = NULL, cols = NULL, value = NULL) {
  if (is.matrix(data)) {
    m <- data
  } else if (is.data.frame(data) && !is.null(value)) {
    rows <- rows %||% names(data)[1]
    cols <- cols %||% names(data)[2]
    r <- as.character(data[[rows]])
    cc <- as.character(data[[cols]])
    rl <- if (is.factor(data[[rows]])) levels(data[[rows]]) else unique(r)
    cl <- if (is.factor(data[[cols]])) levels(data[[cols]]) else unique(cc)
    v <- data[[value]]
    categorical <- is.character(v) || is.factor(v) || is.logical(v)
    m <- matrix(if (categorical) NA_character_ else NA_real_, length(rl), length(cl), dimnames = list(rl, cl))
    m[cbind(match(r, rl), match(cc, cl))] <- if (categorical) as.character(v) else as.numeric(v)
    if (is.factor(v)) attr(m, "levels") <- levels(v)
  } else if (is.data.frame(data)) {
    num <- vapply(data, is.numeric, logical(1))
    lab <- if (all(num)) rownames(data) else as.character(data[[which(!num)[1]]])
    m <- as.matrix(data[, num, drop = FALSE])
    rownames(m) <- lab
  } else {
    cli::cli_abort("{.arg data} must be a matrix or data frame, not {.cls {class(data)}}.")
  }
  if (is.logical(m)) storage.mode(m) <- "character"
  if (!is.numeric(m) && !is.character(m)) {
    cli::cli_abort("Heatmap values must be numeric or categorical, not {.cls {typeof(m)}}.")
  }
  if (is.null(rownames(m))) rownames(m) <- seq_len(nrow(m))
  if (is.null(colnames(m))) colnames(m) <- seq_len(ncol(m))
  m
}

#' Scale a matrix by row or column
#'
#' @param m Numeric matrix.
#' @param scale One of `"none"`, `"row"`, `"column"`.
#' @param method `"zscore"` (mean 0, sd 1) or `"minmax"` (0 to 1), as in
#'   seaborn's `z_score` and `standard_scale`.
#' @return The scaled matrix.
#' @export
calor_scale <- function(m, scale = c("none", "row", "column"),
                        method = c("zscore", "minmax")) {
  scale <- rlang::arg_match(scale)
  method <- rlang::arg_match(method)
  if (scale == "none") return(m)
  f <- switch(method,
    zscore = function(x) (x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE),
    minmax = function(x) (x - min(x, na.rm = TRUE)) / diff(range(x, na.rm = TRUE))
  )
  out <- if (scale == "row") t(apply(m, 1, f)) else apply(m, 2, f)
  dimnames(out) <- dimnames(m)
  out
}

matrix_to_long <- function(m) {
  v <- as.vector(m)
  if (is.character(m)) v <- factor(v, levels = attr(m, "levels") %||% unique(v[!is.na(v)]))
  data.frame(
    .row = factor(rep(rownames(m), ncol(m)), levels = rownames(m)),
    .col = factor(rep(colnames(m), each = nrow(m)), levels = colnames(m)),
    .value = v,
    stringsAsFactors = FALSE
  )
}

# Numeric stand-in for clustering, ordering and margins: the matrix itself,
# or presence (1/0) for categorical cells.
numeric_proxy <- function(m) {
  if (is.numeric(m)) return(m)
  out <- (!is.na(m) & m != "") * 1
  dimnames(out) <- dimnames(m)
  out
}
