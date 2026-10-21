set.seed(1)
m <- matrix(rnorm(60), 12, 5, dimnames = list(paste0("g", 1:12), paste0("s", 1:5)))

test_that("ggcalor returns a ggplot that still accepts ggplot2 additions", {
  p <- ggcalor(m)
  expect_true(is_calor(p))
  expect_s3_class(p, "ggplot")
  p2 <- p + theme_bw() + labs(title = "x") + scale_fill_viridis_c()
  expect_true(is_calor(p2))
  expect_s3_class(ggplotGrob(p2), "gtable")
})

test_that("cells are square and absolute", {
  g <- ggplotGrob(ggcalor(m, cell_size = 4))
  pan <- g$layout[g$layout$name == "panel", ]
  expect_equal(as.numeric(grid::convertUnit(g$widths[pan$l], "mm")), 5 * 4)
  expect_equal(as.numeric(grid::convertUnit(g$heights[pan$t], "mm")), 12 * 4)
})

test_that("long data, scaling and mask work", {
  long <- data.frame(r = rep(rownames(m), 5), c = rep(colnames(m), each = 12), v = as.vector(m))
  p <- ggcalor(long, rows = "r", cols = "c", value = "v")
  expect_equal(calor_state(p)$matrix, m)
  z <- calor_scale(m, "row")
  expect_equal(unname(rowMeans(z)), rep(0, 12))
  mm <- calor_scale(m, "column", "minmax")
  expect_equal(unname(apply(mm, 2, max)), rep(1, 5))
  pm <- ggcalor(m, mask = m > 0)
  expect_true(all(is.na(calor_state(pm)$matrix[m > 0])))
})

test_that("ordering verbs resolve", {
  o <- calor_order_of(ggcalor(m) + calor_order(rows = "mean", cols = "g1"))
  expect_equal(o$rows, names(sort(rowMeans(m), decreasing = TRUE)))
  expect_equal(o$cols, colnames(m)[order(m["g1", ], decreasing = TRUE)])
  o2 <- calor_order_of(ggcalor(m) + calor_order(rows = c("g3", "g1")))
  expect_equal(o2$rows[1:2], c("g3", "g1"))
  o3 <- calor_order_of(ggcalor(m) + calor_order(rows = function(x) order(x[, 1])))
  expect_equal(o3$rows, rownames(m)[order(m[, 1])])
  expect_error(ggplot() + calor_order(rows = "mean"), "ggcalor")
})

test_that("dendrograms reorder and draw", {
  p <- ggcalor(m) + calor_dendro(rows = TRUE, cols = TRUE, k = 2, highlight = TRUE)
  hc <- hclust(dist(m), "complete")
  expect_equal(calor_order_of(p)$rows, rownames(m)[hc$order])
  expect_s3_class(ggplotGrob(p), "gtable")
  own <- hclust(dist(m), "average")
  p2 <- ggcalor(m) + calor_dendro(rows = own)
  expect_equal(calor_order_of(p2)$rows, rownames(m)[own$order])
  seg <- hclust_segments(hc, k = 3)
  expect_equal(nrow(seg$segments), 3 * (nrow(m) - 1))
  expect_equal(nrow(seg$rects), 3)
})

test_that("calor_size and calor_save give a natural size", {
  p <- ggcalor(m, cell_size = 5) + calor_dendro(rows = TRUE)
  sz <- calor_size(p)
  expect_true(sz[1] > 25 && sz[2] > 60)
  f <- withr::local_tempfile(fileext = ".png")
  calor_save(p, f, dpi = 50)
  expect_true(file.exists(f))
})
