# ---- Layout resolution ------------------------------------------------------
# For one axis, turn order / dendro / split specs into: final order, slice
# factor, cell positions (with gaps, in cell units), tree segments and
# highlight rectangles already positioned.
resolve_axis <- function(st, axis) {
  m <- st$num %||% st$matrix
  mm <- if (axis == "rows") m else t(m)
  mm0 <- mm; mm0[is.na(mm0)] <- 0
  items <- rownames(mm); n <- length(items)
  d <- st$dendro[[axis]]; sp <- st$split[[axis]]; o <- st$order[[axis]]
  cell_mm <- if (axis == "rows") st$cell_size[2] else st$cell_size[1]
  k_split <- is.numeric(sp) && length(sp) == 1
  if (k_split && is.null(d)) {
    d <- list(method = "complete", dist = "euclidean", k = NULL, show_tree = FALSE, tree = TRUE, size = 0)
  }
  segs <- NULL; height <- 0; hc <- NULL; cl_items <- NULL

  if (!is.null(d) && (is.null(sp) || k_split)) {
    # One global tree; optional cut into k contiguous slices.
    hc <- compute_hclust(d, mm0)
    ord <- items[hc$order]
    sg <- hclust_segments(hc, k = d$k)
    segs <- sg$segments
    if (!is.null(d$k)) cl_items <- stats::cutree(hc, k = d$k)[hc$order]
    if (k_split) {
      cl <- stats::cutree(hc, k = sp)[hc$order]
      slices <- factor(match(cl, unique(cl)))
      # Drop every segment of merges that join different slices (the trunk),
      # so each slice shows its own subtree without a stem.
      node_cl <- hclust_segments(hc, k = sp)$segments$cluster[seq(2, nrow(segs), by = 3)]
      segs <- segs[rep(node_cl != "trunk", each = 3), , drop = FALSE]
    } else {
      slices <- factor(rep("all", n))
    }
    height <- sg$height
  } else if (!is.null(sp)) {
    # Group split; cluster or order within each slice.
    grp <- align_to_items(sp, items, axis)
    grp <- if (is.factor(grp)) droplevels(grp) else factor(grp, levels = unique(grp))
    ord <- character(); seg_list <- list(); offset <- 0
    for (lv in levels(grp)) {
      it <- items[grp == lv]
      sub <- mm0[it, , drop = FALSE]
      if (!is.null(d) && length(it) > 1) {
        hc_s <- compute_hclust(d, sub)
        o_s <- it[hc_s$order]
        sg <- hclust_segments(hc_s, NULL)
        s <- sg$segments; s$x <- s$x + offset; s$xend <- s$xend + offset
        seg_list[[lv]] <- s; height <- max(height, sg$height)
      } else if (!is.null(o)) {
        o_s <- resolve_order(o[[axis]], mm[it, , drop = FALSE], o$decreasing)
      } else {
        o_s <- it
      }
      ord <- c(ord, o_s); offset <- offset + length(it)
    }
    slices <- grp[ord]
    if (length(seg_list)) segs <- do.call(rbind, seg_list)
  } else {
    ord <- if (is.null(o)) items else resolve_order(o[[axis]], mm, o$decreasing)
    slices <- factor(rep("all", n))
  }

  nsl <- nlevels(slices)
  g <- if (nsl > 1) (st$split$gap %||% 0) / cell_mm else 0
  pos <- seq_len(n) + (as.integer(slices) - 1) * g
  L <- n + (nsl - 1) * g
  shift <- function(x) x + (as.integer(slices)[pmin(n, pmax(1, round(x)))] - 1) * g
  if (!is.null(segs)) {
    segs$x <- shift(segs$x); segs$xend <- shift(segs$xend)
  }
  rects <- NULL
  if (!is.null(cl_items)) {
    rects <- do.call(rbind, lapply(split(pos, cl_items), function(p) data.frame(xmin = min(p) - 0.5, xmax = max(p) + 0.5)))
    rects$cluster <- paste0("cluster ", names(split(pos, cl_items)))
  }
  list(order = ord, slices = slices, pos = pos, L = L, g = g, n = n, segs = segs,
       rects = rects, height = height, hc = hc, cell_mm = cell_mm,
       show_tree = !is.null(d) && isTRUE(d$show_tree) && !is.null(segs), dspec = d)
}

resolve_layout <- function(st) {
  rows <- resolve_axis(st, "rows")
  # Columns see the rows in their final order, so "memo" sorts by the top row.
  st2 <- st
  st2$num <- st$num[rows$order, , drop = FALSE]
  st2$matrix <- st$matrix[rows$order, , drop = FALSE]
  st$lay <- list(rows = rows, cols = resolve_axis(st2, "cols"))
  st$row_order <- st$lay$rows$order
  st$col_order <- st$lay$cols$order
  st
}

# ---- Plain-ggplot helpers ---------------------------------------------------
# S7::convert() drops the S3 alias classes ("ggplot", "gg") that patchwork and
# other S3 code dispatch on, so restore them.
as_plain_ggplot <- function(plot) {
  out <- S7::convert(plot, ggplot2::class_ggplot)
  class(out) <- class(ggplot2::ggplot())
  out
}
as_plain_built <- function(built) {
  out <- S7::convert(built, ggplot2::class_ggplot_built)
  class(out) <- class(ggplot2::ggplot_build(ggplot2::ggplot()))
  out
}

# ---- Build ------------------------------------------------------------------
S7::method(ggplot_build, class_calor) <- function(plot, ...) {
  st <- resolve_layout(calor_state(plot))
  lr <- st$lay$rows; lc <- st$lay$cols
  base <- as_plain_ggplot(plot)
  d <- base@data
  d$.row <- factor(as.character(d$.row), levels = lr$order)
  d$.col <- factor(as.character(d$.col), levels = lc$order)
  rs <- nlevels(lr$slices) > 1; cs <- nlevels(lc$slices) > 1
  if (rs) d$.rsplit <- lr$slices[match(as.character(d$.row), lr$order)]
  if (cs) d$.csplit <- lc$slices[match(as.character(d$.col), lc$order)]
  hex <- identical(st$cell$shape, "hex")
  if (hex) d <- hex_positions(d, lr$order, lc$order)
  if (!is.null(st$text)) {
    tx <- st$text
    d$.label <- if (is.function(tx$format)) tx$format(d$.value)
                else if (is.numeric(d$.value)) formatC(d$.value, digits = tx$digits, format = "f")
                else as.character(d$.value)
    d$.label[is.na(d$.value)] <- ""
  }
  base@data <- d
  base <- apply_interactive(base, st)

  if (!is.null(st$text)) {
    tx <- st$text
    base <- base + rlang::inject(geom_text(aes(label = .data$.label), size = tx$size / .pt,
                                           colour = tx$colour, !!!tx$dots))
  }
  if (rs || cs) {
    base <- base + facet_grid(
      rows = if (rs) vars(.data$.rsplit), cols = if (cs) vars(.data$.csplit),
      scales = "free", space = "free"
    )
    if (!isTRUE(st$split$labels)) base <- base + theme(strip.text = element_blank())
  }
  if (hex) {
    # Lattice positions are fixed at construction; nothing to resize.
  } else if (base@coordinates$is_linear()) {
    base <- base + theme(
      panel.spacing = grid::unit(st$split$gap %||% 0, "mm"),
      panel.widths = grid::unit(as.vector(table(lc$slices)) * lc$cell_mm, "mm"),
      panel.heights = grid::unit(as.vector(table(lr$slices)) * lr$cell_mm, "mm")
    )
  } else {
    # Radial: keep the radial cell height; diameter follows from the hole.
    inner <- base@coordinates$inner_radius %||% 0
    if (is.numeric(inner) && length(inner) == 2) inner <- inner[1]
    dia <- 2 * lr$n * lr$cell_mm / max(1 - inner, 0.1)
    base <- base + theme(panel.widths = grid::unit(dia, "mm"), panel.heights = grid::unit(dia, "mm"))
  }
  # Labels that cannot fit in the cell height or width are dropped.
  if (lr$cell_mm < 2) base <- base + theme(axis.text.y = element_blank())
  if (lc$cell_mm < 2) base <- base + theme(axis.text.x = element_blank())
  # With a column tree on top, labels read better underneath the cells.
  if (identical(st$label_position, "auto") && lc$show_tree) {
    base@scales <- base@scales$clone()
    xs <- base@scales$get_scales("x")
    if (!is.null(xs)) xs$position <- "bottom"
  }
  built <- ggplot2::ggplot_build(base)
  class_calor_built(built, calor = c(st, list(plot = base)))
}

# ---- Assemble ---------------------------------------------------------------
S7::method(ggplot_gtable, class_calor_built) <- function(data, ...) {
  st <- data@calor
  lr <- st$lay$rows; lc <- st$lay$cols
  top <- bottom <- left <- right <- list()
  if (lc$show_tree) top <- c(top, list(dendro_plot(lc, lc$dspec, "top")))
  if (lr$show_tree) left <- c(left, list(dendro_plot(lr, lr$dspec, "left")))
  it <- st$interactive
  for (tr in st$anno$top) top <- c(top, list(track_plot(tr, lc, lc$cell_mm, it)))
  for (tr in st$anno$left) left <- c(left, list(track_plot(tr, lr, lr$cell_mm, it)))
  for (tr in st$anno$bottom) bottom <- c(bottom, list(track_plot(tr, lc, lc$cell_mm, it)))
  for (tr in st$anno$right) right <- c(right, list(track_plot(tr, lr, lr$cell_mm, it)))

  main <- apply_histogram_legend(st$plot, st)
  has_tracks <- length(top) + length(bottom) + length(left) + length(right) > 0
  if (!main@coordinates$is_linear() || identical(st$cell$shape, "hex")) {
    if (has_tracks) cli::cli_warn("Dendrograms and annotation tracks are not drawn with hex cells or non-linear coordinates.")
    has_tracks <- FALSE
  }
  if (!has_tracks) {
    if (identical(main, st$plot)) return(ggplot2::ggplot_gtable(as_plain_built(data)))
    return(ggplot2::ggplot_gtable(ggplot2::ggplot_build(main)))
  }

  # Titles move to the whole composition so they sit above the tracks.
  lab <- main@labels
  titles <- Filter(Negate(is.null), lab[intersect(c("title", "subtitle", "caption"), names(lab))])
  if (length(titles)) main <- main + labs(title = NULL, subtitle = NULL, caption = NULL)

  pieces <- c(top, list(main), bottom, left, right)
  ids <- c(LETTERS, letters)[seq_along(pieces)]
  names(pieces) <- ids
  nt <- length(top); nb <- length(bottom); nl <- length(left); nr <- length(right)
  row_ids <- ids[seq_len(nt + 1 + nb)]                 # top..., main, bottom...
  col_ids <- c(ids[nt + 1 + nb + seq_len(nl)], ids[nt + 1], ids[nt + 1 + nb + nl + seq_len(nr)])
  main_id <- ids[nt + 1]
  design <- vapply(row_ids, function(r) paste(vapply(col_ids, function(cc) {
    if (r == main_id && cc == main_id) main_id
    else if (r == main_id) cc
    else if (cc == main_id) r
    else "#"
  }, character(1)), collapse = ""), character(1))
  pw <- patchwork::wrap_plots(pieces, design = paste(design, collapse = "\n")) +
    patchwork::plot_layout(guides = "collect")
  if (length(titles)) {
    th <- main@theme
    pw <- pw + patchwork::plot_annotation(
      title = titles$title, subtitle = titles$subtitle, caption = titles$caption,
      theme = th[intersect(c("plot.title", "plot.subtitle", "plot.caption", "text", "title",
                             "plot.title.position", "plot.caption.position"), names(th))]
    )
  }
  patchwork::patchworkGrob(pw)
}
