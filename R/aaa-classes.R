#' @import ggplot2

NULL

#' The ggcalor plot class
#'
#' An S7 subclass of [ggplot2::class_ggplot] carrying the heatmap state in the
#' `calor` property. Users never construct it directly; see [ggcalor()].
#' @keywords internal
#' @export
class_calor <- S7::new_class(
  "calor",
  parent = ggplot2::class_ggplot,
  properties = list(calor = S7::class_list),
  constructor = function(plot, calor = list()) {
    out <- S7::new_object(plot, calor = calor)
    add_s3_aliases(out, c("ggcalor::calor", "calor"), "ggplot2::ggplot", "ggplot")
  }
)

#' @rdname class_calor
#' @keywords internal
#' @export
class_calor_built <- S7::new_class(
  "calor_built",
  parent = ggplot2::class_ggplot_built,
  properties = list(calor = S7::class_list),
  constructor = function(built, calor = list()) {
    out <- S7::new_object(built, calor = calor)
    add_s3_aliases(out, c("ggcalor::calor_built", "calor_built"), "ggplot2::ggplot_built", "ggplot_built")
  }
)

# ggplot2 4.0 gives its S7 objects plain S3 class names ("ggplot", "gg") next
# to the prefixed ones so S3 methods in patchwork and friends dispatch. S7
# subclassing drops them, so mirror what ggplot2:::ggplot.default() does.
add_s3_aliases <- function(x, own, parent_prefixed, parent_alias) {
  cls <- class(x)
  cls <- append(cls, parent_alias, after = match(parent_prefixed, cls))
  class(x) <- union(union(own, cls), "gg")
  x
}

#' Is this a ggcalor plot?
#' @param x An object.
#' @return `TRUE` for objects created by [ggcalor()].
#' @export
is_calor <- function(x) S7::S7_inherits(x, class_calor)

# Fetch and replace the calor state on a plot.
calor_state <- function(plot) plot@calor
`calor_state<-` <- function(plot, value) {
  plot@calor <- value
  plot
}
