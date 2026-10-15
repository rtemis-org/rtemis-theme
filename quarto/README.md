# rtemis themes for Quarto

Shared dark and light website themes, with code highlighting that matches the
rtemis editor palette. Each SCSS file combines the established website styling
with matching code surfaces. The `.theme` files provide syntax colors as
KDE/Skylighting JSON accepted by Pandoc. All files are maintained directly,
without a build step.

## Use in a book

Use this directory as the shared source for all books, including the SCSS
partials, syntax palettes, license, and notices. Merge into `_quarto.yml`:

```yaml
format:
  html:
    css: themes/rtemis/fonts.css
    theme:
      light: themes/rtemis/rtemis-light.scss
      dark: themes/rtemis/rtemis-dark.scss
    syntax-highlighting:
      light: themes/rtemis/rtemis-light.theme
      dark: themes/rtemis/rtemis-dark.theme
```

The SCSS files are complete custom themes; no Bootswatch base or additional
site stylesheet is needed. `_rtemis-defaults.scss` owns Geist/Geist Mono font
families and the compact navbar (0.375rem vertical padding per side). `_rtemis-rules.scss` owns font loading, code-language labels, image
and spacing helpers, title metadata, DataTables dark styles, cards, buttons,
and callouts. Both color modes import the same partials.

Change shared appearance here rather than editing consumer copies. The accent
`$rthighlight` in the two mode files controls links, primary controls, sidebar
highlights, and the webR run icon. Syntax colors are independent of the accent.
The [pkgdown adapter](../pkgdown/README.md) reads these same defaults and syntax
palettes to style companion API reference sites.

For a book's front page, opt in to the shared landing layout:

```yaml
format:
  html:
    body-classes: rtemis-landing
```

This hides the title block and TOC, aligns the content with the sidebar, and uses
42px headings. It does not affect ordinary chapter pages. Logos and navigation
content remain book metadata. The unused legacy logo-mask rule is not included.

`rtemis-exercises.scss` is an optional webR/webexercises integration; append it
to both mode theme lists only for books that use those interactive controls.
It is not loaded by default.

Quarto ignores highlighting-file backgrounds when using adaptive light/dark
highlighting. The SCSS supplies the neutral code backgrounds: `#F7F7F7` in light
mode and `#303030` in dark mode. Page backgrounds retain the website defaults,
white in light mode and `#181818` in dark mode. The `Normal` token style sets code
foregrounds in both modes, including text without a specialized token.

When migrating, remove the old duplicate website/font/layout CSS and use one
`syntax-highlighting` setting instead of `highlight-style: atom-one`. The shared
theme owns code/output surfaces; avoid consumer CSS that overrides them.

For a single-mode HTML book:

```yaml
format:
  html:
    css: themes/rtemis/fonts.css
    theme: themes/rtemis/rtemis-light.scss
    syntax-highlighting: themes/rtemis/rtemis-light.theme
```

For PDF output, configure the light highlighting file separately:

```yaml
format:
  pdf:
    syntax-highlighting: themes/rtemis/rtemis-light.theme
```

The HTML SCSS files do not apply to PDF. Older Quarto versions use
`highlight-style` in place of `syntax-highlighting`; the theme files are the same.
The configurations above were checked with Quarto 1.10.18 and its Pandoc 3.10.

## Fonts

Geist Sans loads from Google Fonts. Geist Mono loads from the bundled
`fonts/GeistMono-Variable.woff2`, taken from the official `geist@1.7.2` npm
package (`dist/fonts/geist-mono/GeistMono-Variable.woff2`). The variable font
supports weights 100–900 and includes the `ss11` coding ligature feature.
The shared rules enable this feature on `pre`, `code`, `kbd`, and `samp`.

Copy `fonts.css` and the `fonts/` directory together with the SCSS files.
Load `fonts.css` through `format.html.css` (or the chosen HTML-derived format).
The font URL resolves relative to this stylesheet, including when the theme
lives in a nested directory. Quarto copies the referenced font to the output.
Include the font license as a project resource, adjusting the theme path:

```yaml
project:
  resources:
    - themes/rtemis/fonts/OFL.txt
```

The font is distributed under the SIL Open Font License in `fonts/OFL.txt`.
Rendering requires no npm installation. Font updates retain the full font's
OpenType features; Google Fonts subsets omit `ss11`.

## Page footer

Use Quarto's native book footer for a centered logo and copyright group:

```yaml
book:
  page-footer:
    border: false
    center: |
      <span class="rtemis-footer">
        <a href="https://www.rtemis.org/"><img src="/assets/favicon.svg" alt="rtemis"></a>
        <span>© 2026 E.D. Gennatas</span>
      </span>
```

Set the image, link, copyright holder, and year range for the book. The image
path starts at the project root so it also works for nested chapters. Websites
use the same `page-footer` configuration under `website` instead of `book`.
The theme supplies compact spacing, subdued text, and a logo height of
1.25rem. The group wraps on narrow screens. Add `class="inv"` to a black logo
image to invert it in dark mode; colored logos can retain their colors.
The footer is opt-in and does not add attribution to other theme consumers.

## Share updates across books

Keep this repository as the source of truth. Refresh all theme SCSS (including
underscore-prefixed partials), both `.theme` files, and both notices together.
Do not edit generated consumer copies. In docs-rtemis, a shared pre-render hook
automatically refreshes all four books from the configured local checkout;
`just render` rebuilds and syncs them, and `just sync-theme` refreshes open
previews' local theme files. Other consumers must adopt the complete payload
when updating; their existing copies are not changed by editing this repository.

## Preview and matching

From this repository's root:

```sh
quarto preview quarto/preview.qmd
```

Use the page's light/dark toggle to review the R, Python, Julia, and JSON examples.
The preview does not execute code or require those language runtimes.

Functions are blue, types light blue, named arguments/attributes orange,
numbers and constants pink, strings teal, and keywords violet. Operators are
neutral gray. Comments and their documentation annotations use upright text.

Pandoc/Skylighting has fewer token categories than VS Code or Zed. For example,
R named arguments use `Attribute`, while the `L` suffix in `2L` uses `DataType`.
`Attribute` is also used for HTML attributes and some other languages' properties.
The palette matches; individual token classification depends on the language
highlighter. A color theme cannot add semantic classifications.

The SCSS preserves the established website component styling and `.day`/`.night`
visibility helpers. Redundant defaults, unused legacy container widths, commented
examples, and conflicting code-background overrides have been removed. Variable
removals were checked against compiled CSS with Quarto 1.10.18.

See [Quarto theme layering](https://quarto.org/docs/output-formats/html-themes-more.html#bootstrap-bootswatch-layering),
[Quarto custom highlighting](https://quarto.org/docs/output-formats/html-code.html#custom-highlighting)
and [Pandoc syntax highlighting](https://pandoc.org/MANUAL.html#syntax-highlighting).

## License

[BSD 3-Clause](LICENSE), with [third-party notices](THIRD_PARTY_NOTICES.txt) for
the adapted website component styles.
