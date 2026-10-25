# Alterations in RAS/RAF/MEK/JNK pathway genes across TCGA lung adenocarcinoma
# samples (cBioPortal, provisional study), as shipped with 'ComplexHeatmap'.
f <- system.file("extdata", "tcga_lung_adenocarcinoma_provisional_ras_raf_mek_jnk_signalling.txt",
                 package = "ComplexHeatmap")
x <- read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE, check.names = FALSE)
m <- t(as.matrix(x[, -1]))
colnames(m) <- x[[1]]
m[] <- trimws(m)
codes <- c("MUT;" = "mutation", "AMP;" = "amplification", "HOMDEL;" = "deep deletion",
           "MUT;AMP;" = "mutation + amplification")
m[] <- unname(codes[m])
# Keep genes altered in at least one sample.
luad_alterations <- m[rowSums(!is.na(m)) > 0, ]
usethis::use_data(luad_alterations, overwrite = TRUE)
