// Keep pkgdown's clipboard implementation and feedback, but supply source text
// when its copy button fires the native copy event. Example containers also
// contain printed output, live widget DOM, and serialized widget data.
(() => {
  let pendingSource = null;
  let pendingButton = null;

  document.addEventListener("click", (event) => {
    const button = event.target.closest?.(".btn-copy-ex[data-clipboard-copy]");
    const code = button?.closest(".sourceCode")?.querySelector("pre > code");
    if (!code) return;
    pendingButton = button;

    const inputs = code.querySelectorAll(".r-in");
    if (inputs.length) {
      pendingSource = Array.from(inputs, (input) => input.textContent.trimEnd()).join("\n");
    } else {
      const source = code.cloneNode(true);
      source.querySelectorAll(".r-out, .r-plt, .html-widget, script, style")
        .forEach((output) => output.remove());
      pendingSource = source.textContent.replace(/^\n+|\n+$/g, "");
    }
    // ClipboardJS copies synchronously during this click. Clear the context
    // afterward so ordinary keyboard/menu copies keep the user's selection.
    setTimeout(() => { pendingSource = null; pendingButton = null; }, 0);
  }, true);

  document.addEventListener("copy", (event) => {
    if (pendingSource === null || !event.clipboardData) return;
    event.clipboardData.setData("text/plain", pendingSource);
    event.preventDefault();
    const button = pendingButton;
    pendingSource = null;
    // Use Bootstrap's content API after pkgdown's handler. Re-showing an
    // already visible tooltip can otherwise retain "Copy to clipboard".
    setTimeout(() => {
      const tooltip = window.bootstrap?.Tooltip.getInstance(button);
      if (!tooltip) return;
      tooltip.setContent({ ".tooltip-inner": "Copied!" });
      tooltip.show();
      button.addEventListener("hidden.bs.tooltip", () => {
        tooltip.setContent({ ".tooltip-inner": button.getAttribute("aria-label") || "Copy to clipboard" });
      }, { once: true });
    }, 0);
  }, true);
})();
