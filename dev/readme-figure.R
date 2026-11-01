
# Figures for README.md. Run from the package root after changing the README
# examples; every plot is saved at its natural size with calor_save().
# The look follows Cédric Scherer: a title that states the finding, a quieter
# subtitle, the data source in a monospaced caption, and one palette for all.
devtools::load_all(".", quiet = TRUE)
options(ggcalor.family = "Fira Sans", ggcalor.mono = "Roboto Mono")
fig <- function(p, name) calor_save(p, file.path("man/figures", paste0("readme-", name, ".png")), dpi = 300)

# Measles: the opening figure
era <- ifelse(as.integer(colnames(measles)) < 1963, "before vaccine", "after vaccine")
p <- ggcalor(measles, cell_size = 2.6, cell_gap = 0.06, border = NA) +
  calor_split(cols = factor(era, c("before vaccine", "after vaccine")), gap = 2) +
  calor_margin(top = "sum", size = 14, fill = "#B3202A") +
  scale_fill_fermenter(palette = "YlOrRd", direction = 1, transform = "log10",
                       breaks = 10^(1:5), labels = scales::label_comma(),
                       na.value = "#F4F1EB") +
  labs(title = "Measles all but vanished after the 1963 vaccine",
       subtitle = "Reported measles cases per US state and year, 1930–2001",
       caption = "Data: Project Tycho", fill = "cases")
suppressWarnings(fig(p, "measles"))

# Dune meadows: clustering, splits, annotations, margins
data(dune, dune.env, package = "vegan")
sites <- data.frame(management = dune.env$Management, moisture = dune.env$Moisture,
                    row.names = rownames(dune))
levels(sites$management) <- c("biological", "hobby", "nature reserve", "standard")
p <- ggcalor(t(dune), cell_size = 4.2) +
  calor_dendro(rows = TRUE, cols = TRUE) +
  calor_split(cols = 3) +
  calor_anno(top = sites, colours = list(
    # Quiet, earthy tones keep the eye on the cells.
    management = c("#C9C1B1", "#919F89", "#57717C", "#EDBDAE"),
    moisture = c("#E4EEF0", "#BDD3CE", "#5F97A4", "#2C3B4D")
  )) +
  calor_margin(right = "mean", fill = "#708C69") +
  # Cream to sage to deep teal, after the "seafarer" palette in ltc.
  scale_fill_gradientn(colours = c("#FCF3E3", "#BDD3CE", "#708C69", "#013D5A")) +
  labs(title = "Wet meadows grow their own plant community",
       subtitle = "Cover of 30 plant species in 20 Dutch dune meadows",
       caption = "Data: vegan::dune", fill = "cover")
fig(p, "dune")

# Oncoprint
alt_colours <- c(mutation = "#3B8F5C", amplification = "#E4572E",
                 `deep deletion` = "#2E86AB", `mutation + amplification` = "#8E5BA8")
n_altered <- rowSums(!is.na(luad_alterations))
m <- luad_alterations[order(n_altered, decreasing = TRUE)[1:10], ]
m <- m[, colSums(!is.na(m)) > 0]
p <- ggcalor(m, cell_size = 2.2, cell_gap = 0.2, border = NA, labels = "rows") +
  calor_order(rows = "sum", cols = "memo") +
  calor_margin(right = "sum", top = "sum", size = 12) +
  scale_fill_manual(values = alt_colours, breaks = names(alt_colours), na.value = "#F1EEE8") +
  labs(title = "KRAS and BRAF are rarely altered in the same tumour",
       subtitle = "RAS/RAF/MEK/JNK pathway alterations in 106 lung adenocarcinomas",
       caption = "Data: TCGA via cBioPortal", fill = NULL) +
  theme(legend.position = "bottom", axis.text.y = element_text(size = 6.5))
fig(p, "oncoprint")

# Beyond heatmaps: surface, flat and round temperatures, waffle
v <- t(volcano[seq(87, 1, -2), seq(1, 61, 2)])
dimnames(v) <- list(seq_len(nrow(v)), seq_len(ncol(v)))
p <- ggcalor(v, cell_size = 2.4, smooth = "contour", smooth_sigma = 1, labels = "none") +
  scale_fill_viridis_d(option = "mako") +
  labs(title = "Maunga Whau rises 100 m above its plain",
       caption = "Data: datasets::volcano", fill = "height (m)")
fig(p, "volcano")

anomaly <- scale_fill_distiller(palette = "RdBu", limits = c(-1.5, 1.5), breaks = c(-1, 0, 1),
                                labels = c("−1 °C", "0", "+1 °C"))
p <- ggcalor(global_temp, cell_size = 2.2, border = NA) +
  calor_labels(every = c(rows = 3, cols = 20)) +
  anomaly +
  labs(title = "Every month of the last decade was warmer than any before 1980",
       subtitle = "Global temperature anomaly by month, against the 1951–1980 average",
       caption = "Data: NASA GISTEMP v4", fill = NULL)
fig(p, "temp-flat")

p <- ggcalor(global_temp, cell_size = 3.4, border = NA) +
  calor_radial(inner.radius = 0.5, gap = 0.35, label_size = 9) +
  calor_labels(every = c(rows = 3, cols = 20)) +
  anomaly +
  labs(title = "A planet running a fever",
       subtitle = "Global temperature anomaly by month, 1880–2025",
       caption = "Data: NASA GISTEMP v4", fill = "against the 1951–1980 average")
fig(p, "ring")

penguins <- as.data.frame(table(island = palmerpenguins::penguins$island,
                                species = palmerpenguins::penguins$species))
p <- calor_waffle(penguins, "species", "Freq", by = "island", cell_size = 3.2) +
  labs(title = "Gentoo penguins live only on Biscoe",
       subtitle = "Share of each species among the penguins sampled on three islands")
fig(p, "waffle")
