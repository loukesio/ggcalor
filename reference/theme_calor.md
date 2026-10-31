# A minimal theme for cell grids

No grid, no axis lines, tick-less labels, legend on the right. Titles
are bold and aligned with the left edge of the whole plot, the subtitle
is quieter, and the caption (for a data source) is set in a monospaced
font.

## Usage

``` r
theme_calor(base_size = 10, base_family = calor_family())
```

## Arguments

- base_size:

  Base font size.

- base_family:

  Base font family.

## Value

A theme object.

## Details

The font family defaults to `getOption("ggcalor.family")`, so
`options(ggcalor.family = "Fira Sans")` sets it for every plot,
including the trees, tracks and legends; `options(ggcalor.mono = )` sets
the caption font.
