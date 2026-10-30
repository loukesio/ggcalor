# Waffle chart: a unit grid of counts

Counts become cells on the same square grid as a heatmap: one cell per
share of the total, filled column by column from the bottom. Give a `by`
column to draw one waffle per group side by side.

## Usage

``` r
ggwaffle(
  data,
  category = NULL,
  count = NULL,
  by = NULL,
  n = 100,
  rows = 10,
  cell_size = 4,
  cell_gap = 0.15,
  cell_radius = 0.3
)
```

## Arguments

- data:

  A named vector of counts, or a data frame.

- category, count, by:

  Column names when `data` is a data frame.

- n:

  Cells per waffle.

- rows:

  Rows per waffle.

- cell_size, cell_gap, cell_radius:

  Cell geometry, as in
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md).

## Value

A `ggplot` object.

## Examples

``` r
ggwaffle(c(apples = 45, pears = 30, plums = 25), n = 100, rows = 10)

df <- data.frame(region = rep(c("north", "south"), each = 3),
                 crop = rep(c("wheat", "rice", "maize"), 2), tons = c(5, 3, 2, 1, 6, 3))
ggwaffle(df, "crop", "tons", by = "region", n = 50, rows = 10)
```
