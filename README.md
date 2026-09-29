# rtemis themes

Dark and light themes for [rtemis](https://www.rtemis.org), with a shared syntax
palette across VS Code, Zed, Quarto, and pkgdown. Editor diffs use green additions,
red deletions, and blue modification markers.

## Install

| Platform             | Themes                                   | Installation                  |
|----------------------|------------------------------------------|-------------------------------|
| [VS Code](vscode/)   | `rtemis-dark` and `rtemis-light`         | [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=egenn.rtemis-dark) |
| [Open VSX](openvsx/) | `rtemis-dark` and `rtemis-light`         | [Open VSX Registry](https://open-vsx.org/extension/egenn/rtemis-theme) |
| [Zed](zed/)          | `rtemis-dark` and `rtemis-light`         | [Zed extensions](https://zed.dev/extensions/rtemis-theme) |
| [Quarto](quarto/)    | Dark and light website and syntax themes | [Book setup](quarto/README.md#use-in-a-book) |
| [pkgdown](pkgdown/)  | Matching dark and light API reference sites | [API site setup](pkgdown/README.md#use) |

In VS Code and compatible editors, choose **rtemis-dark** or **rtemis-light** with
**Preferences: Color Theme** after installing the extension.

See the [editor screenshots](vscode/README.md). Quarto themes include matching
code highlighting and a customizable website accent. The pkgdown adapter reads
the same theme sources to keep books and API references consistent.

## License

[BSD 3-Clause](LICENSE), with [third-party notices](vscode/THIRD_PARTY_NOTICES.txt)
for the VS Code and Open VSX themes and [Quarto notices](quarto/THIRD_PARTY_NOTICES.txt)
for its adapted website component styles.
