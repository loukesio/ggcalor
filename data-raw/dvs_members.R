# Simulated membership data for the ring recipe, with real country names.
set.seed(2)
cn <- countrycode::codelist$country.name.en
cn <- cn[!is.na(cn) & nchar(cn) <= 14]
countries <- sort(sample(cn, 130))
dvs_members <- do.call(rbind, lapply(countries, function(ct) {
  k <- rbinom(1, 12, 0.35)
  if (k == 0) return(NULL)
  data.frame(country = ct, month = month.abb[sort(sample(12, k))],
             trait = sample(c("Data", "Visualization", "Society"), k, TRUE, prob = c(.5, .3, .2)))
}))
dvs_members$month <- factor(dvs_members$month, levels = month.abb)
rownames(dvs_members) <- NULL
usethis::use_data(dvs_members, overwrite = TRUE)
