# Figures for README.md. Run from the package root after changing the README
# examples; every plot is saved at its natural size with calor_save().
devtools::load_all(".", quiet = TRUE)
fig <- function(p, name) calor_save(p, file.path("man/figures", paste0("readme-", name, ".png")), dpi = 300)

# Measles: the opening figure
era <- ifelse(as.integer(colnames(measles)) < 1963, "before vaccine", "after vaccine")
p <- ggcalor(measles, cell_size = 2.6, cell_gap = 0.06, border = NA) +
  calor_split(cols = factor(era, c("before vaccine", "after vaccine")), gap = 2) +
  calor_margin(top = "sum", size = 14) +
  scale_fill_fermenter(palette = "YlOrRd", direction = 1, transform = "log10",
                       breaks = 10^(1:5), labels = scales::label_comma(), na.value = "grey95") +
  labs(title = "Measles cases in the United States, 1930–2001",
       subtitle = "The vaccine was licensed in 1963", fill = "cases")
suppressWarnings(fig(p, "measles"))

# Dune meadows: clustering, splits, annotations, margins
data(dune, dune.env, package = "vegan")
sites <- data.frame(management = dune.env$Management, moisture = dune.env$Moisture,
                    row.names = rownames(dune))
levels(sites$management) <- c("biological", "hobby", "nature reserve", "standard")
p <- ggcalor(t(dune), cell_size = 4.2) +
  calor_dendro(rows = TRUE, cols = TRUE, k = 3, highlight = TRUE) +
  calor_split(cols = 3) +
  calor_anno(top = sites) +
  calor_margin(right = "mean") +
  scale_fill_distiller(palette = "Greens", direction = 1) +
  labs(title = "Plant cover in 20 Dutch dune meadows", fill = "cover")
fig(p, "dune")

# Oncoprint
alt_colours <- c(mutation = "#2E7D32", amplification = "#C62828",
                 `deep deletion` = "#1565C0", `mutation + amplification` = "#8E24AA")
n_altered <- rowSums(!is.na(luad_alterations))
m <- luad_alterations[order(n_altered, decreasing = TRUE)[1:10], ]
m <- m[, colSums(!is.na(m)) > 0]
p <- ggcalor(m, cell_size = 2.6, cell_gap = 0.25, border = NA, labels = "rows") +
  calor_order(rows = "sum", cols = "memo") +
  calor_margin(right = "sum", top = "sum", size = 10) +
  scale_fill_manual(values = alt_colours, breaks = names(alt_colours), na.value = "grey93") +
  labs(title = "RAS/RAF/MEK/JNK pathway alterations in lung adenocarcinoma", fill = NULL) +
  theme(legend.position = "bottom")
fig(p, "oncoprint")

# Beyond heatmaps: surface, ring, waffle
v <- t(volcano[seq(87, 1, -2), seq(1, 61, 2)])
dimnames(v) <- list(seq_len(nrow(v)), seq_len(ncol(v)))
p <- ggcalor(v, cell_size = 2.4, smooth = "contour", smooth_sigma = 1, labels = "none") +
  scale_fill_viridis_d(option = "mako") +
  labs(fill = "height (m)")
fig(p, "volcano")

p <- ggcalor(dvs_members, rows = "month", cols = "country", value = "trait",
             cell_size = 2.4, border = "grey85", na_fill = "white") +
  calor_radial(inner.radius = 0.45) +
  scale_fill_manual(values = c(Data = "#f2c200", Visualization = "#e03b3b", Society = "#4a7bd0"),
                    na.translate = FALSE) +
  labs(fill = NULL)
fig(p, "ring")

penguins <- as.data.frame(table(island = palmerpenguins::penguins$island,
                                species = palmerpenguins::penguins$species))
p <- ggwaffle(penguins, "species", "Freq", by = "island", cell_size = 2.6)
fig(p, "waffle")
