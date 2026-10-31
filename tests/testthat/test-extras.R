set.seed(5)
m <- matrix(rnorm(60), 12, 5, dimnames = list(paste0("g", 1:12), paste0("s", 1:5)))

test_that("histogram legend replaces the colourbar and renders", {
  p <- ggcalor(m) + calor_legend("histogram", bins = 10)
  expect_equal(calor_state(p)$legend$type, "histogram")
  expect_s3_class(ggplotGrob(p), "gtable")
  expect_s3_class(ggplotGrob(p + calor_dendro(rows = TRUE)), "gtable")
})

test_that("glyph tracks and brackets build", {
  p <- ggcalor(m) + calor_anno(top = list(kind = c("a", "b", "a", "b", "a")), type = "glyph") +
    calor_bracket(cols = c("x", "x", "y", "y", "y"), side = "bottom") +
    calor_bracket(rows = rep(c("r1", "r2"), each = 6), side = "right")
  st <- calor_state(p)
  expect_equal(st$anno$top[[1]]$type, "glyph")
  expect_equal(st$anno$bottom[[1]]$type, "bracket")
  expect_equal(st$anno$right[[1]]$type, "bracket")
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("rasterisation switches by threshold and drops tiny labels", {
  p <- ggcalor(m, raster = "auto", raster_threshold = 10)
  expect_true(calor_state(p)$cell$raster)
  expect_false(calor_state(ggcalor(m))$cell$raster)
  big <- ggcalor(matrix(rnorm(3000), 1000, 3), cell_size = c(3, 0.1))
  b <- ggplot_build(big)
  expect_s3_class(b@plot@theme$axis.text.y, "element_blank")
})

test_that("radial coordinates render without tracks and warn with them", {
  p <- ggcalor(m) + coord_radial(inner.radius = 0.2)
  expect_s3_class(ggplotGrob(p), "gtable")
  expect_warning(ggplotGrob(p + calor_dendro(rows = TRUE)), "non-linear")
  r <- ggcalor(m) + calor_radial(inner.radius = 0.4)
  expect_false(r@coordinates$is_linear())
  expect_equal(r@theme$legend.position, "bottom")
  expect_equal((ggcalor(m) + calor_radial(legend = "inside"))@theme$legend.position, "inside")
  expect_s3_class(ggplotGrob(r), "gtable")
  # later theme() calls still win, and ring labels add to the natural size
  r2 <- r + theme(legend.position = "right")
  expect_equal(r2@theme$legend.position, "right")
  expect_gt(calor_size(r)[1], calor_size(ggcalor(m) + coord_radial())[1] - 1e-9)
  long <- data.frame(row = rep(month.abb, 5), col = rep(paste0("c", 1:5), each = 12),
                     value = sample(c("a", "b", NA), 60, TRUE))
  expect_s3_class(ggplotGrob(ggcalor(long, "row", "col", "value") + calor_radial()), "gtable")
})

test_that("waffle allocates cells by largest remainder", {
  expect_equal(largest_remainder(c(45, 30, 25), 100), c(45, 30, 25))
  expect_equal(sum(largest_remainder(c(1, 1, 1), 100)), 100)
  p <- calor_waffle(c(a = 45, b = 30, c = 25), n = 100, rows = 10)
  expect_equal(nrow(p@data), 100)
  expect_s3_class(ggplotGrob(p), "gtable")
  df <- data.frame(g = rep(c("x", "y"), each = 2), k = c("a", "b", "a", "b"), v = c(3, 1, 1, 3))
  expect_s3_class(ggplotGrob(calor_waffle(df, "k", "v", by = "g", n = 20, rows = 4)), "gtable")
})

test_that("interactive cells carry tooltips", {
  skip_if_not_installed("ggiraph")
  p <- ggcalor(m) + calor_interactive(data_id = "row")
  b <- ggplot_build(p)
  expect_true(all(c(".tooltip", ".data_id") %in% names(b@plot@data)))
  expect_s3_class(b@plot@layers[[1]]$geom, "GeomInteractiveTile")
  w <- calor_girafe(p)
  expect_s3_class(w, "girafe")
})

test_that("smooth surfaces interpolate, blur and follow the order", {
  f <- outer(1:6, 1:8, function(i, j) i + j); dimnames(f) <- list(paste0("r", 1:6), paste0("c", 1:8))
  up <- upsample_matrix(f, 4)
  expect_equal(dim(up$z), c(24, 32))
  expect_equal(range(up$z), range(f))
  expect_equal(blur_matrix(up$z, 0), up$z)
  bl <- blur_matrix(up$z, 3)
  expect_lt(stats::sd(bl), stats::sd(up$z) + 1e-9)
  p <- ggcalor(f, smooth = "contour", smooth_bins = 5)
  expect_s3_class(ggplotGrob(p), "gtable")
  p2 <- ggcalor(f, smooth = "raster") + calor_order(rows = "mean") + calor_dendro(cols = TRUE)
  b <- ggplot_build(p2)
  expect_equal(b@plot@scales$get_scales("y")$labels, rev(calor_order_of(p2)$rows))
  expect_error(ggcalor(matrix("a", 2, 2), smooth = "raster"), "numeric")
})

test_that("calor_labels(every = ) thins each axis on its own", {
  p <- ggcalor(global_temp[, 1:40]) + calor_labels(every = c(rows = 3, cols = 20))
  g <- ggplot2::ggplot_build(p)
  pp <- g@layout$panel_params[[1]]
  expect_equal(setdiff(pp$x$get_labels(), ""), c("1880", "1900"))
  expect_equal(setdiff(pp$y$get_labels(), ""), c("Oct", "Jul", "Apr", "Jan"))
})
