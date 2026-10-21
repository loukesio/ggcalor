#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||% .data
#' @importFrom patchwork wrap_plots
NULL

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
