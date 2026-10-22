set.seed(3)
m <- matrix(rnorm(80), 16, 5, dimnames = list(paste0("g", 1:16), paste0("s", 1:5)))
grp <- rep(c("a", "b"), each = 8)

test_that("splits give contiguous slices, gaps and per-slice ordering", {
  p <- ggcalor(m) + calor_split(rows = grp, gap = 2) + calor_order(rows = "mean")
  st <- resolve_layout(calor_state(p))
  lay <- st$lay$rows
  expect_equal(as.character(lay$slices), rep(c("a", "b"), each = 8))
  expect_equal(lay$g, 2 / 5)
  expect_equal(lay$L, 16 + 2 / 5)
  expect_equal(diff(lay$pos)[8], 1 + 2 / 5)
  # within-slice order by mean, descending
  a <- lay$order[1:8]
  expect_equal(a, names(sort(rowMeans(m[1:8, ]), decreasing = TRUE)))
  g <- ggplotGrob(p)
  pan <- g$layout[grepl("^panel", g$layout$name), ]
  expect_equal(nrow(pan), 2)
})

test_that("integer split cuts the tree and keeps slices contiguous in leaf order", {
  p <- ggcalor(m) + calor_dendro(rows = TRUE) + calor_split(rows = 3)
  lay <- resolve_layout(calor_state(p))$lay$rows
  hc <- hclust(dist(m))
  expect_equal(lay$order, rownames(m)[hc$order])
  expect_equal(nlevels(lay$slices), 3)
  expect_true(all(diff(as.integer(lay$slices)) >= 0))
  # trunk segments joining slices are dropped: 3 segments per merge within slices
  expect_equal(nrow(lay$segs), 3 * sum(table(lay$slices) - 1))
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("annotations become tracks matched by name or position", {
  meta <- data.frame(group = c("x", "y", "x", "y", "x"), dose = 1:5, row.names = colnames(m))
  p <- ggcalor(m) + calor_anno(top = meta[c(5, 1:4), ], left = list(flag = rep(TRUE, 16)),
                               type = c(dose = "point"), size = c(group = 3))
  st <- calor_state(p)
  expect_length(st$anno$top, 2)
  expect_equal(st$anno$top[[1]]$type, "tile")
  expect_equal(st$anno$top[[2]]$type, "point")
  expect_equal(st$anno$top[[1]]$size, 3)
  expect_equal(unname(st$anno$top[[2]]$values), 1:5)  # reordered back to matrix order
  expect_equal(st$anno$left[[1]]$name, "flag")
  expect_error(ggcalor(m) + calor_anno(top = 1:3), "length 5")
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("margins summarise raw data and text labels cells", {
  p <- ggcalor(m, scale = "row") + calor_margin(right = "mean", bottom = "boxplot") + calor_text(digits = 2)
  st <- calor_state(p)
  expect_equal(unname(st$anno$right[[1]]$values), unname(rowMeans(m)))
  expect_equal(st$anno$bottom[[1]]$type, "boxplot")
  b <- ggplot_build(p)
  expect_true(".label" %in% names(b@plot@data))
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("cell shapes render", {
  for (sh in c("square", "circle")) {
    p <- ggcalor(m[1:4, ], cell_shape = sh, cell_gap = 0.1, cell_radius = 0.5)
    expect_s3_class(ggplotGrob(p), "gtable")
  }
})

test_that("calor_labels() moves and styles names", {
  m <- matrix(rnorm(40), 8, 5, dimnames = list(paste0("g", 1:8), paste0("s", 1:5)))
  p <- ggcalor(m) + calor_labels(rows = "right", cols = "bottom", colour = "navy", angle = 45)
  b <- ggplot2::ggplot_build(p)
  expect_equal(b@plot@scales$get_scales("x")$position, "bottom")
  expect_equal(b@plot@scales$get_scales("y")$position, "right")
  expect_equal(ggplot2::calc_element("axis.text.y.right", b@plot@theme)$colour, "navy")
  expect_equal(ggplot2::calc_element("axis.text.x.bottom", b@plot@theme)$angle, 45)
  # Names hidden
  p2 <- ggcalor(m) + calor_labels(rows = "none")
  b2 <- ggplot2::ggplot_build(p2)
  expect_s3_class(ggplot2::calc_element("axis.text.y.left", b2@plot@theme), "element_blank")
  # With tracks the names move outside the outermost track and build still works
  p3 <- ggcalor(m) + calor_anno(left = data.frame(k = rep(c("a", "b"), 4)), right = data.frame(v = 1:8)) +
    calor_labels(rows = "left")
  expect_s3_class(ggplot2::ggplotGrob(p3), "gtable")
})

test_that("tracks sit against the cells and count axes use whole numbers", {
  m <- matrix(sample(0:5, 40, TRUE), 8, 5, dimnames = list(paste0("g", 1:8), paste0("s", 1:5)))
  p <- ggcalor(m) + calor_margin(top = "sum")
  expect_s3_class(ggplot2::ggplotGrob(p), "gtable")
  ax <- value_axis(TRUE, "top", integer = TRUE)
  b <- ax[[1]]$breaks(c(0, 5))
  expect_true(all(b == round(b)))
  expect_gte(length(b), 2)
})
