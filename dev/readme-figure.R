devtools::load_all(".", quiet = TRUE)
set.seed(42)
m <- matrix(rnorm(30 * 12), 30, 12, dimnames = list(paste0("gene_", 1:30), paste0("sample", 1:12)))
m[1:10, 1:6] <- m[1:10, 1:6] + 2.5
m[11:20, 7:12] <- m[11:20, 7:12] - 2
m[21:30, 4:9] <- m[21:30, 4:9] + 1.5
samples <- data.frame(condition = rep(c("control", "treated"), each = 6),
                      batch = rep(c("b1", "b2", "b3"), 4), row.names = colnames(m))
genes <- data.frame(type = sample(c("TF", "kinase", "other"), 30, TRUE), row.names = rownames(m))

p <- ggcalor(m, cell_size = 4.5, scale = "row") +
  calor_dendro(rows = TRUE, cols = TRUE, k = 3, highlight = TRUE) +
  calor_split(rows = 3, gap = 2) +
  calor_anno(top = samples, left = genes,
             colours = list(condition = c(control = "grey70", treated = "firebrick"))) +
  calor_margin(right = "mean", bottom = "boxplot") +
  labs(title = "Expression, z-scored by gene", subtitle = "rows cut into three clusters")
calor_save(p, "man/figures/readme-dendro.png", dpi = 300)

p2 <- ggcalor(m[1:12, ], cell_size = 7, cell_gap = 0.1) +
  calor_split(cols = samples$condition) +
  calor_dendro(rows = TRUE, cols = TRUE) +
  calor_text(digits = 1, size = 5)
calor_save(p2, "man/figures/readme-split.png", dpi = 300)

# Histogram legend, glyph track, brackets
set.seed(11)
m3 <- matrix(rnorm(24 * 10), 24, 10, dimnames = list(paste0("g", 1:24), paste0("s", 1:10)))
m3[1:8, 1:5] <- m3[1:8, 1:5] + 2; m3[9:16, 6:10] <- m3[9:16, 6:10] - 2
scenario <- rep(c("present", "future"), 5)
source_grp <- rep(c("LNG", "Norway", "Poland", "Algeria", "Baseline"), each = 2)
p3 <- ggcalor(m3, cell_size = 5, scale = "row") +
  calor_dendro(rows = TRUE, cols = TRUE, k = 2, highlight = TRUE) +
  calor_split(rows = 2) +
  calor_anno(bottom = list(scenario = scenario), type = "glyph") +
  calor_bracket(cols = source_grp, side = "bottom", angle = 90, size = 10) +
  calor_legend("histogram") +
  calor_margin(right = "sd")
calor_save(p3, "man/figures/readme-legend.png", dpi = 300)

# Waffle
pop <- data.frame(decile = rep(c("<100", "3K", "12K", "43K"), each = 4),
                  region = rep(c("Africa", "China", "India", "Europe"), 4),
                  share = c(60, 10, 25, 5, 30, 30, 30, 10, 10, 40, 20, 30, 5, 10, 5, 80))
p4 <- ggwaffle(pop, "region", "share", by = "decile", n = 100, rows = 20, cell_size = 2.5)
ggsave("man/figures/readme-waffle.png", p4, width = 6, height = 3, dpi = 300, bg = "white")

# Radial ring
p5 <- ggcalor(dvs_members, rows = "month", cols = "country", value = "trait",
              cell_size = 2.4, border = "grey85", na_fill = "white") +
  calor_radial(inner.radius = 0.45) +
  scale_fill_manual(values = c(Data = "#f2c200", Visualization = "#e03b3b", Society = "#4a7bd0"),
                    na.translate = FALSE) +
  labs(fill = NULL)
calor_save(p5, "man/figures/readme-radial.png", dpi = 300)

# Oncoprint
set.seed(3)
genes <- c("TP53", "KRAS", "EGFR", "PIK3CA", "BRAF", "PTEN", "ALK", "MET")
mut <- matrix(NA_character_, 8, 40, dimnames = list(genes, sprintf("S%02d", 1:40)))
types <- c("missense", "nonsense", "amplification", "deletion")
freq <- c(.6, .45, .3, .3, .2, .2, .1, .1)
for (g in seq_along(genes)) {
  idx <- sample(40, rbinom(1, 40, freq[g]))
  mut[g, idx] <- sample(types, length(idx), TRUE, prob = c(.5, .2, .15, .15))
}
p6 <- ggcalor(mut, cell_size = c(3, 6), cell_gap = 0.15, border = NA, na_fill = "grey93",
        labels = "rows") +
  calor_order(rows = "sum", cols = "memo") +
  calor_margin(right = "sum", top = "sum", size = 8) +
  labs(fill = "alteration")
calor_save(p6, "man/figures/readme-oncoprint.png", dpi = 300)

# Smooth surface
set.seed(8)
f <- outer(1:30, 1:45, function(i, j) sin(i / 4) * cos(j / 6) + 0.6 * sin((i + j) / 5))
f <- f + matrix(rnorm(length(f), sd = 0.25), nrow(f))
dimnames(f) <- list(paste0("r", 1:30), paste0("c", 1:45))
p7 <- ggcalor(f, cell_size = 3, smooth = "contour", smooth_sigma = 1.5, smooth_bins = 8, labels = "none") +
  scale_fill_manual(values = c("#1b4d8f", "#2a9df4", "#3cb44b", "#bfef45", "#ffe119", "#f58231", "#e6194b", "#c71585")) +
  theme(legend.position = "none")
calor_save(p7, "man/figures/readme-surface.png", dpi = 300)
