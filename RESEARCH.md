# Heatmap landscape research (2026-10-21)

Environment: R 4.5.1, ggplot2 4.0.3 (S7 objects), ComplexHeatmap, patchwork, ggiraph, plotly, dendextend, ggtree, aplot installed.

## 1. The competitors

| Package | Engine | What it does well | Where it hurts |
|---|---|---|---|
| ComplexHeatmap (Bioc) | grid | Annotations, row/col splits, slice clustering, oncoPrint, UpSet, densityHeatmap, legends. The reference feature set. | Not ggplot2. Legends fixed to four sides. Multi-heatmap grids need manual viewports. Steep API, many parameters. |
| ggalign 1.2.0 (CRAN 2025-10-18, needs ggplot2 >= 4.0) | ggplot2 | ggplot2-native ComplexHeatmap. `ggheatmap()`, `anno_top/left/bottom/right()`, `align_dendro()`, `align_kmeans()`, `align_group()`, `ggoncoplot()`, `ggupset()`, circle layouts, auto raster for >20k cells, legends anywhere. Self-reported as beating ComplexHeatmap on every row of its own comparison table. | Really a general layout engine (stack/quad/circle/cross layouts, "active context" switching, schemes, free_* helpers). Heavy concept load. Many renames and deprecations across versions. No interactivity. No documented fixed/square cell size. Its vignette site had a 404 for the heatmap layout article. |
| tidyHeatmap 1.13.x (CRAN 2025-10-30) | ComplexHeatmap | Tidy long-data input, annotations by column name, 3 to 5x less code than ComplexHeatmap. | Inherits every grid limitation. Not composable with ggplot2. |
| ggheatmap 2.2 (CRAN, Baiwei Luo) | ggplot2 + aplot + patchwork | Simple clustering, scaling, annotations. | Name collision with our idea. `ggheatmap()` also exists in heatmaply and ggalign. One-function API, little extensibility. |
| heatmaply 1.6.0 (2025-07) | ggplot2 -> plotly | Hover values, drag-zoom, dendrogram zoom. The default "interactive heatmap" answer. | plotly heavy, not a ggplot object you can extend, dated look. |
| iheatmapr 0.7.x | plotly | Modular subplots added top/left/right/bottom, linked zoom. | Not ggplot2 at all. Slow development. |
| superheat | ggplot2 (2016) | Marginal plots, text overlay. | Abandoned, pre-ggplot2 3.0 era. |
| seaborn clustermap (Python) | matplotlib | The API people copy: `z_score=0/1`, `standard_scale`, `mask`, `row_colors/col_colors` (DataFrame, multi-level), `row_linkage/col_linkage` precomputed, `dendrogram_ratio`, `pivot_kws` for long data, `reordered_ind` exposed after. | Square cells need `figsize` fiddling, same as everywhere. |
| marsilea (Python) | matplotlib | Declarative, composable, grid-based. ggalign's named rival. | Python. |

## 2. What ggplot2 4.0 gives us that nobody has exploited yet

- `theme(panel.widths, panel.heights)`: absolute panel size. Verified: `unit(ncol*6, "mm")` x `unit(nrow*6, "mm")` yields exact 6 mm square cells, and they survive `patchwork` composition. This is THE square-heatmap primitive. ggalign only fixed a bug around it; nobody exposes `cell_size = 6`.
- S7 class system. `class(p)` is `ggplot2::ggplot`. Extensions should build with ggproto geoms/stats and S7 for the top-level object.
- `theme(geom = element_geom())` and `from_theme()`: theme-driven layer defaults, so a heatmap theme can set tile border colour, na colour, text size in one place.
- `palette.fill.continuous` / `palette.fill.discrete` theme slots: heatmap colour palette becomes a theme property, not a scale call.
- `layer(layout = ...)`: new hook for interacting with facets, worth exploring for split panels.
- `geom_raster()` auto-falls back to `geom_rect()` in non-linear coords, so circular heatmaps come nearly free with `coord_radial()`.
- `facet_grid(space = "free")` now works with `coord_fixed()`: splits with unequal group sizes keep square cells.
- `make_constructor()`, `@aesthetics` roxygen tag, `get_layer_data()`: cleaner extension authoring.
- `ggsave()` multi-page PDFs from a list of plots.

## 3. Where a new package can actually win

ggalign has already won "ComplexHeatmap in ggplot2". Competing on feature count against a layout engine is a losing move. The open space is:

1. **Cell-first geometry.** `cell_size = unit(5, "mm")` as a first-class argument; the plot sizes itself, not the device. Square by default. Nobody does this. Also `cell_shape` (square, circle, pie, text-in-cell, split tile) as geoms on the same cell grid.
2. **Grammar, not layout engine.** One `ggplot()`-shaped object. `ggheat(mat) + hm_cluster(rows = "complete") + hm_split(cols = group) + hm_anno(top = df) + hm_dendro()`. Every verb returns something that still answers to `+ theme()`, `+ scale_fill_*()`, `+ labs()`. ggalign's quad/stack/active-context model is where users get lost.
3. **seaborn-level ergonomics in R.** `scale = "row"` / `"col"` with z-score or min-max, `mask`, precomputed linkage, `pivot` from long tidy data, reordered indices returned as an attribute. These are the ten things 90% of users need and the thing they type first.
4. **Interactivity as a flag, not a rewrite.** Build every geom with a `*_interactive` twin so `ggheat(mat, interactive = TRUE)` or `girafe(hm)` gives tooltips (row, col, value, annotation values) and linked brushing across dendrogram and annotations. ggiraph is already installed, is pure SVG, works in Shiny and Quarto. heatmaply and iheatmapr are the only interactive options today and both are plotly.
5. **Legends and labels done right.** Legend for the main matrix plus each annotation, merged, placed anywhere, with sensible titles. ggalign claims this, ComplexHeatmap does not.
6. **Big matrices.** Auto raster above a cell threshold (ggalign does 20k). Add `ggrastr` opt-in for annotations too.
7. **Export sanity.** `hm_save(p, "fig.pdf")` computes the device size from the cell size, margins, and legends so that what you asked for is what you get. This is the thing nobody solves and the reason people fight with ggsave width/height.

Not worth chasing early: oncoPrint, UpSet, circular layouts, genomic tracks. ggalign and ComplexHeatmap own those. Make the core so composable that those become recipes later.

## 4. Naming

`ggheatmap` is taken on CRAN (v2.2) and as a function name in heatmaply and ggalign. Pick a new name before writing code. Candidates: `ggheat`, `heatgrammar`, `tilegrid`, `ggcells`, `squareheat`. The package folder can stay as is for now.

## 5. Proposed phase plan

1. Core (weeks 1-3): matrix and long-data input, `cell_size`, z-score/min-max scaling, NA/mask, clustering with hclust and precomputed linkage, row/col ordering, dendrograms via ggdendro-style segments, one annotation type (categorical bar), legends, `hm_save()`.
2. Composition (weeks 4-6): splits (facets), multiple annotations stacked, numeric annotations (bar, line, points, boxplot), text in cells, split tiles, theme_heatmap().
3. Interactivity (weeks 7-8): ggiraph twins, tooltips, linked highlighting, Shiny example.
4. Later: circular via coord_radial, oncoprint recipe, benchmarks against ggalign and ComplexHeatmap, JOSS paper.

## Sources

- ggalign site https://yunuuuu.github.io/ggalign/ and CRAN news https://cran.r-project.org/web/packages/ggalign/news/news.html
- ggalign Biostars announcement https://www.biostars.org/p/9599310/
- CRAN ggheatmap https://rdrr.io/cran/ggheatmap and heatmaply::ggheatmap https://search.r-project.org/CRAN/refmans/heatmaply/html/ggheatmap.html
- ggplot2 changelog https://ggplot2.tidyverse.org/news/index.html
- tidyHeatmap https://stemangiola.r-universe.dev/tidyHeatmap
- seaborn clustermap https://seaborn.pydata.org/generated/seaborn.clustermap
- heatmaply https://www.stats.bris.ac.uk/R/web/packages/heatmaply/index.html
- iheatmapr https://docs.ropensci.org/iheatmapr/
- ComplexHeatmap manual https://bioc.r-universe.dev/ComplexHeatmap/doc/manual.html
- ComplexHeatmap multi-grid limitation https://support.bioconductor.org/p/87318/
- eheat (bridge ggplot2 <-> ComplexHeatmap by the ggalign author) https://github.com/Yunuuuu/eheat/

## 6. Gallery targets (from the eight inspiration images in `inspiration/`)

Each image is a chart the package should produce with one or two added verbs, not a custom script.

| # | Image | What it is | Grammar features it demands |
|---|---|---|---|
| 1 | hex cells | Hexagonal cell grid, spectral palette | `cell_shape = "hex"`; cells are a layout choice, not a different package |
| 2 | fatal crashes, month x hour | Calendar heatmap, white gaps, 6-step binned legend, x labels on top, filter buttons | `cell_gap`, `scale_fill_binned()` as default for percentages, axis labels on top, horizontal stepped legend below, Shiny/ggiraph filter hooks |
| 3 | wildlife strikes | Heatmap with marginal bar sums right and below, hover filters above | marginal summaries `hm_margin(rows = "sum", cols = "sum")` drawn as bars aligned to cells; linked hover highlighting (ggiraph `data_id`) |
| 4 | scientific A to D | Row and column dendrograms, clusters shaded on the dendrogram, column groups split with gaps, bottom glyph annotation with brackets, histogram legend with colourbar, dot plot aligned to rows, panel tags | `hm_dendro(rows, cols, k = 3, highlight = TRUE)`, `hm_split(cols = group, gap = 2mm)`, `hm_anno(bottom = glyphs)`, `guide_hist()` legend, `hm_margin(right = dotplot)`, patchwork tags |
| 5 | Data Visualization Society | Radial heatmap, categorical fill, labels around the rim, legend in the hole | `coord_radial(donut = 0.3)` on the same cell grid, categorical fill, rim labels |
| 6 | McKinsey waffle | Unit chart, 1 square = 0.1 percent, stacked categorical columns | `layout = "waffle"`: same square cells, cells ordered by count within column; it is a heatmap of counts |
| 7 | whatever the weather | Icons inside cells, rounded corners, sparse grid with blank cells, coloured header labels, area chart on top | `hm_glyph(icon)` or `geom_cell_text()`, `cell_radius`, NA cells drawn blank, `hm_anno(top = area_chart)`, coloured axis text from data |
| 8 | smooth contour texture | Interpolated or density heatmap | `smooth = TRUE` via `geom_raster(interpolate)` or `geom_contour_filled()`; decorative, lowest priority |

What the eight images share: every one is a grid of cells where the cell is the design unit. Shape, gap, radius, glyph, and layout (grid, hex, waffle, radial) vary; the data model does not. That is the thesis of the package: **one cell grid, many looks**.

### Ordering and dendrograms (the "sorting look")

The user wants ordering to be effortless. Proposed verbs, all returning the same object:

- `hm_order(rows = "mean")`, `"sum"`, `"max"`, `"var"`, a column name, a vector, or a function. Descending by default. `cols` the same.
- `hm_order(rows = "cluster")` runs hclust and uses the leaf order without drawing a tree.
- `hm_dendro(rows = TRUE, cols = TRUE, method = "complete", dist = "euclidean", k = NULL, highlight = FALSE, size = unit(15, "mm"))` draws the tree and reorders. Precomputed `hclust`, `dendrogram`, `phylo` objects accepted. `k` cuts and colours branches; `highlight = TRUE` shades the clusters as in image 4.
- `hm_split(rows = k)` or a factor: facets with gaps, square cells kept via `facet_grid(space = "free")` plus `coord_fixed()`.
- Reordered indices always exposed: `hm_order_of(p)` returns row and column orders so users can reuse them (seaborn's `reordered_ind`).

### Cell styling vocabulary

`cell_size`, `cell_shape` (square, circle, hex, pie, triangle-split), `cell_gap`, `cell_radius`, `cell_border`, `cell_text`, `cell_glyph`. All theme-able through `theme(geom = element_geom())` so a `theme_heat_*()` can set a look in one line.
