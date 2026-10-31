# Lay the grid out as a ring

Wraps
[`ggplot2::coord_radial()`](https://ggplot2.tidyverse.org/reference/coord_radial.html)
with the settings a ring heatmap needs: column labels radiate outward
and stay readable, row labels sit in a small gap of the ring, the legend
sits below as a slim bar, and the grid is hidden. Anything added
afterwards with
[`theme()`](https://ggplot2.tidyverse.org/reference/theme.html) or
[`guides()`](https://ggplot2.tidyverse.org/reference/guides.html) still
wins.

## Usage

``` r
calor_radial(
  inner.radius = 0.4,
  gap = 0.12,
  label_size = 6,
  legend = c("bottom", "right", "inside"),
  ...
)
```

## Arguments

- inner.radius:

  Hole size as a fraction of the outer radius.

- gap:

  Sector left open, in radians, where the row labels are placed.

- label_size:

  Column label size in points.

- legend:

  Where the legend goes: `"bottom"` (a slim horizontal bar below the
  ring), `"right"`, or `"inside"` (in the hole).

- ...:

  Passed to
  [`ggplot2::coord_radial()`](https://ggplot2.tidyverse.org/reference/coord_radial.html).

## Value

An object to add to a
[`ggcalor()`](https://loukesio.github.io/ggcalor/reference/ggcalor.md)
plot with `+`.

## Details

Dendrograms and annotation tracks are not drawn in a ring.

## Examples

``` r
ring <- matrix(sample(c("a", "b", NA), 12 * 40, TRUE), 12, 40,
               dimnames = list(month.abb, paste0("country ", 1:40)))
ggcalor(ring, cell_size = 3, na_fill = "#EFECE6") + calor_radial()

ggcalor(global_temp[, 1:60], cell_size = 3) + calor_radial(legend = "right")
```
