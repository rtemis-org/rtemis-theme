# Source this file, then pass rtemis_pkgdown(theme_dir, config) to
# pkgdown::build_site(override = ...). No template package installation is needed.
rtemis_pkgdown <- function(theme_dir, config = list()) {
  if (utils::packageVersion("pkgdown") < "2.2.1") {
    stop("The rtemis theme requires pkgdown 2.2.1 or later.")
  }
  theme_dir <- normalizePath(theme_dir, mustWork = TRUE)
  quarto_dir <- file.path(theme_dir, "quarto")
  read <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")

  # Let Sass resolve the existing Quarto defaults, including imports and mixes.
  # Stop before Quarto-specific rules; its layout and Bootstrap build are separate.
  values <- function(mode) {
    source <- read(file.path(quarto_dir, paste0("rtemis-", mode, ".scss")))
    marker <- "/*-- scss:rules --*/"
    if (!grepl(marker, source, fixed = TRUE)) {
      stop("Missing Quarto Sass rules marker in ", mode, " theme.")
    }
    defaults <- strsplit(source, marker, fixed = TRUE)[[1]][[1]]
    names <- c(
      "body-bg", "body-color", "rthighlight", "code-block-bg", "code-block-color",
      "font-family-sans-serif", "font-family-monospace", "font-size-base",
      "h2-font-size", "h3-font-size", "navbar-padding-y", "navbar-bg", "navbar-fg"
    )
    declarations <- c(sprintf("--%s: #{$%s};", names, names), vapply(
      c("body-bg", "body-color", "rthighlight"), function(name) sprintf(
        "--%s-rgb: #{red($%s)}, #{green($%s)}, #{blue($%s)};", name, name, name, name
      ), character(1)
    ))
    css <- sass::sass(
      paste(defaults, ".rtemis-values {", paste(declarations, collapse = "\n"), "}"),
      options = sass::sass_options(output_style = "expanded", include_path = quarto_dir),
      cache = FALSE
    )
    lines <- strsplit(css, "\n", fixed = TRUE)[[1]]
    lines <- trimws(lines[grepl("^\\s*--", lines)])
    stats::setNames(
      sub("^--[^:]+: (.*);$", "\\1", lines),
      sub("^--([^:]+):.*$", "\\1", lines)
    )
  }
  light <- values("light")
  dark <- values("dark")

  # Pandoc/Skylighting and downlit use these same token classes. Explicit style
  # resets prevent the built-in pkgdown palette from leaving inherited italics.
  classes <- c(
    Alert = "al", Annotation = "an", Attribute = "at", BaseN = "bn",
    BuiltIn = "bu", ControlFlow = "cf", Char = "ch", Constant = "cn",
    Comment = "co", CommentVar = "cv", Documentation = "do", DataType = "dt",
    DecVal = "dv", Error = "er", Extension = "ex", Float = "fl", Function = "fu",
    Import = "im", Information = "in", Keyword = "kw", Operator = "op",
    Other = "ot", Preprocessor = "pp", RegionMarker = "re", SpecialChar = "sc",
    SpecialString = "ss", String = "st", Variable = "va", VerbatimString = "vs",
    Warning = "wa"
  )
  syntax <- function(mode) {
    palette <- jsonlite::fromJSON(file.path(quarto_dir, paste0("rtemis-", mode, ".theme")))
    styles <- palette[["text-styles"]]
    roles <- c("Normal", names(classes))
    if (!all(roles %in% names(styles))) stop("Incomplete ", mode, " syntax palette.")
    paste(vapply(roles, function(role) {
      style <- styles[[role]]
      selector <- if (role == "Normal") "pre code" else paste0("pre code span.", classes[[role]])
      sprintf(
        "%s { color: %s; background-color: %s; font-weight: %s; font-style: %s; text-decoration: %s; }",
        selector, style[["text-color"]],
        if (is.null(style[["background-color"]])) "transparent" else style[["background-color"]],
        if (isTRUE(style$bold)) "bold" else "normal",
        if (isTRUE(style$italic)) "italic" else "normal",
        if (isTRUE(style$underline)) "underline" else "none"
      )
    }, character(1)), collapse = "\n")
  }
  mode_css <- function(mode, tokens) {
    selector <- if (mode == "light") ":root, [data-bs-theme='light']" else "[data-bs-theme='dark']"
    paste0(selector, " {\n",
      paste(sprintf("--rt-%s: %s;", names(tokens), tokens), collapse = "\n"), "\n",
      syntax(mode), "\n}"
    )
  }
  css <- sass::sass(
    list(mode_css("light", light), mode_css("dark", dark),
         sass::sass_file(file.path(theme_dir, "pkgdown", "rtemis.scss"))),
    options = sass::sass_options(output_style = "compressed"), cache = FALSE
  )
  # Inline CSS is independent of the page depth and works in local previews as
  # well as hosted subdirectories. No machine-local source path enters the HTML.
  head <- paste(
    config$template$includes$head,
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Geist+Mono:wght@100..900&amp;family=Geist:wght@100..900&amp;display=swap">',
    paste0('<style id="rtemis-pkgdown">', css, "</style>"),
    paste0('<script id="rtemis-pkgdown-copy">',
           read(file.path(theme_dir, "pkgdown", "rtemis.js")), "</script>"), sep = "\n"
  )
  bslib <- list(
    preset = "bootstrap", bootswatch = NULL,
    bg = light[["body-bg"]], fg = light[["body-color"]],
    primary = light[["rthighlight"]],
    base_font = light[["font-family-sans-serif"]],
    heading_font = light[["font-family-sans-serif"]],
    code_font = light[["font-family-monospace"]],
    `font-size-base` = light[["font-size-base"]],
    `h2-font-size` = light[["h2-font-size"]], `h3-font-size` = light[["h3-font-size"]],
    `body-bg-dark` = dark[["body-bg"]], `body-color-dark` = dark[["body-color"]],
    `link-color-dark` = dark[["rthighlight"]],
    `code-bg` = light[["code-block-bg"]], `code-color` = light[["code-block-color"]],
    `code-color-dark` = dark[["code-block-color"]],
    `navbar-bg` = light[["navbar-bg"]], `navbar-padding-y` = light[["navbar-padding-y"]],
    `pkgdown-nav-height` = "56px"
  )
  result <- utils::modifyList(config, list(template = list(
    bootstrap = 5L, `light-switch` = TRUE, bootswatch = NULL,
    theme = "monochrome-light", `theme-dark` = "monochrome-dark",
    bslib = bslib, includes = list(head = head)
  )))
  # Keep explicit NULLs so pkgdown's later config merge removes old presets.
  result$template["bootswatch"] <- list(NULL)
  result$template$bslib["bootswatch"] <- list(NULL)
  result$template$params["bootswatch"] <- list(NULL)
  result
}

# Separate evaluated source and output before the browser initializes widgets
# or adds copy buttons. Usage and unevaluated code retain pkgdown's markup.
# Call after pkgdown::build_site(), passing the resolved output directory.
# Returns the number of changed pages, invisibly; repeated calls are harmless.
rtemis_pkgdown_examples <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  has_class <- function(node, name) {
    value <- xml2::xml_attr(node, "class")
    !is.na(value) && name %in% strsplit(value, "\\s+")[[1]]
  }
  classify <- function(node) {
    if (xml2::xml_type(node) == "text") return("space")
    if (has_class(node, "r-in")) return("source")
    if (any(vapply(c("r-out", "r-msg", "r-wrn", "r-err"),
                   function(name) has_class(node, name), logical(1)))) return("text")
    if (xml2::xml_name(node) %in% c("script", "style", "link")) return("metadata")
    "display"
  }
  # Copy source attributes and anchors without duplicating container IDs when
  # one original example becomes several source blocks.
  attributes <- function(node, first) {
    attrs <- xml2::xml_attrs(node)
    if (!first) attrs <- attrs[names(attrs) != "id"]
    attrs
  }
  changed <- 0L
  for (file in list.files(path, "[.]html$", recursive = TRUE, full.names = TRUE)) {
    # Do not strip blank text nodes: they separate highlighted source lines.
    doc <- xml2::read_html(file, options = c("RECOVER", "NOERROR", "NOWARNING", "NONET"))
    codes <- xml2::xml_find_all(doc, paste0(
      "//div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]/pre/code",
      "[span[contains(concat(' ', normalize-space(@class), ' '), ' r-in ')]]"
    ))
    modified <- FALSE
    for (code in codes) {
      nodes <- xml2::xml_contents(code)
      kinds <- vapply(nodes, classify, character(1))
      if (all(kinds %in% c("source", "space"))) next
      # Unknown unmarked text is not safe to classify as input or output.
      # Leave such a block intact rather than silently losing its contents.
      if (any(vapply(nodes[kinds == "space"], function(node) {
        nzchar(trimws(xml2::xml_text(node)))
      }, logical(1)))) next

      pre <- xml2::xml_parent(code)
      original <- xml2::xml_parent(pre)
      current <- NULL
      kind <- NULL
      whitespace <- list()
      first_source <- TRUE
      for (i in seq_along(nodes)) {
        next_kind <- kinds[[i]]
        if (next_kind == "space") {
          whitespace <- c(whitespace, list(nodes[[i]]))
          next
        }
        # Each rich output gets its own host, with its initialization metadata.
        # This also contains widgets which paint their immediate parent's bg.
        same <- !is.null(current) && (next_kind == "metadata" ||
          (next_kind == kind && next_kind != "display"))
        if (!same) {
          block <- xml2::xml_add_sibling(original, "div", .where = "before")
          if (next_kind == "source") {
            xml2::xml_attrs(block) <- attributes(original, first_source)
            new_pre <- xml2::xml_add_child(block, "pre")
            xml2::xml_attrs(new_pre) <- attributes(pre, first_source)
            current <- xml2::xml_add_child(new_pre, "code")
            xml2::xml_attrs(current) <- attributes(code, first_source)
            first_source <- FALSE
          } else {
            xml2::xml_set_attr(block, "class", paste("rtemis-output", paste0("rtemis-output-", next_kind)))
            current <- if (next_kind == "text") {
              xml2::xml_add_child(xml2::xml_add_child(block, "pre"), "code")
            } else block
          }
          kind <- next_kind
        } else {
          for (space in whitespace) xml2::xml_add_child(current, space)
        }
        whitespace <- list()
        xml2::xml_add_child(current, nodes[[i]])
      }
      xml2::xml_remove(original)
      modified <- TRUE
    }
    if (modified) {
      xml2::write_html(doc, file, options = character())
      changed <- changed + 1L
    }
  }
  invisible(changed)
}
