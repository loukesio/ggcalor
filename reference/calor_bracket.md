# Group brackets

Draws a bracket over each run of equal labels along rows or columns,
with the label beside it. Runs are found in the final order, so combine
with
[`calor_split()`](https://loukesio.github.io/ggcalor/reference/calor_split.md)
or a sorted axis for clean groups.

## Usage

``` r
calor_bracket(
  cols = NULL,
  rows = NULL,
  side = NULL,
  size = 6,
  colour = "grey20",
  text_size = 7,
  angle = 0
)
```

## Arguments

- cols, rows:

  A vector of group labels, named or in matrix order.

- side:

  `"top"` or `"bottom"` for columns, `"left"` or `"right"` for rows.

- size:

  Track thickness in millimetres.

- colour:

  Line colour.

- text_size:

  Label size in points.

- angle:

  Label angle in degrees; for column brackets, rotate when groups are
  narrow (then also raise `size`).

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(100), 10, 10, dimnames = list(paste0("g", 1:10), paste0("s", 1:10)))
ggcalor(m) + calor_bracket(cols = rep(c("ctrl", "treated"), each = 5), side = "bottom")
```
