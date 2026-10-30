# Scale a matrix by row or column

Scale a matrix by row or column

## Usage

``` r
calor_scale(
  m,
  scale = c("none", "row", "column"),
  method = c("zscore", "minmax")
)
```

## Arguments

- m:

  Numeric matrix.

- scale:

  One of `"none"`, `"row"`, `"column"`.

- method:

  `"zscore"` (mean 0, sd 1) or `"minmax"` (0 to 1), as in seaborn's
  `z_score` and `standard_scale`.

## Value

The scaled matrix.
