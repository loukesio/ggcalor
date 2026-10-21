#' Cluster and draw dendrograms
#'
#' Reorders rows and/or columns by hierarchical clustering and draws the trees
#' beside the heatmap, aligned leaf to cell. Precomputed `hclust` or
#' `dendrogram` objects are accepted.
#'
#' @param rows,cols `TRUE` to cluster that axis, `FALSE` to leave it, or an
#'   `hclust` / `dendrogram` object to use as is.
#' @param method Linkage method passed to [stats::hclust()].
#' @param dist Distance measure passed to [stats::dist()], or a function taking
#'   the matrix and returning a `dist`.
#' @param k Cut the tree into `k` clusters and colour the branches.
#' @param highlight Shade the `k` clusters behind the tree, as in many
#'   publication figures.
#' @param size Height of a column tree or width of a row tree, in millimetres.
#' @param colour Line colour when `k` is `NULL`.
#' @param linewidth Line width of the branches.
#' @param show_tree Set to `FALSE` to reorder without drawing. Equivalent to
#'   `calor_order("cluster")` but with your own linkage and distance.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
#' ggcalor(m) + calor_dendro(rows = TRUE, cols = TRUE)
#' ggcalor(m) + calor_dendro(rows = TRUE, k = 3, highlight = TRUE)
#' @export
calor_dendro <- function(rows = TRUE, cols = FALSE, method = "complete",
                         dist = "euclidean", k = NULL, highlight = FALSE,
                         size = 12, colour = "grey30", linewidth = 0.4,
                         show_tree = TRUE) {
  structure(list(rows = rows, cols = cols, method = method, dist = dist, k = k,
                 highlight = highlight, size = size, colour = colour,
                 linewidth = linewidth, show_tree = show_tree),
            class = "calor_dendro")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_dendro <- function(object, plot, ...) {
  check_calor(plot, "calor_dendro()")
  st <- calor_state(plot)
  spec <- object[setdiff(names(object), c("rows", "cols"))]
  if (!isFALSE(object$rows)) st$dendro$rows <- c(spec, list(tree = object$rows))
  if (!isFALSE(object$cols)) st$dendro$cols <- c(spec, list(tree = object$cols))
  calor_state(plot) <- st
  plot
}

# Compute an hclust for one margin. `m` has the items to cluster as rows.
compute_hclust <- function(spec, m) {
  tree <- spec$tree
  if (inherits(tree, "hclust")) return(tree)
  if (inherits(tree, "dendrogram")) return(stats::as.hclust(tree))
  d <- if (is.function(spec$dist)) spec$dist(m) else stats::dist(m, method = spec$dist)
  stats::hclust(d, method = spec$method)
}

# Segments of an hclust tree in leaf-position coordinates (1..n), like
# ggdendro::dendro_data() but with cluster membership attached.
hclust_segments <- function(hc, k = NULL) {
  n <- length(hc$order)
  leaf_x <- numeric(n)
  leaf_x[hc$order] <- seq_len(n)
  cl <- if (!is.null(k)) stats::cutree(hc, k = k)[hc$labels %||% seq_len(n)] else NULL
  node_x <- node_y <- numeric(n - 1)
  node_cl <- rep(NA_integer_, n - 1)
  segs <- vector("list", n - 1)
  child <- function(j) {
    if (j < 0) list(x = leaf_x[-j], y = 0, cl = if (is.null(cl)) NA else cl[[-j]])
    else list(x = node_x[j], y = node_y[j], cl = node_cl[j])
  }
  for (i in seq_len(n - 1)) {
    a <- child(hc$merge[i, 1]); b <- child(hc$merge[i, 2]); h <- hc$height[i]
    node_x[i] <- (a$x + b$x) / 2; node_y[i] <- h
    node_cl[i] <- if (!is.na(a$cl) && identical(a$cl, b$cl)) a$cl else NA_integer_
    segs[[i]] <- data.frame(
      x = c(a$x, a$x, b$x), xend = c(a$x, b$x, b$x),
      y = c(a$y, h, h), yend = c(h, h, b$y),
      cluster = c(a$cl, node_cl[i], b$cl)
    )
  }
  out <- do.call(rbind, segs)
  out$cluster <- if (is.null(k)) NA_character_ else ifelse(is.na(out$cluster), "trunk", paste0("cluster ", out$cluster))
  rects <- NULL
  if (!is.null(k)) {
    rects <- do.call(rbind, lapply(split(leaf_x, cl), function(x)
      data.frame(xmin = min(x) - 0.5, xmax = max(x) + 0.5)))
    rects$cluster <- paste0("cluster ", names(split(leaf_x, cl)))
  }
  list(segments = out, rects = rects, n = n, height = max(hc$height))
}

# Build the dendrogram ggplot for one side from a resolved axis layout.
dendro_plot <- function(lay, spec, side) {
  seg <- lay$segs; rects <- lay$rects; L <- lay$L
  ymax <- max(lay$height, 1e-8) * 1.02
  flip <- side == "left"
  if (flip) {
    seg[c("x", "xend")] <- lapply(seg[c("x", "xend")], function(v) L + 1 - v)
    if (!is.null(rects)) {
      r <- rects; rects$xmin <- L + 1 - r$xmax; rects$xmax <- L + 1 - r$xmin
    }
  }
  coloured <- !is.null(spec$k) && !all(is.na(seg$cluster))
  p <- ggplot(seg)
  if (isTRUE(spec$highlight) && !is.null(rects)) {
    p <- p + if (flip) {
      geom_rect(data = rects, aes(ymin = .data$xmin, ymax = .data$xmax, fill = .data$cluster),
                xmin = -Inf, xmax = Inf, alpha = 0.15, show.legend = FALSE)
    } else {
      geom_rect(data = rects, aes(xmin = .data$xmin, xmax = .data$xmax, fill = .data$cluster),
                ymin = -Inf, ymax = Inf, alpha = 0.15, show.legend = FALSE)
    }
  }
  if (!coloured) {
    seg_aes <- if (flip) aes(x = .data$y, xend = .data$yend, y = .data$x, yend = .data$xend)
               else aes(x = .data$x, xend = .data$xend, y = .data$y, yend = .data$yend)
    p <- p + geom_segment(seg_aes, colour = spec$colour %||% "grey30", linewidth = spec$linewidth %||% 0.4, lineend = "square")
  } else {
    seg_aes <- if (flip) aes(x = .data$y, xend = .data$yend, y = .data$x, yend = .data$xend, colour = .data$cluster)
               else aes(x = .data$x, xend = .data$xend, y = .data$y, yend = .data$yend, colour = .data$cluster)
    p <- p + geom_segment(seg_aes, linewidth = spec$linewidth %||% 0.4, lineend = "square", show.legend = FALSE) +
      scale_colour_manual(values = cluster_palette(seg$cluster), aesthetics = c("colour", "fill"))
  }
  leaf_scale <- function(f) f(limits = c(0.5, L + 0.5), expand = c(0, 0))
  p <- p + theme_void() + theme(plot.margin = margin(0, 0, 0, 0))
  if (flip) {
    p + scale_x_reverse(limits = c(ymax, 0), expand = c(0, 0)) + leaf_scale(scale_y_continuous) +
      theme(panel.widths = grid::unit(spec$size, "mm"), panel.heights = grid::unit(L * lay$cell_mm, "mm"))
  } else {
    p + scale_y_continuous(limits = c(0, ymax), expand = c(0, 0)) + leaf_scale(scale_x_continuous) +
      theme(panel.heights = grid::unit(spec$size, "mm"), panel.widths = grid::unit(L * lay$cell_mm, "mm"))
  }
}

cluster_palette <- function(cluster) {
  lv <- sort(unique(cluster))
  pal <- c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666")
  pal <- rep_len(pal, length(lv))
  names(pal) <- lv
  pal["trunk"] <- "grey40"
  pal
}

