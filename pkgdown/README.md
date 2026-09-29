# rtemis theme for pkgdown

Matching light and dark API reference sites for the rtemis Quarto books:
Geist and Geist Mono, neutral page and code surfaces, teal accents, a compact
dark navbar, and the same syntax palette with upright comments.

The adapter reads the shared Quarto SCSS defaults and both `.theme` palettes
on every build. Change colors, typography, and syntax in `quarto/`; keep only
pkgdown-specific layout rules in `rtemis.scss`. No generated palette or installed
template package is needed. Quarto-specific cards and book layouts remain in
the Quarto theme.

## Use

Requires pkgdown 2.2.1 or later with Bootstrap 5, plus its `sass`, `jsonlite`, and `xml2`
dependencies. Configure the checkout with `RTEMIS_THEME_DIR`, then build:

```r
theme_dir <- Sys.getenv("RTEMIS_THEME_DIR")
source(file.path(theme_dir, "pkgdown", "rtemis.R"))
config <- pkgdown::as_pkgdown(".")$meta
override <- rtemis_pkgdown(theme_dir, config)
pkgdown::build_site(
  ".",
  override = override,
  preview = FALSE
)
rtemis_pkgdown_examples(pkgdown::as_pkgdown(".", override = override)$dst_path)
```

The adapter preserves navigation, analytics, and other package metadata. It
sets Bootstrap 5 and enables pkgdown's native light/dark/auto switch. A custom
`navbar.structure.right` must include `lightswitch` to display the control.
Do not layer another Bootswatch theme or site CSS that overrides these styles.

The generated stylesheet is embedded in each page's head, after Bootstrap, so
it works at every page depth, on a local server, and under hosted subpaths.
The post-build step separates evaluated source, printed results, and rich output
in their original order. Usage and example source share the same code containers;
the inner `code` is transparent. Each plot keeps its own background and preferred
size, centered below the source and constrained to the available column width.
The transformation preserves widget IDs, initialization data, and source links.
It is safe to run more than once. Code and output are separated in the saved HTML,
before any browser script runs.

The companion script keeps example copy buttons limited to source code,
excluding printed output, widget tooltips, and serialized widget data. Ordinary
text selection and pkgdown's copy confirmation are preserved. Draw's interactive
widgets render their own palettes, so the theme disables pkgdown's inversion
filter for those widgets; use a Draw build with Bootstrap color-mode detection.
Fonts load from Google Fonts with local sans-serif and monospace fallbacks,
as in the Quarto theme. Pages contain no local checkout paths.

In docs-rtemis, `just theme-source /path/to/rtemis-theme` configures the common
source for both tools. `just api` builds and syncs all four API sites; each
`just api-<site>` rebuilds one. A missing theme source fails before publication.
Package repositories' independent build commands must opt in using the R helper.

See [pkgdown customization](https://pkgdown.r-lib.org/articles/customise.html)
and the [Quarto theme](../quarto/README.md).

## Check changes

Run `Rscript pkgdown/check.R` from the repository root to check source-update
propagation, metadata preservation, preset replacement, missing-source failure,
and example splitting (order, whitespace, payloads, links, and idempotence).
Review a built home page, reference index, and function page in both
modes, including search, copy, and the mobile navbar, after layout changes.
With Playwright available to Node, run
`node pkgdown/check-browser.cjs /path/to/draw-api` against a built Draw API site
to check widget mode changes, exact clipboard contents, matching Usage/Examples
surfaces, and separate responsive outputs at desktop and phone widths. It also
checks mixed code/output blocks and ordinary selected-text copying. A site URL
also works.

## License

[BSD 3-Clause](../LICENSE). The shared source includes
[Quarto third-party notices](../quarto/THIRD_PARTY_NOTICES.txt).
