#' Annotate rows and columns
#'
#' Adds annotation tracks beside the heatmap: coloured bars for categorical
#' data, bar charts for numeric data. Each column of a data frame becomes one
#' track. Tracks align cell to cell with the heatmap, follow its ordering and
#' splits, and get their own legends.
#'
#' @param top,bottom Annotations for columns: a data frame with one row per
#'   column of the matrix, a vector, or a named list of vectors. Values are
#'   matched by name when names are present, else by position.
#' @param left,right The same, for rows.
#' @param type Track type: `"auto"` (tile for categorical, bar for numeric),
#'   `"tile"`, `"bar"`, `"point"`, `"line"`, or `"glyph"` (a point per item:
#'   shapes for categories, sizes for numbers). One value, or a named vector
#'   keyed by track name.
#' @param size Track thickness in millimetres; one value or named by track.
#' @param colours Named list: for a categorical track, a vector of colours
#'   (optionally named by level); for a numeric track, a single fill colour.
#' @param show_legend Draw legends for categorical tracks.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
#' meta <- data.frame(group = rep(c("A", "B"), 5), dose = 1:10)
#' ggcalor(m) + calor_anno(top = meta, left = data.frame(score = runif(20)))
#' @export
calor_anno <- function(top = NULL, bottom = NULL, left = NULL, right = NULL,
                       type = "auto", size = 4, colours = NULL, show_legend = TRUE) {
  structure(list(top = top, bottom = bottom, left = left, right = right,
                 type = type, size = size, colours = colours,
                 show_legend = show_legend),
            class = "calor_anno")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_anno <- function(object, plot, ...) {
  check_calor(plot, "calor_anno()")
  st <- calor_state(plot)
  for (side in c("top", "bottom", "left", "right")) {
    x <- object[[side]]
    if (is.null(x)) next
    items <- if (side %in% c("top", "bottom")) colnames(st$matrix) else rownames(st$matrix)
    tracks <- as_tracks(x, items, side)
    for (tr in tracks) {
      tr$type <- pick(object$type, tr$name, "auto")
      tr$size <- pick(object$size, tr$name, 4)
      tr$colours <- object$colours[[tr$name]]
      tr$show_legend <- object$show_legend
      if (tr$type == "auto") tr$type <- if (is.numeric(tr$values)) "bar" else "tile"
      # Unordered categorical tracks continue along the qualitative palette, so
      # two tracks never share colours by accident.
      if (qualitative_track(tr)) {
        tr$pal_offset <- sum(vapply(unlist(st$anno, recursive = FALSE), function(o)
          if (qualitative_track(o)) length(unique(stats::na.omit(o$values))) else 0L, numeric(1)))
      }
      st$anno[[side]] <- c(st$anno[[side]], list(tr))
    }
  }
  calor_state(plot) <- st
  plot
}

pick <- function(x, name, default) {
  if (is.null(x)) return(default)
  if (!is.null(names(x)) && name %in% names(x)) return(x[[name]])
  if (is.null(names(x)) && length(x) == 1) return(x[[1]])
  default
}

as_tracks <- function(x, items, side) {
  if (is.data.frame(x)) {
    if (!is.null(rownames(x)) && !identical(rownames(x), as.character(seq_len(nrow(x)))) &&
        all(items %in% rownames(x))) x <- x[items, , drop = FALSE]
    cols <- names(x)
    return(lapply(cols, function(nm) list(
      name = nm, values = align_to_items(stats::setNames(x[[nm]], rownames(x) %||% NULL), items, side), side = side)))
  }
  if (is.list(x)) {
    nms <- names(x) %||% paste0(side, seq_along(x))
    return(Map(function(v, nm) list(name = nm, values = align_to_items(v, items, side), side = side), x, nms))
  }
  list(list(name = side, values = align_to_items(x, items, side), side = side))
}

#' Marginal summaries
#'
#' Summarise each row or column of the displayed matrix and draw it as a track:
#' a bar of a statistic or a boxplot of the distribution.
#'
#' @param top,bottom,left,right A statistic name (`"mean"`, `"sum"`, `"median"`,
#'   `"max"`, `"min"`, `"sd"`, `"var"`), `"boxplot"`, or a function of a vector.
#' @param size Track thickness in millimetres.
#' @param fill Fill colour of bars and boxes.
#' @param data Summarise the `"raw"` input values (default) or the
#'   `"display"` values after scaling and masking.
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rpois(200, 5), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
#' ggcalor(m) + calor_margin(right = "sum", bottom = "boxplot")
#' @export
calor_margin <- function(top = NULL, bottom = NULL, left = NULL, right = NULL,
                         size = 10, fill = "#455D7A", data = c("raw", "display")) {
  data <- rlang::arg_match(data)
  structure(list(top = top, bottom = bottom, left = left, right = right,
                 size = size, fill = fill, data = data), class = "calor_margin")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_margin <- function(object, plot, ...) {
  check_calor(plot, "calor_margin()")
  st <- calor_state(plot)
  m <- if (identical(object$data, "raw") && !isTRUE(st$categorical)) st$raw else st$num
  for (side in c("top", "bottom", "left", "right")) {
    f <- object[[side]]
    if (is.null(f)) next
    by_col <- side %in% c("top", "bottom")
    mm <- if (by_col) t(m) else m
    if (identical(f, "boxplot")) {
      tr <- list(name = "", values = NULL, dist = mm, type = "boxplot", side = side)
    } else {
      fn <- if (is.function(f)) f else get(f, envir = asNamespace("stats"), mode = "function", inherits = TRUE)
      vals <- apply(mm, 1, function(v) fn(v[!is.na(v)]))
      tr <- list(name = if (is.character(f)) f else "margin", values = stats::setNames(vals, rownames(mm)),
                 type = "bar", side = side)
    }
    tr$size <- object$size; tr$colours <- object$fill; tr$show_legend <- FALSE
    st$anno[[side]] <- c(st$anno[[side]], list(tr))
  }
  calor_state(plot) <- st
  plot
}

#' Write values in cells
#'
#' @param digits Decimal places.
#' @param size Text size in points.
#' @param colour Text colour.
#' @param format Optional function from values to labels; overrides `digits`.
#' @param ... Passed to [ggplot2::geom_text()].
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
#' ggcalor(m, cell_size = 10) + calor_text(digits = 1)
#' @export
calor_text <- function(digits = 1, size = 7, colour = "grey15", format = NULL, ...) {
  structure(list(digits = digits, size = size, colour = colour, format = format,
                 dots = list(...)), class = "calor_text")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_text <- function(object, plot, ...) {
  check_calor(plot, "calor_text()")
  st <- calor_state(plot)
  st$text <- object
  calor_state(plot) <- st
  plot
}

# Build one annotation track as a ggplot aligned to the layout of `axis`.
track_plot <- function(tr, lay, cell_mm, interactive = NULL) {
  if (identical(tr$type, "panel")) return(panel_plot(tr, lay, cell_mm))
  along_cols <- tr$side %in% c("top", "bottom")
  n <- length(lay$order)
  pos <- lay$pos
  if (!along_cols) pos <- lay$L + 1 - pos  # rows run top to bottom
  lim <- c(0.5, lay$L + 0.5)
  th <- theme_void(base_family = calor_family()) + theme(plot.margin = margin(0, 0, 0, 0))
  name_theme <- if (along_cols) {
    theme(axis.title.y = element_text(size = 7, angle = 0, hjust = 1, vjust = 0.5, margin = margin(r = 2.5)))
  } else {
    theme(axis.title.x = element_text(size = 7, angle = 90, hjust = 1, vjust = 0.5, margin = margin(t = 2.5)))
  }
  along_scale <- if (along_cols) scale_x_continuous(limits = lim, expand = c(0, 0))
                 else scale_y_continuous(limits = lim, expand = c(0, 0))
  axis_bits <- NULL

  if (tr$type == "boxplot") {
    d <- tr$dist[lay$order, , drop = FALSE]
    df <- data.frame(pos = rep(pos, ncol(d)), v = as.vector(d))
    p <- if (along_cols) {
      ggplot(df, aes(x = .data$pos, y = .data$v, group = .data$pos))
    } else {
      ggplot(df, aes(y = .data$pos, x = .data$v, group = .data$pos))
    }
    p <- p + geom_boxplot(width = 0.62, linewidth = 0.3, outlier.size = 0.3, outlier.alpha = 0.6,
                          fill = tr$colours %||% "#D6E4EE", colour = calor_ink, staplewidth = 0.4,
                          orientation = if (along_cols) "x" else "y", na.rm = TRUE)
    axis_bits <- value_axis(along_cols, tr$side, integer = FALSE)
  } else {
    df <- data.frame(pos = pos, value = unname(tr$values[lay$order]))
    if (tr$type == "tile") {
      p <- ggplot(df, if (along_cols) aes(x = .data$pos, y = 1, fill = .data$value)
                      else aes(x = 1, y = .data$pos, fill = .data$value))
      if (!is.null(interactive) && isTRUE(interactive$tracks)) {
        df$.tooltip <- paste0(tr$name, ": ", df$value)
        df$.data_id <- if (along_cols == (interactive$data_id == "col")) lay$order
                       else paste(tr$name, lay$order, sep = "\r")
        p <- p %+% df + ggiraph::geom_tile_interactive(
          aes(tooltip = .data$.tooltip, data_id = .data$.data_id),
          width = 1, height = 1, colour = NA, show.legend = tr$show_legend)
      } else {
        p <- p + geom_tile(width = 1, height = 1, colour = NA, show.legend = tr$show_legend)
      }
      p <- p + labs(fill = tr$name)
      p <- p + if (along_cols) scale_y_continuous(limits = c(0.5, 1.5), expand = c(0, 0))
               else scale_x_continuous(limits = c(0.5, 1.5), expand = c(0, 0))
      p <- p + if (is.numeric(df$value)) {
        if (!is.null(tr$colours)) scale_fill_gradientn(colours = tr$colours) else scale_fill_viridis_c(option = "mako", direction = -1)
      } else if (!is.null(tr$colours)) {
        scale_fill_manual(values = tr$colours)
      } else if (is.ordered(df$value)) {
        # Ordered levels read as a light-to-dark sequence.
        scale_fill_manual(values = grDevices::colorRampPalette(c("#DEEBF7", "#08519C"))(nlevels(df$value)))
      } else {
        calor_qualitative_scale(tr$pal_offset %||% 0)
      }
    } else if (tr$type == "glyph") {
      col <- tr$colours %||% calor_ink
      p <- ggplot(df, if (along_cols) aes(x = .data$pos, y = 1) else aes(x = 1, y = .data$pos))
      p <- p + if (is.numeric(df$value)) {
        list(geom_point(aes(size = .data$value), colour = col, na.rm = TRUE, show.legend = tr$show_legend),
             scale_size(range = c(0.3, 2.6)), labs(size = tr$name))
      } else {
        list(geom_point(aes(shape = .data$value), size = 1.8, colour = col, fill = col, na.rm = TRUE, show.legend = tr$show_legend),
             scale_shape_manual(values = c(16, 1, 17, 2, 15, 0, 18, 5)), labs(shape = tr$name))
      }
      p <- p + if (along_cols) scale_y_continuous(limits = c(0.5, 1.5), expand = c(0, 0))
               else scale_x_continuous(limits = c(0.5, 1.5), expand = c(0, 0))
    } else if (tr$type == "bracket") {
      p <- bracket_plot(df, tr, along_cols)
    } else {
      fill <- tr$colours %||% "#455D7A"
      p <- if (along_cols) ggplot(df, aes(x = .data$pos, y = .data$value)) else ggplot(df, aes(y = .data$pos, x = .data$value))
      rng <- range(df$value, na.rm = TRUE)
      if (tr$type == "bar" && rng[1] < 0 && rng[2] > 0) {
        # A baseline makes bars on both sides of zero readable.
        p <- p + if (along_cols) geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3)
                 else geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.3)
      }
      p <- p + switch(tr$type,
        bar = geom_col(width = 0.72, fill = fill, colour = NA, orientation = if (along_cols) "x" else "y", na.rm = TRUE),
        point = geom_point(size = 1, colour = fill, na.rm = TRUE),
        line = geom_line(aes(group = 1), colour = fill, linewidth = 0.4, na.rm = TRUE),
        cli::cli_abort("Unknown annotation type {.val {tr$type}}.")
      )
      v <- df$value[is.finite(df$value)]
      axis_bits <- value_axis(along_cols, tr$side, integer = length(v) && all(v == round(v)))
    }
  }
  # The complete theme goes first so the axis and name settings survive it.
  p <- p + along_scale + th + axis_bits + name_theme
  p <- p + if (along_cols) labs(y = tr$name) else labs(x = tr$name)
  size_theme <- if (along_cols) {
    theme(panel.widths = grid::unit(lay$L * cell_mm, "mm"), panel.heights = grid::unit(tr$size, "mm"))
  } else {
    theme(panel.heights = grid::unit(lay$L * cell_mm, "mm"), panel.widths = grid::unit(tr$size, "mm"))
  }
  p + size_theme
}

# A small value axis for numeric tracks; bars on the left grow leftwards.
# Three ticks at most, never dropped, with a thin axis line.
value_axis <- function(along_cols, side, integer = FALSE) {
  brk <- function(n) function(lim) {
    # Ask for more breaks until at least two land inside the limits; counts
    # get whole numbers.
    for (k in n:(n + 4)) {
      b <- scales::breaks_extended(n = k, only.loose = FALSE)(lim)
      b <- b[b >= lim[1] & b <= lim[2]]
      if (integer) b <- b[b == round(b)]
      if (length(b) >= 2) break
    }
    b
  }
  # 800K rather than 8e+05.
  lab <- scales::label_number(scale_cut = scales::cut_short_scale())
  txt <- element_text(size = 5.5)
  line <- element_line(linewidth = 0.3, colour = "grey55")
  tick <- theme(axis.ticks.length = grid::unit(0.7, "mm"))
  if (along_cols) {
    list(scale_y_continuous(expand = expansion(mult = c(0.02, 0.08)), breaks = brk(3), labels = lab),
         theme(axis.text.y = txt, axis.text.y.left = element_text(hjust = 1, margin = margin(r = 1)),
               axis.ticks.y = line, axis.line.y = line), tick)
  } else if (side == "left") {
    list(scale_x_reverse(expand = expansion(mult = c(0.08, 0.02)), breaks = brk(3), labels = lab),
         theme(axis.text.x = txt, axis.text.x.bottom = element_text(margin = margin(t = 1)),
               axis.ticks.x = line, axis.line.x = line), tick)
  } else {
    list(scale_x_continuous(expand = expansion(mult = c(0.02, 0.08)), breaks = brk(3), labels = lab),
         theme(axis.text.x = txt, axis.text.x.bottom = element_text(margin = margin(t = 1)),
               axis.ticks.x = line, axis.line.x = line), tick)
  }
}

# Put the heatmap's row or column names on the outer edge of a track, so
# names sit outside the tracks and the tracks touch the cells.
place_labels <- function(p, lay, side, main_theme) {
  along_cols <- side %in% c("top", "bottom")
  pos <- if (along_cols) lay$pos else lay$L + 1 - lay$pos
  p@scales <- p@scales$clone()
  sc <- p@scales$get_scales(if (along_cols) "x" else "y")
  if (is.null(sc)) return(p)
  if (sc$is_discrete()) {
    # A calor_panel(): its limits are already the names.
    sc$breaks <- lay$order
  } else {
    sc$breaks <- pos
    sc$labels <- lay$order
  }
  sc$position <- side
  el <- paste0("axis.text.", if (along_cols) "x." else "y.", side)
  args <- stats::setNames(list(calc_element(el, main_theme)), el)
  p + rlang::inject(theme(!!!args))
}

# Give a track the main plot's legend typography so collected legends match.
match_legend_theme <- function(p, main_theme) {
  # Only size, colour and face: the guide keeps its own alignment defaults.
  font <- function(el) {
    e <- calc_element(el, main_theme)
    element_text(size = e$size, colour = e$colour, face = e$face, family = e$family)
  }
  ax <- calc_element("axis.text", main_theme)
  p + theme(text = element_text(family = ax$family, colour = ax$colour),
            legend.title = font("legend.title"),
            legend.text = font("legend.text"),
            legend.key.size = calc_element("legend.key.size", main_theme),
            legend.key.spacing = calc_element("legend.key.spacing", main_theme))
}

#' Group brackets
#'
#' Draws a bracket over each run of equal labels along rows or columns, with
#' the label beside it. Runs are found in the final order, so combine with
#' [calor_split()] or a sorted axis for clean groups.
#'
#' @param cols,rows A vector of group labels, named or in matrix order.
#' @param side `"top"` or `"bottom"` for columns, `"left"` or `"right"` for rows.
#' @param size Track thickness in millimetres.
#' @param colour Line colour.
#' @param text_size Label size in points.
#' @param angle Label angle in degrees; for column brackets, rotate when groups
#'   are narrow (then also raise `size`).
#' @return An object to add to a [ggcalor()] plot with `+`.
#' @examples
#' m <- matrix(rnorm(100), 10, 10, dimnames = list(paste0("g", 1:10), paste0("s", 1:10)))
#' ggcalor(m) + calor_bracket(cols = rep(c("ctrl", "treated"), each = 5), side = "bottom")
#' @export
calor_bracket <- function(cols = NULL, rows = NULL, side = NULL, size = 6,
                          colour = "grey20", text_size = 7, angle = 0) {
  structure(list(cols = cols, rows = rows, side = side, size = size, colour = colour,
                 text_size = text_size, angle = angle), class = "calor_bracket")
}

#' @exportS3Method ggplot2::ggplot_add
ggplot_add.calor_bracket <- function(object, plot, ...) {
  check_calor(plot, "calor_bracket()")
  st <- calor_state(plot)
  if (!is.null(object$cols)) {
    side <- object$side %||% "bottom"
    tr <- list(name = "", values = align_to_items(object$cols, colnames(st$matrix), "cols"),
               type = "bracket", side = side, size = object$size, colours = object$colour,
               text_size = object$text_size, angle = object$angle, show_legend = FALSE)
    st$anno[[side]] <- c(st$anno[[side]], list(tr))
  }
  if (!is.null(object$rows)) {
    side <- object$side %||% "right"
    tr <- list(name = "", values = align_to_items(object$rows, rownames(st$matrix), "rows"),
               type = "bracket", side = side, size = object$size, colours = object$colour,
               text_size = object$text_size, show_legend = FALSE)
    st$anno[[side]] <- c(st$anno[[side]], list(tr))
  }
  calor_state(plot) <- st
  plot
}

bracket_plot <- function(df, tr, along_cols) {
  # df has pos (in display order along the axis) and value; find runs.
  o <- order(df$pos)
  r <- rle(as.character(df$value[o]))
  ends <- cumsum(r$lengths); starts <- ends - r$lengths + 1
  runs <- data.frame(label = r$values, from = df$pos[o][starts] - 0.4, to = df$pos[o][ends] + 0.4)
  runs$mid <- (runs$from + runs$to) / 2
  inward <- tr$side %in% c("top", "left")   # ticks point toward the heatmap
  angle <- tr$angle %||% 0
  rotated <- along_cols && abs(angle) > 10
  # Heatmap sits below a top track and above a bottom track; rotated labels
  # hang away from it, so the line moves close to the heatmap edge.
  line_y <- if (inward) (if (rotated) 0.1 else 0.35) else (if (rotated) 0.9 else 0.65)
  tick_y <- line_y + if (inward) -0.12 else 0.12
  text_y <- if (inward) line_y + 0.1 else line_y - 0.1
  hjust <- if (!rotated) 0.5 else if (inward) 0 else 1
  vjust <- if (rotated) 0.5 else if (inward) 0 else 1
  col <- tr$colours %||% calor_ink
  if (along_cols) {
    p <- ggplot(runs) +
      geom_segment(aes(x = .data$from, xend = .data$to), y = line_y, yend = line_y, colour = col, linewidth = 0.4) +
      geom_segment(aes(x = .data$from, xend = .data$from), y = line_y, yend = tick_y, colour = col, linewidth = 0.4) +
      geom_segment(aes(x = .data$to, xend = .data$to), y = line_y, yend = tick_y, colour = col, linewidth = 0.4) +
      geom_text(aes(x = .data$mid, label = .data$label), y = text_y, size = tr$text_size / .pt, colour = col,
                angle = angle, hjust = hjust, vjust = vjust) +
      scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) + coord_cartesian(clip = "off")
  } else {
    p <- ggplot(runs) +
      geom_segment(aes(y = .data$from, yend = .data$to), x = line_y, xend = line_y, colour = col, linewidth = 0.4) +
      geom_segment(aes(y = .data$from, yend = .data$from), x = line_y, xend = tick_y, colour = col, linewidth = 0.4) +
      geom_segment(aes(y = .data$to, yend = .data$to), x = line_y, xend = tick_y, colour = col, linewidth = 0.4) +
      geom_text(aes(y = .data$mid, label = .data$label), x = text_y, size = tr$text_size / .pt, colour = col,
                angle = if (tr$side == "left") 90 else -90) +
      scale_x_continuous(limits = c(0, 1), expand = c(0, 0))
  }
  p
}

#' Discrete palette for annotation tracks
#'
#' A qualitative palette of twelve saturated, clearly separated colours, used
#' for categorical annotation tracks, cluster highlights and waffle charts.
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @export
scale_fill_calor_d <- function(...) calor_qualitative_scale(0, ...)

calor_pal <- c("#E4572E", "#F3A712", "#3B8F5C", "#8E5BA8", "#2E86AB", "#E07BA1",
               "#4EC0B9", "#A0673E", "#1B3A57", "#C9B037", "#7A2E3A", "#9DB4C0")
calor_ink <- "#2B2B2B"

# The qualitative palette starting `offset` colours in, wrapping around.
calor_qualitative_scale <- function(offset = 0, ...) {
  pal <- calor_pal[(seq_along(calor_pal) + offset - 1) %% length(calor_pal) + 1]
  discrete_scale("fill", palette = function(n) rep_len(pal, n), ...)
}

qualitative_track <- function(tr) {
  identical(tr$type, "tile") && is.null(tr$colours) && !is.numeric(tr$values) && !is.ordered(tr$values)
}
