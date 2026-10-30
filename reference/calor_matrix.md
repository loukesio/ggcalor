# Turn heatmap input into a long data frame

Accepts a numeric matrix, a data frame in wide form (first column or row
names as row labels), or a long data frame with explicit row, column and
value columns.

## Usage

``` r
calor_matrix(data, rows = NULL, cols = NULL, value = NULL)
```

## Arguments

- data:

  A matrix or data frame.

- rows, cols, value:

  For long data, the column names (strings) holding row labels, column
  labels and cell values. Ignored for matrices.

## Value

A list with `matrix` (numeric, with dimnames) and `long` (data frame
with `.row`, `.col`, `.value`).
