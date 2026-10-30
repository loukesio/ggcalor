# Row and column order of a built heatmap

Returns the final order after
[`calor_order()`](https://loukesio.github.io/ggcalor/reference/calor_order.md)
and
[`calor_dendro()`](https://loukesio.github.io/ggcalor/reference/calor_dendro.md)
have been applied, so it can be reused elsewhere, like seaborn's
`reordered_ind`.

## Usage

``` r
calor_order_of(plot)
```

## Arguments

- plot:

  A
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
  plot.

## Value

A list with `rows` and `cols`, character vectors of names.
