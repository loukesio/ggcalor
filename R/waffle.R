#' Waffle chart: a unit grid of counts
#'
#' Counts become cells on the same square grid as a heatmap: one cell per
#' share of the total, filled column by column from the bottom. Give a `by`
#' column to draw one waffle per group side by side.
#'
#' @param data A named vector of counts, or a data frame.
#' @param category,count,by Column names when `data` is a data frame.
#' @param n Cells per waffle.
#' @param rows Rows per waffle.
#' @param cell_size,cell_gap,cell_radius Cell geometry, as in [ggcalor()].
#' @return A `ggplot` object.
#' @examples
#' calor_waffle(c(apples = 45, pears = 30, plums = 25), n = 100, rows = 10)
#' df <- data.frame(region = rep(c("north", "south"), each = 3),
#'                  crop = rep(c("wheat", "rice", "maize"), 2), tons = c(5, 3, 2, 1, 6, 3))
#' calor_waffle(df, "crop", "tons", by = "region", n = 50, rows = 10)
#' @export
calor_waffle <- function(data, category = NULL, count = NULL, by = NULL, n = 100, rows = 10,
                     cell_size = 4, cell_gap = 0.15, cell_radius = 0.3) {
  if (is.data.frame(data)) {
    category <- category %||% names(data)[1]; count <- count %||% names(data)[2]
    df <- data.frame(category = data[[category]], count = data[[count]],
                     by = if (is.null(by)) "all" else data[[by]])
  } else {
    df <- data.frame(category = names(data), count = as.numeric(data), by = "all")
  }
  df$category <- if (is.factor(df$category)) df$category else factor(df$category, levels = unique(df$category))
  df$by <- if (is.factor(df$by)) df$by else factor(df$by, levels = unique(df$by))
  cells <- do.call(rbind, lapply(split(df, df$by), function(g) {
    k <- largest_remainder(g$count, n)
    data.frame(by = g$by[1], category = rep(g$category, k), i = seq_len(sum(k)))
  }))
  cells$col <- (cells$i - 1) %/% rows + 1
  cells$row <- (cells$i - 1) %% rows + 1
  ncols <- ceiling(n / rows)
  share <- 100 / n
  p <- ggplot(cells, aes(x = .data$col, y = .data$row, fill = .data$category)) +
    geom_cell(gap = cell_gap, radius = cell_radius, colour = NA) +
    scale_x_continuous(limits = c(0.5, ncols + 0.5), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0.5, rows + 0.5), expand = c(0, 0)) +
    scale_fill_calor_d() +
    labs(fill = NULL, caption = sprintf("1 square = %s%%", format(share, digits = 2))) +
    theme_void(base_family = calor_family()) +
    theme(text = element_text(colour = calor_ink),
          panel.widths = grid::unit(rep(ncols * cell_size, nlevels(cells$by)), "mm"),
          panel.heights = grid::unit(rows * cell_size, "mm"),
          panel.spacing = grid::unit(cell_size, "mm"), strip.text = element_text(size = 9, face = "bold", hjust = 0, margin = margin(b = 3)),
          plot.title = element_text(size = 15, face = "bold", margin = margin(b = 4)),
          plot.subtitle = element_text(size = 10, colour = "#5A5A5A", margin = margin(b = 12)),
          plot.caption = element_text(family = calor_family("mono"), size = 7, colour = "#7A7A7A", hjust = 0),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.margin = margin(12, 14, 10, 14), legend.key.size = grid::unit(4, "mm"))
  if (nlevels(cells$by) > 1) p <- p + facet_wrap(vars(.data$by), nrow = 1)
  p
}

largest_remainder <- function(counts, n) {
  q <- counts / sum(counts) * n
  k <- floor(q)
  rem <- n - sum(k)
  if (rem > 0) {
    o <- order(q - k, decreasing = TRUE)[seq_len(rem)]
    k[o] <- k[o] + 1
  }
  k
}
