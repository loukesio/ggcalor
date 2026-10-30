# Create a heatmap with square cells

`ggcalor()` builds a heatmap as a grammar of cells. Cells are square by
default and sized in millimetres, so the plot sizes itself instead of
the device. The result is a `ggplot` object: add themes, scales, labels,
and `calor_*()` verbs with `+`.

## Usage

``` r
ggcalor(
  data,
  rows = NULL,
  cols = NULL,
  value = NULL,
  cell_size = 5,
  cell_gap = 0,
  cell_shape = c("square", "circle", "hex"),
  cell_radius = 0,
  cell_area = NULL,
  scale = c("none", "row", "column"),
  scale_method = c("zscore", "minmax"),
  mask = NULL,
  na_fill = "grey92",
  border = "white",
  palette = "auto",
  raster = c("auto", "never", "always"),
  raster_threshold = 20000,
  smooth = c("none", "contour", "raster"),
  smooth_sigma = 1,
  smooth_bins = 9,
  labels = c("both", "rows", "cols", "none"),
  label_position = c("auto", "top", "bottom")
)
```

## Arguments

- data:

  A numeric or categorical matrix, a wide data frame, or a long data
  frame (then give `rows`, `cols`, `value`). Categorical values get a
  discrete fill; clustering, ordering and margins then use presence
  (1/0).

- rows, cols, value:

  Column names for long data. See
  [`calor_matrix()`](https://loukesio.github.io/ggcalor/reference/calor_matrix.md).

- cell_size:

  Cell size in millimetres. Give one number for square cells or
  `c(width, height)`.

- cell_gap:

  Gap between cells as a fraction of the cell (0 to 1).

- cell_shape:

  `"square"`, `"circle"` or `"hex"`. Hexagons tile an offset lattice, so
  trees and tracks are not drawn with them.

- cell_radius:

  Corner radius of square cells in millimetres.

- cell_area:

  Optional matrix of the same shape whose values (scaled to 0 to 1) set
  each cell's area, for dot plots.

- scale:

  Scale values by `"row"` or `"column"` before plotting, or `"none"`.

- scale_method:

  `"zscore"` or `"minmax"`. See
  [`calor_scale()`](https://loukesio.github.io/ggcalor/reference/calor_scale.md).

- mask:

  Optional logical matrix; `TRUE` cells are hidden (drawn as NA).

- na_fill:

  Fill colour for missing or masked cells. Also applied to a fill scale
  you add, unless that scale sets its own `na.value`.

- border:

  Colour of the cell border, or `NA` for none.

- palette:

  `"auto"` picks a diverging palette when values span zero and a
  sequential one otherwise. Any `scale_fill_*()` can be added later to
  override.

- raster:

  `"auto"` draws cells as a raster image when the matrix has more than
  `raster_threshold` cells, `"always"` or `"never"`. Raster cells have
  no gap, border or shape.

- raster_threshold:

  Cell count above which `"auto"` rasterises.

- smooth:

  `"none"` draws cells. `"contour"` interpolates and blurs the matrix
  into a surface drawn as filled contour bands; `"raster"` draws the
  same surface as a continuous image. Dendrograms and tracks still
  align.

- smooth_sigma:

  Blur radius in cells.

- smooth_bins:

  Approximate number of contour bands; breaks are rounded to pretty
  values.

- labels:

  Which labels to show: `"both"`, `"rows"`, `"cols"` or `"none"`.

- label_position:

  Where column labels go: `"auto"` (top, or bottom when a column
  dendrogram is present), `"top"` or `"bottom"`.

## Value

A `ggplot` object of class `calor`.

## Examples

``` r
m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
ggcalor(m, cell_size = 6)

ggcalor(m, scale = "row") + calor_dendro(rows = TRUE, cols = TRUE, k = 3)
```
