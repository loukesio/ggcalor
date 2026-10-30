# Cluster and draw dendrograms

Reorders rows and/or columns by hierarchical clustering and draws the
trees beside the heatmap, aligned leaf to cell. Precomputed `hclust` or
`dendrogram` objects are accepted.

## Usage

``` r
calor_dendro(
  rows = TRUE,
  cols = FALSE,
  method = "complete",
  dist = "euclidean",
  k = NULL,
  highlight = FALSE,
  size = 12,
  colour = "grey30",
  linewidth = 0.4,
  show_tree = TRUE
)
```

## Arguments

- rows, cols:

  `TRUE` to cluster that axis, `FALSE` to leave it, or an `hclust` /
  `dendrogram` object to use as is.

- method:

  Linkage method passed to
  [`stats::hclust()`](https://rdrr.io/r/stats/hclust.html).

- dist:

  Distance measure passed to
  [`stats::dist()`](https://rdrr.io/r/stats/dist.html), or a function
  taking the matrix and returning a `dist`.

- k:

  Cut the tree into `k` clusters and colour the branches.

- highlight:

  Shade the `k` clusters behind the tree, as in many publication
  figures.

- size:

  Height of a column tree or width of a row tree, in millimetres.

- colour:

  Line colour when `k` is `NULL`.

- linewidth:

  Line width of the branches.

- show_tree:

  Set to `FALSE` to reorder without drawing. Equivalent to
  `calor_order("cluster")` but with your own linkage and distance.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
ggcalor(m) + calor_dendro(rows = TRUE, cols = TRUE)

ggcalor(m) + calor_dendro(rows = TRUE, k = 3, highlight = TRUE)
```
