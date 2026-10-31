
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
  calor_anno(top = sites) +
  calor_margin(right = "mean", fill = "#3B8F5C") +
  scale_fill_distiller(palette = "YlGn", direction = 1) +
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
p <- ggcalor(m, cell_size = 2.6, cell_gap = 0.25, border = NA, labels = "rows") +
  calor_order(rows = "sum", cols = "memo") +
  calor_margin(right = "sum", top = "sum", size = 10) +
  scale_fill_manual(values = alt_colours, breaks = names(alt_colours), na.value = "#F1EEE8") +
  labs(title = "KRAS and BRAF are rarely altered in the same tumour",
       subtitle = "RAS/RAF/MEK/JNK pathway alterations in 106 lung adenocarcinomas",
       caption = "Data: TCGA via cBioPortal", fill = NULL) +
  theme(legend.position = "bottom")
fig(p, "oncoprint")

# Beyond heatmaps: surface, ring, waffle
v <- t(volcano[seq(87, 1, -2), seq(1, 61, 2)])
dimnames(v) <- list(seq_len(nrow(v)), seq_len(ncol(v)))
p <- ggcalor(v, cell_size = 2.4, smooth = "contour", smooth_sigma = 1, labels = "none") +
  scale_fill_viridis_d(option = "mako") +
  labs(title = "Maunga Whau rises 100 m above its plain",
       caption = "Data: datasets::volcano", fill = "height (m)")
fig(p, "volcano")

p <- ggcalor(dvs_members, rows = "month", cols = "country", value = "trait",
             cell_size = 3.6, border = "white", na_fill = "#EFECE6") +
  calor_radial(inner.radius = 0.42, gap = 0.2, label_size = 8) +
  scale_fill_manual(values = c(Data = "#F3A712", Visualization = "#E4572E", Society = "#2E86AB"),
                    breaks = c("Data", "Visualization", "Society"), na.value = "#EFECE6") +
  labs(title = "A year of new members, country by country",
       subtitle = "Months in which each country gained members, by their main interest",
       caption = "Simulated memberships; real country names", fill = NULL) +
  # The country names reach past the ring; keep them clear of the titles.
  theme(plot.subtitle = element_text(margin = margin(b = 30)),
        plot.caption = element_text(margin = margin(t = 30)))
fig(p, "ring")

penguins <- as.data.frame(table(island = palmerpenguins::penguins$island,
                                species = palmerpenguins::penguins$species))
p <- calor_waffle(penguins, "species", "Freq", by = "island", cell_size = 3.2) +
  labs(title = "Gentoo penguins live only on Biscoe",
       subtitle = "Share of each species among the penguins sampled on three islands")
fig(p, "waffle")
