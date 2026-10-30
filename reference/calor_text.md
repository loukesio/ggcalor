# Write values in cells

Write values in cells

## Usage

``` r
calor_text(digits = 1, size = 7, colour = "grey15", format = NULL, ...)
```

## Arguments

- digits:

  Decimal places.

- size:

  Text size in points.

- colour:

  Text colour.

- format:

  Optional function from values to labels; overrides `digits`.

- ...:

  Passed to
  [`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html).

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
ggcalor(m, cell_size = 10) + calor_text(digits = 1)
```
