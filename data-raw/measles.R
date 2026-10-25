# Measles cases by US state and year, 1930-2001, from Project Tycho as shipped
# with 'ComplexHeatmap'. Territories and the New York City / upstate split
# (which overlap New York) are dropped.
m <- readRDS(system.file("extdata", "measles.rds", package = "ComplexHeatmap"))
drop <- c("AMERICAN.SAMOA", "GUAM", "NORTHERN.MARIANA.ISLANDS", "PAC.TRUST.TERR",
          "PUERTO.RICO", "VIRGIN.ISLANDS", "NEW.YORK.CITY", "UPSTATE.NEW.YORK")
m <- m[!rownames(m) %in% drop, ]
rownames(m) <- tools::toTitleCase(tolower(gsub(".", " ", rownames(m), fixed = TRUE)))
storage.mode(m) <- "integer"
measles <- m
usethis::use_data(measles, overwrite = TRUE)
