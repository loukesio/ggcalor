# Order rows and columns

Sort the heatmap without drawing a tree. Ordering is resolved when the
plot is built, so it composes with
[`calor_dendro()`](https://loukesio.github.io/ggcalor/reference/calor_dendro.md):
a dendrogram wins for the axis it clusters.

## Usage

``` r
calor_order(rows = NULL, cols = NULL, decreasing = TRUE)
```

## Arguments

- rows, cols:

  How to order. One of:

  - a statistic name: `"mean"`, `"sum"`, `"max"`, `"min"`, `"var"`,
    `"sd"`, `"median"`;

  - `"cluster"`: hierarchical-clustering leaf order, no tree drawn;

  - `"memo"`: the oncoprint sort. Items are ordered so that those with a
    value in the first row/column come first, then the second, and so
    on. Combine with `"sum"` on the other axis for a classic oncoprint;

  - a name: order rows by the values in that column, or columns by the
    values in that row;

  - a character vector of names or an integer vector: an explicit order;

  - a function taking the matrix and returning an order. `NULL` leaves
    the axis as is.

- decreasing:

  Sort statistics from largest to smallest.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(80), 10, 8, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
ggcalor(m) + calor_order(rows = "mean", cols = "cluster")

ggcalor(m) + calor_order(rows = "s1")
```
