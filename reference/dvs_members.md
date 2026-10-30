# Simulated society membership by country and month

One row per country and month in which members joined, with the dominant
trait of those members. The 130 country names are real; the membership
is simulated. Used by the ring recipe in
[`vignette("gallery")`](https://loukesio.github.io/ggcalor/articles/gallery.md).

## Usage

``` r
dvs_members
```

## Format

A data frame with columns `country` (character), `month` (factor,
`month.abb`) and `trait` (`"Data"`, `"Visualization"` or `"Society"`).
