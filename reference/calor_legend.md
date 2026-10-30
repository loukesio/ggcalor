# Histogram legend

Replace the colour bar with a histogram of the values, coloured by the
fill scale and with the colour strip underneath. It joins the other
legends.

## Usage

``` r
calor_legend(
  type = c("histogram", "colourbar"),
  width = 32,
  height = 18,
  bins = 30
)
```

## Arguments

- type:

  `"histogram"` or `"colourbar"` (the default legend).

- width, height:

  Legend size in millimetres.

- bins:

  Number of histogram bins.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
ggcalor(m) + calor_legend("histogram")
```
