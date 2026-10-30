# Marginal summaries

Summarise each row or column of the displayed matrix and draw it as a
track: a bar of a statistic or a boxplot of the distribution.

## Usage

``` r
calor_margin(
  top = NULL,
  bottom = NULL,
  left = NULL,
  right = NULL,
  size = 10,
  fill = "grey45",
  data = c("raw", "display")
)
```

## Arguments

- top, bottom, left, right:

  A statistic name (`"mean"`, `"sum"`, `"median"`, `"max"`, `"min"`,
  `"sd"`, `"var"`), `"boxplot"`, or a function of a vector.

- size:

  Track thickness in millimetres.

- fill:

  Fill colour of bars and boxes.

- data:

  Summarise the `"raw"` input values (default) or the `"display"` values
  after scaling and masking.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rpois(200, 5), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
ggcalor(m) + calor_margin(right = "sum", bottom = "boxplot")
```
