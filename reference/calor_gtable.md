# The heatmap as a table with the cells as its panel

Returns a gtable shaped like an ordinary ggplot whose only panel, named
`"panel"`, covers exactly the cells, while trees, tracks, names and
legends sit in the axis space around it. Tools that place or connect
ggplots by their panel, such as ggweave, can then treat a ggcalor plot
like any other plot. Cell coordinates run from 0.5 to the number of
columns (or rows) plus any split gaps, plus 0.5, and are stored in the
`"calor_ranges"` attribute.

## Usage

``` r
calor_gtable(plot)
```

## Arguments

- plot:

  A
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
  plot.

## Value

A gtable.

## See also

[`calor_anchors()`](https://loukesio.github.io/ggcalor/reference/calor_anchors.md)
for the positions of named rows and columns.

## Examples

``` r
m <- matrix(rnorm(20), 4, 5, dimnames = list(letters[1:4], LETTERS[1:5]))
g <- calor_gtable(ggcalor(m) + calor_dendro(rows = TRUE))
attr(g, "calor_ranges")
#> $x
#> [1] 0.5 5.5
#> 
#> $y
#> [1] 0.5 4.5
#> 
```
