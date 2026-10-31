# Global monthly temperature anomalies from NASA GISTEMP v4 (land and ocean),
# relative to the 1951-1980 mean. Complete years only.
url <- "https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv"
raw <- read.csv(url, skip = 1, na.strings = "***")
raw <- raw[raw$Year <= 2025, ]
global_temp <- t(as.matrix(raw[, month.abb]))
dimnames(global_temp) <- list(month.abb, raw$Year)
stopifnot(!anyNA(global_temp))
usethis::use_data(global_temp, overwrite = TRUE)
