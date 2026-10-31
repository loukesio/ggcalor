# Render an interactive heatmap

Wraps
[`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html)
with the plot's natural size and hover styling that dims everything
except the hovered cells.

## Usage

``` r
calor_girafe(plot, ..., hover_css = NULL, dim_css = NULL)
```

## Arguments

- plot:

  A
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
  plot with
  [`calor_interactive()`](https://loukesio.github.io/ggcalor/reference/calor_interactive.md).

- ...:

  Passed to
  [`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html).

- hover_css:

  CSS for hovered cells; `NULL` picks a default.

- dim_css:

  CSS for the other cells while hovering; `NULL` fades them, or veils
  them in white for waffles, hex and circle cells and smooth surfaces.

## Value

A 'girafe' htmlwidget.
