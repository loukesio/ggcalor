# Annotate rows and columns

Adds annotation tracks beside the heatmap: coloured bars for categorical
data, bar charts for numeric data. Each column of a data frame becomes
one track. Tracks align cell to cell with the heatmap, follow its
ordering and splits, and get their own legends.

## Usage

``` r
calor_anno(
  top = NULL,
  bottom = NULL,
  left = NULL,
  right = NULL,
  type = "auto",
  size = 4,
  colours = NULL,
  show_legend = TRUE
)
```

## Arguments

- top, bottom:

  Annotations for columns: a data frame with one row per column of the
  matrix, a vector, or a named list of vectors. Values are matched by
  name when names are present, else by position.

- left, right:

  The same, for rows.

- type:

  Track type: `"auto"` (tile for categorical, bar for numeric),
  `"tile"`, `"bar"`, `"point"`, `"line"`, or `"glyph"` (a point per
  item: shapes for categories, sizes for numbers). One value, or a named
  vector keyed by track name.

- size:

  Track thickness in millimetres; one value or named by track.

- colours:

  Named list: for a categorical track, a vector of colours (optionally
  named by level); for a numeric track, a single fill colour.

- show_legend:

  Draw legends for categorical tracks.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
meta <- data.frame(group = rep(c("A", "B"), 5), dose = 1:10)
ggcalor(m) + calor_anno(top = meta, left = data.frame(score = runif(20)))
```
