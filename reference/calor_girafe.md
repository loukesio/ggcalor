# Render an interactive heatmap

Wraps
[`ggiraph::girafe()`](https://davidgohel.github.io/ggiraph/reference/girafe.html)
with the plot's natural size and hover styling that dims everything
except the hovered cells.

## Usage

``` r
calor_girafe(
  plot,
  ...,
  hover_css = "stroke:black;stroke-width:1.2px;",
  dim_css = "opacity:0.35;"
)
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

  CSS for hovered cells.

- dim_css:

  CSS for the other cells while hovering.

## Value

A 'girafe' htmlwidget.
