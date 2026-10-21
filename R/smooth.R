# Bilinear upsampling of a matrix onto a grid `k` times finer, in cell units
# (cell centres at integers, so the field spans 0.5 to n + 0.5).
upsample_matrix <- function(m, k = 8) {
  nr <- nrow(m); nc <- ncol(m)
  m[is.na(m)] <- mean(m, na.rm = TRUE)
  xs <- seq(0.5, nc + 0.5, length.out = max(2, nc * k))
  ys <- seq(0.5, nr + 0.5, length.out = max(2, nr * k))
  idx <- function(t, n) {
    t <- pmin(pmax(t, 1), n)
    i0 <- pmin(floor(t), max(n - 1, 1)); i1 <- pmin(i0 + 1, n)
    list(i0 = i0, i1 = i1, w = t - i0)
  }
  cx <- idx(xs, nc); cy <- idx(ys, nr)
  wx <- matrix(cx$w, length(ys), length(xs), byrow = TRUE)
  wy <- matrix(cy$w, length(ys), length(xs))
  z <- (1 - wy) * ((1 - wx) * m[cy$i0, cx$i0, drop = FALSE] + wx * m[cy$i0, cx$i1, drop = FALSE]) +
       wy * ((1 - wx) * m[cy$i1, cx$i0, drop = FALSE] + wx * m[cy$i1, cx$i1, drop = FALSE])
  list(x = xs, y = ys, z = z)
}

# Separable Gaussian blur with edge replication; `sigma` in pixels.
blur_matrix <- function(z, sigma) {
  if (sigma <= 0) return(z)
  h <- ceiling(3 * sigma)
  kern <- stats::dnorm(-h:h, sd = sigma); kern <- kern / sum(kern)
  smooth_vec <- function(v) {
    p <- c(rep(v[1], h), v, rep(v[length(v)], h))
    as.numeric(stats::filter(p, kern, sides = 2))[(h + 1):(h + length(v))]
  }
  z <- apply(z, 2, smooth_vec)
  t(apply(z, 1, smooth_vec))
}

# Field data frame for the smooth layer, rows in display order (top first).
smooth_field <- function(m, sm) {
  m <- m[nrow(m):1, , drop = FALSE]   # row 1 on top means highest y
  up <- upsample_matrix(m, sm$upsample)
  z <- blur_matrix(up$z, sm$sigma * sm$upsample)
  data.frame(x = rep(up$x, each = length(up$y)), y = rep(up$y, length(up$x)), z = as.vector(z))
}

smooth_layer <- function(field, sm) {
  if (sm$type == "contour") {
    geom_contour_filled(data = field, aes(x = .data$x, y = .data$y, z = .data$z),
                        bins = sm$bins, inherit.aes = FALSE, colour = NA)
  } else {
    geom_raster(data = field, aes(x = .data$x, y = .data$y, fill = .data$z),
                inherit.aes = FALSE, interpolate = TRUE)
  }
}
