#' Measles cases by US state and year
#'
#' Reported measles cases in the 50 US states and the District of Columbia
#' from 1930 to 2001. The vaccine was licensed in 1963. Used for the opening
#' example and the binned-scale recipes.
#'
#' @format An integer matrix with 51 rows (states) and 72 columns (years).
#' @source Project Tycho (van Panhuis et al. 2013, *N Engl J Med* 369:2152),
#'   as shipped with the 'ComplexHeatmap' package. Territories and the New
#'   York City / upstate split are removed; see `data-raw/measles.R`.
"measles"

#' RAS/RAF/MEK/JNK pathway alterations in lung adenocarcinoma
#'
#' Alterations in 22 pathway genes across 172 TCGA lung adenocarcinoma
#' samples, one cell per gene and sample. Used by the oncoprint recipe.
#'
#' @format A character matrix with genes in rows and TCGA sample IDs in
#'   columns. Values are `"mutation"`, `"amplification"`, `"deep deletion"`,
#'   `"mutation + amplification"`, or `NA` for no alteration.
#' @source TCGA lung adenocarcinoma (provisional) via cBioPortal, as shipped
#'   with the 'ComplexHeatmap' package; see `data-raw/luad_alterations.R`.
"luad_alterations"

#' Global monthly temperature anomalies
#'
#' Global mean surface temperature (land and ocean) for every month from 1880
#' to 2025, as the difference from the 1951–1980 average. Used by the ring
#' recipe.
#'
#' @format A numeric matrix with 12 rows (months, `month.abb`) and 146
#'   columns (years), in degrees Celsius.
#' @source NASA GISS Surface Temperature Analysis (GISTEMP v4), Lenssen et
#'   al. (2019), <https://data.giss.nasa.gov/gistemp/>; see
#'   `data-raw/global_temp.R`.
"global_temp"
