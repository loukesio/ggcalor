# Split rows and columns into slices

Slices are separated by a gap and keep square cells. Give a grouping
vector, or an integer to cut the dendrogram (a default one is computed
when none was added).

## Usage

``` r
calor_split(rows = NULL, cols = NULL, gap = 1.5, labels = TRUE)
```

## Arguments

- rows, cols:

  `NULL`, an integer number of clusters, or a vector (or factor) of
  group labels, named by row/column or in matrix order.

- gap:

  Gap between slices in millimetres.

- labels:

  Show slice labels as strips.

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Examples

``` r
m <- matrix(rnorm(200), 20, 10, dimnames = list(paste0("g", 1:20), paste0("s", 1:10)))
ggcalor(m) + calor_dendro(rows = TRUE) + calor_split(rows = 3)

ggcalor(m) + calor_split(cols = rep(c("ctrl", "treat"), each = 5))
```
