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

test_that("user scales and calor_radial() replace the defaults silently", {
  expect_no_message(p <- ggcalor(m) + scale_fill_viridis_c())
  expect_no_message(ggcalor(m) + calor_radial())
  fill_call <- function(p) ggplot_build(p)@plot@scales$get_scales("fill")$call[[1]]
  expect_identical(fill_call(p), quote(scale_fill_viridis_c))
  # Without a user scale the default diverging scale is used.
  expect_identical(fill_call(ggcalor(m)), quote(scale_fill_gradient2))
})

test_that("a histogram legend on categorical cells fails clearly", {
  mut <- matrix(c("a", "b", NA, "a"), 2, 2)
  expect_error(ggcalor(mut) + calor_legend("histogram"), "categorical")
})

test_that("categorical tracks get distinct colours and ordered tracks a sequence", {
  cols <- data.frame(a = rep(c("x", "y"), length.out = 5), b = rep(c("u", "v"), length.out = 5),
                     o = factor(c(1, 2, 3, 1, 2), ordered = TRUE), row.names = colnames(m))
  tr <- calor_state(ggcalor(m) + calor_anno(top = cols))$anno$top
  expect_equal(tr[[1]]$pal_offset, 0)
  expect_equal(tr[[2]]$pal_offset, 2)
  expect_null(tr[[3]]$pal_offset)
  expect_s3_class(ggplotGrob(ggcalor(m) + calor_anno(top = cols)), "gtable")
})

test_that("na_fill applies to a user fill scale unless it sets na.value", {
  na_of <- function(p) ggplot_build(p)@plot@scales$get_scales("fill")$na.value
  expect_identical(na_of(ggcalor(m, na_fill = NA) + scale_fill_distiller()), NA)
  expect_identical(na_of(ggcalor(m, na_fill = NA) + scale_fill_distiller(na.value = "pink")), "pink")
})

test_that("calor_panel() puts each name at its row or column, gaps included", {
  rows <- data.frame(id = rownames(m), v = seq_len(nrow(m)))
  cols <- data.frame(id = colnames(m), v = seq_len(ncol(m)))
  p <- ggcalor(m) + calor_dendro(rows = TRUE) + calor_split(rows = 2, cols = c(1, 1, 2, 2, 2), gap = 3) +
    calor_panel(ggplot(rows, aes(v, id, label = id)) + geom_text(), side = "right") +
    calor_panel(ggplot(cols, aes(id, v, label = id)) + geom_text(), side = "bottom")
  st <- resolve_layout(calor_state(p))
  at <- function(side, lay) {
    tr <- calor_state(p)$anno[[side]][[1]]
    ggplot_build(panel_plot(tr, lay, lay$cell_mm))@data[[1]]
  }
  lr <- st$lay$rows; lc <- st$lay$cols
  y <- at("right", lr)
  expect_equal(y$y[match(lr$order, y$label)], lr$L + 1 - lr$pos, ignore_attr = TRUE)
  x <- at("bottom", lc)
  expect_equal(x$x[match(lc$order, x$label)], lc$pos, ignore_attr = TRUE)
  expect_gt(lr$g, 0)
  expect_s3_class(ggplotGrob(p), "gtable")
})

test_that("calor_panel() replaces the user's along-axis scale and keeps the rest", {
  rows <- data.frame(id = rownames(m), v = seq_len(nrow(m)), g = rep(c("a", "b"), length.out = nrow(m)))
  side <- ggplot(rows, aes(v, id, fill = g)) + geom_col() + scale_y_discrete(limits = rev) +
    scale_fill_manual(values = c(a = "red", b = "blue"))
  p <- ggcalor(m) + calor_panel(side, side = "left", size = 20)
  expect_no_message(g <- ggplotGrob(p))
  expect_s3_class(g, "gtable")
  expect_error(calor_panel(1), "ggplot")
})

test_that("a heatmap with trees and tracks nests inside another patchwork", {
  hm <- ggcalor(m) + calor_dendro(rows = TRUE, cols = TRUE) +
    calor_anno(top = data.frame(g = rep(c("a", "b"), length.out = ncol(m)), row.names = colnames(m)))
  other <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
  pw <- patchwork::wrap_plots(hm, other) + patchwork::plot_annotation(tag_levels = "A")
  g <- patchwork::patchworkGrob(pw)
  expect_s3_class(g, "gtable")
  f <- tempfile(fileext = ".png")
  ragg::agg_png(f, 800, 400)
  expect_no_error(grid::grid.draw(g))
  grDevices::dev.off()
  # The stand-in table's panel is exactly the cells.
  grDevices::pdf(NULL)
  tb <- plot_table.calor(hm, "keep")
  grDevices::dev.off()
  panel <- tb$layout[tb$layout$name == "panel", ]
  expect_equal(grid::convertHeight(tb$heights[panel$t], "mm", valueOnly = TRUE), nrow(m) * 5)
  expect_equal(grid::convertWidth(tb$widths[panel$l], "mm", valueOnly = TRUE), ncol(m) * 5)
  # A plain heatmap still goes through patchwork's usual alignment.
  expect_s3_class(patchwork::patchworkGrob(patchwork::wrap_plots(ggcalor(m), other)), "gtable")
})

test_that("calor_gtable() has one panel over the cells and calor_anchors() finds rows", {
  p <- ggcalor(m) + calor_dendro(rows = TRUE) + calor_split(rows = 2, gap = 2)
  g <- calor_gtable(p)
  expect_equal(sum(g$layout$name == "panel"), 1)
  lr <- resolve_layout(calor_state(p))$lay$rows
  expect_equal(attr(g, "calor_ranges")$y, c(0.5, lr$L + 0.5))
  a <- calor_anchors(p, rows = lr$order[1:2], side = "right")
  # The first row in the final order is the top one.
  expect_equal(a$y, lr$L + 1 - lr$pos[1:2])
  expect_true(all(a$x == ncol(m) + 0.5))
  # Outside the row tree on the left.
  expect_lt(calor_anchors(p, rows = lr$order[1], side = "left")$x, 0.5)
  expect_equal(calor_anchors(p, rows = lr$order[1], side = "left", outside = FALSE)$x, 0.5)
  expect_error(calor_anchors(p, rows = "nope"), "Not rows")
  expect_error(calor_anchors(p), "one of")
})
