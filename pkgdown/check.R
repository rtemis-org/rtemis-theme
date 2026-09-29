# Run from the repository root: Rscript pkgdown/check.R
# Differential checks: edits to the existing Quarto sources must reach pkgdown.
local({
  source("pkgdown/rtemis.R")
  fixture <- tempfile("rtemis-theme-")
  dir.create(fixture)
  on.exit(unlink(fixture, recursive = TRUE))
  stopifnot(all(file.copy(c("quarto", "pkgdown"), fixture, recursive = TRUE)))

  config <- list(
    url = "https://example.org/reference",
    navbar = list(structure = list(right = c("search", "lightswitch"))),
    template = list(
      bootswatch = "darkly",
      bslib = list(bootswatch = "darkly", code_font = list(google = "Fira Code")),
      params = list(bootswatch = "darkly"),
      includes = list(head = '<meta name="fixture" content="retained">',
                      after_body = "<footer>retained</footer>")
    )
  )
  initial <- rtemis_pkgdown(fixture, config)
  merged <- utils::modifyList(config, initial)
  stopifnot(
    identical(initial$navbar, config$navbar), identical(initial$url, config$url),
    grepl(config$template$includes$head, initial$template$includes$head, fixed = TRUE),
    identical(initial$template$includes$after_body, config$template$includes$after_body),
    is.null(merged$template$bootswatch), is.null(merged$template$bslib$bootswatch),
    is.null(merged$template$params$bootswatch),
    !grepl(fixture, initial$template$includes$head, fixed = TRUE),
    !grepl("Fira Code", initial$template$includes$head, fixed = TRUE)
  )

  path <- file.path(fixture, "quarto", "rtemis-light.scss")
  writeLines(gsub("#6CA3A0", "#123456", readLines(path), fixed = TRUE), path)
  path <- file.path(fixture, "quarto", "_rtemis-defaults.scss")
  writeLines(gsub(".375rem", ".5rem", readLines(path), fixed = TRUE), path)
  path <- file.path(fixture, "quarto", "rtemis-dark.theme")
  palette <- jsonlite::fromJSON(path)
  palette[["text-styles"]]$Function[["text-color"]] <- "#ABCDEF"
  jsonlite::write_json(palette, path, auto_unbox = TRUE, null = "null")
  changed <- rtemis_pkgdown(fixture, config)
  stopifnot(
    changed$template$bslib$primary == "#123456",
    changed$template$bslib[["navbar-padding-y"]] == "0.5rem",
    grepl("#ABCDEF", changed$template$includes$head, fixed = TRUE),
    !identical(initial$template$includes$head, changed$template$includes$head)
  )

  unlink(file.path(fixture, "quarto", "rtemis-dark.theme"))
  failed <- suppressWarnings(tryCatch(
    { rtemis_pkgdown(fixture, config); FALSE }, error = function(e) TRUE
  ))
  stopifnot(failed)
  message("pkgdown theme checks passed: source propagation, metadata, presets, and missing-source failure.")
})

# Mixed examples must keep their execution order and exact widget payload while
# becoming independent source/output siblings. Run before browser verification.
local({
  source("pkgdown/rtemis.R")
  fixture <- tempfile("rtemis-examples-")
  dir.create(fixture)
  on.exit(unlink(fixture, recursive = TRUE))
  file <- file.path(fixture, "example.html")
  writeLines(paste0(
    '<!DOCTYPE html><html><head><title>Example</title></head><body>',
    '<div id="usage" class="sourceCode"><pre><code>draw(x)</code></pre></div>',
    '<section id="examples"><div id="example-source" class="sourceCode">',
    '<pre class="sourceCode r"><code>',
    '<span class="r-in"><a href="x.html">x</a> &lt;- 1</span>\n',
    '<span class="r-in">\nprint(x)</span>\n',
    '<span class="r-out co">#&gt; 1</span>\n',
    '<span class="r-msg co">message</span>\n',
    '<span class="r-wrn co">warning</span>\n',
    '<span class="r-err co">error</span>\n',
    '<span class="r-in">draw(x)</span>\n',
    '<div id="widget-one" class="html-widget" style="width:700px;height:400px"></div>\n',
    '<script type="application/json" data-for="widget-one">{"x":"a & b < c", "evals":[]}</script>\n',
    '<div id="widget-two" class="html-widget"></div>\n',
    '<script type="application/json" data-for="widget-two">{"x":2}</script>\n',
    '<span class="r-in">plot(x)</span>\n',
    '<span class="r-plt img"><img src="plot.png" alt="plot"></span>\n',
    '<span class="r-in">table(x)</span>\n',
    '<div class="gt-table"><table><tr><td>A</td></tr></table></div>',
    '</code></pre></div></section>',
    '<div id="unknown" class="sourceCode"><pre><code>',
    '<span class="r-in">x</span>unmarked text<div>output</div>',
    '</code></pre></div></body></html>'
  ), file)
  before <- xml2::read_html(file)
  scripts <- xml2::xml_text(xml2::xml_find_all(before, "//script"))
  usage <- as.character(xml2::xml_find_first(before, "//*[@id='usage']"))
  unknown <- as.character(xml2::xml_find_first(before, "//*[@id='unknown']"))
  stopifnot(rtemis_pkgdown_examples(fixture) == 1L)
  after <- xml2::read_html(file)
  blocks <- xml2::xml_find_all(after, "//section[@id='examples']/div")
  stopifnot(
    identical(xml2::xml_attr(blocks, "class"), c(
      "sourceCode", "rtemis-output rtemis-output-text", "sourceCode",
      "rtemis-output rtemis-output-display", "rtemis-output rtemis-output-display",
      "sourceCode", "rtemis-output rtemis-output-display",
      "sourceCode", "rtemis-output rtemis-output-display"
    )),
    identical(xml2::xml_text(xml2::xml_find_all(after, "//script")), scripts),
    identical(as.character(xml2::xml_find_first(after, "//*[@id='usage']")), usage),
    identical(as.character(xml2::xml_find_first(after, "//*[@id='unknown']")), unknown),
    identical(xml2::xml_text(xml2::xml_find_first(blocks[[1]], "pre/code")),
              "x <- 1\n\nprint(x)"),
    identical(xml2::xml_text(blocks[[2]]), "#> 1\nmessage\nwarning\nerror"),
    xml2::xml_attr(xml2::xml_find_first(blocks[[1]], ".//a"), "href") == "x.html",
    xml2::xml_attr(xml2::xml_find_first(blocks[[4]], "div"), "id") == "widget-one",
    xml2::xml_attr(xml2::xml_find_first(blocks[[5]], "div"), "id") == "widget-two",
    length(xml2::xml_find_all(after, "//*[@id='example-source']")) == 1L,
    length(xml2::xml_find_all(after, "//section//code/script | //section//code/div | //section//code//img")) == 0L
  )
  saved <- readBin(file, "raw", file.info(file)$size)
  stopifnot(rtemis_pkgdown_examples(fixture) == 0L,
            identical(readBin(file, "raw", file.info(file)$size), saved))
  message("pkgdown example checks passed: source/output order, whitespace, payloads, links, and idempotence.")
})
