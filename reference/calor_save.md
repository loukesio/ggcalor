# Save a heatmap at its natural size

Computes the device size from the cell size, trees, labels and legend,
so the file holds exactly the plot you built. Extra arguments go to
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Usage

``` r
calor_save(plot, filename, pad = 2, ...)
```

## Arguments

- plot:

  A
  [`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
  plot.

- filename:

  Output path; the extension picks the device.

- pad:

  Extra space around the plot, in millimetres.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html),
  e.g. `dpi`.

## Value

The filename, invisibly.
