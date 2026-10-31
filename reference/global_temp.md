# Global monthly temperature anomalies

Global mean surface temperature (land and ocean) for every month from
1880 to 2025, as the difference from the 1951–1980 average. Used by the
ring recipe.

## Usage

``` r
global_temp
```

## Format

A numeric matrix with 12 rows (months, `month.abb`) and 146 columns
(years), in degrees Celsius.

## Source

NASA GISS Surface Temperature Analysis (GISTEMP v4), Lenssen et al.
(2019), <https://data.giss.nasa.gov/gistemp/>; see
`data-raw/global_temp.R`.
