# Measles cases by US state and year

Reported measles cases in the 50 US states and the District of Columbia
from 1930 to 2001. The vaccine was licensed in 1963. Used for the
opening example and the binned-scale recipes.

## Usage

``` r
measles
```

## Format

An integer matrix with 51 rows (states) and 72 columns (years).

## Source

Project Tycho (van Panhuis et al. 2013, *N Engl J Med* 369:2152), as
shipped with the 'ComplexHeatmap' package. Territories and the New York
City / upstate split are removed; see `data-raw/measles.R`.
