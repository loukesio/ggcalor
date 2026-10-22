set.seed(9)
mut <- matrix(sample(c("mis", "del", NA), 60, TRUE, prob = c(.3, .2, .5)), 6, 10,
              dimnames = list(paste0("g", 1:6), paste0("s", 1:10)))

test_that("categorical matrices get a discrete fill and a presence proxy", {
  p <- ggcalor(mut)
  st <- calor_state(p)
  expect_true(st$categorical)
  expect_equal(st$num, (!is.na(mut)) * 1, ignore_attr = TRUE)
  expect_s3_class(p@data$.value, "factor")
  expect_error(ggcalor(mut, scale = "row"), "numeric")
  expect_s3_class(ggplotGrob(p + calor_text() + calor_margin(right = "sum")), "gtable")
  long <- data.frame(r = rep(rownames(mut), 10), c = rep(colnames(mut), each = 6), v = as.vector(mut))
  expect_equal(calor_state(ggcalor(long, "r", "c", "v"))$matrix, mut, ignore_attr = TRUE)
})

test_that("memo sort puts samples altered in the top gene first", {
  p <- ggcalor(mut) + calor_order(rows = "sum", cols = "memo")
  o <- calor_order_of(p)
  pres <- (!is.na(mut)) * 1
  top <- o$rows[1]
  hit <- pres[top, o$cols]
  expect_true(all(diff(hit) <= 0))  # ones before zeros
})

test_that("masking does not change clustering", {
  m <- matrix(rnorm(36), 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  a <- calor_order_of(ggcalor(m) + calor_order(rows = "cluster"))
  b <- calor_order_of(ggcalor(m, mask = upper.tri(m)) + calor_order(rows = "cluster"))
  expect_equal(a$rows, b$rows)
})

test_that("hex cells and cell_area render", {
  m <- matrix(rnorm(40), 5, 8, dimnames = list(paste0("r", 1:5), paste0("c", 1:8)))
  ph <- ggcalor(m, cell_shape = "hex")
  expect_true(all(c(".x", ".y") %in% names(ph@data)))
  expect_s3_class(ggplotGrob(ph), "gtable")
  expect_warning(ggplotGrob(ph + calor_dendro(rows = TRUE)), "hex")
  pa <- ggcalor(m, cell_shape = "circle", cell_area = abs(m))
  expect_true(all(pa@data$.area >= 0 & pa@data$.area <= 1))
  expect_s3_class(ggplotGrob(pa), "gtable")
  expect_error(ggcalor(m, cell_area = m[1:2, ]), "dimensions")
})

test_that("empty cells of a categorical matrix are painted with na_fill", {
  m <- matrix(c("a", NA, "b", NA), 2, 2, dimnames = list(c("r1", "r2"), c("c1", "c2")))
  p <- ggcalor(m, na_fill = "grey93")
  d <- ggplot2::layer_data(p, 1)
  expect_equal(nrow(d), 4)
  expect_equal(sum(d$fill == "grey93"), 2)
  # No NA key in the legend
  b <- ggplot2::ggplot_build(p)
  sc <- b@plot@scales$get_scales("fill")
  expect_false(anyNA(sc$get_limits()))
})
