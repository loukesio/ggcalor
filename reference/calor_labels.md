# Place and style row and column names

Row names sit next to the cells, or outside the tracks on the chosen
side; column names the same. The style applies to both and is inherited
by the track names, so one call sets the typography of the whole figure.
Anything added later with `theme(axis.text = ...)` still wins.

## Usage

``` r
calor_labels(
  rows = c("auto", "left", "right", "none"),
  cols = c("auto", "top", "bottom", "none"),
  size = NULL,
  colour = NULL,
  face = NULL,
  family = NULL,
  angle = NULL,
  every = NULL
)
```

## Arguments

- rows:

  `"auto"`, `"left"`, `"right"` or `"none"`. Auto keeps names on the
  side without tracks, else outside the right tracks.

- cols:

  `"auto"`, `"top"`, `"bottom"` or `"none"`. Auto puts names on the side
  without tracks, else below.

- size:

  Text size in points.

- colour:

  Text colour.

- face:

  `"plain"`, `"bold"` or `"italic"`.

- family:

  Font family.

- angle:

  Angle of column names in degrees; row names stay horizontal.

- every:

  Show only every n-th name, counted from the first in the final order:
  one number for both axes, or a named vector such as
  `c(rows = 3, cols = 20)`. Useful for long runs of years or months.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
ggcalor(m) + calor_labels(rows = "right", cols = "bottom", angle = 45, face = "italic")

ggcalor(global_temp, cell_size = 2) + calor_labels(every = c(rows = 3, cols = 20))
```
