# Positions of rows and columns, for connecting plots

Gives the position of named rows or columns in the cell coordinates of
[`calor_gtable()`](https://loukesio.github.io/ggcalor/reference/calor_gtable.md),
after clustering, ordering and splitting, on one edge of the cells. Use
it as the anchors of a ggcalor plot in ggweave, to draw threads from a
row or column to the same item in another plot.

## Usage

``` r
calor_anchors(
  plot,
  rows = NULL,
  cols = NULL,
  side = NULL,
  outside = TRUE,
  id = "id"
)
```

## Arguments

- plot:

  A
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
  plot.

- rows, cols:

  Names of rows or columns. Give one of them.

- side:

  Edge of the cells the anchors sit on: `"left"` or `"right"` for rows
  (default `"right"`), `"top"` or `"bottom"` for columns (default
  `"bottom"`), or `"centre"` for the middle of the row or column.

- outside:

  If `TRUE` (default), anchors on an edge sit beyond the trees and
  tracks on that side, so threads do not cross them.

- id:

  Name of the identifier column.

## Value

A data frame with columns `id`, `x` and `y`.

## Examples

``` r
m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
p <- ggcalor(m) + calor_dendro(rows = TRUE)
calor_anchors(p, rows = c("a", "c"))
#>   id   x y
#> 1  a 5.5 2
#> 2  c 5.5 1
```
