// Requires Playwright. Usage: node pkgdown/check-browser.cjs /path/to/draw-api
// An HTTP(S) site URL can be used instead of a directory.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

(async () => {
  const site = process.argv[2];
  if (!site) throw new Error('Supply a built Draw API site directory or URL.');
  const base = /^https?:/.test(site)
    ? site.replace(/\/?$/, '/')
    : pathToFileURL(path.resolve(site) + path.sep).href;
  const browser = await chromium.launch();
  try {
    for (const system of ['light', 'dark']) {
      const context = await browser.newContext({
        colorScheme: system, permissions: ['clipboard-read', 'clipboard-write'],
        viewport: { width: 1280, height: 1000 }, reducedMotion: 'reduce'
      });
      // Begin with a saved page choice opposite to the OS preference.
      await context.addInitScript((mode) => {
        if (!localStorage.getItem('theme')) localStorage.setItem('theme', mode);
      }, system === 'light' ? 'dark' : 'light');
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', (error) => errors.push(error.message));
      const checkMode = async (mode) => {
        await page.waitForFunction((dark) => {
          const widget = document.querySelector('.rtemis-draw');
          const chart = widget && window.echarts?.getInstanceByDom(widget);
          return chart?.getOption().backgroundColor === (dark ? '#181818' : '#ffffff') &&
            window.RtemisThemeWatch?.isDark() === dark && getComputedStyle(widget).filter === 'none';
        }, mode === 'dark');
      };
      const setMode = async (mode) => {
        await page.evaluate(() => scrollTo(0, 0));
        await page.waitForFunction(() => document.querySelector('.navbar').getBoundingClientRect().y >= 0);
        await page.locator('#dropdown-lightswitch').click();
        await page.locator(`[data-bs-theme-value="${mode}"]`).click();
        await checkMode(mode === 'auto' ? system : mode);
      };
      await page.goto(new URL('reference/setup_BoxplotConfig.html', base).href);
      await checkMode(system === 'light' ? 'dark' : 'light');
      for (const mode of ['light', 'dark', 'light']) await setMode(mode);
      await page.reload();
      await checkMode('light');
      await setMode('auto');
      await page.emulateMedia({ colorScheme: system === 'dark' ? 'light' : 'dark' });
      await checkMode(system === 'dark' ? 'light' : 'dark');

      // Force a visible plot tooltip: its DOM must never enter the clipboard.
      await page.evaluate(() => {
        echarts.getInstanceByDom(document.querySelector('.rtemis-draw'))
          .dispatchAction({ type: 'showTip', seriesIndex: 0, dataIndex: 1 });
      });
      const example = page.locator('#ref-examples + .sourceCode');
      await example.hover();
      await example.locator('.btn-copy-ex').click();
      assert.equal(await page.evaluate(() => navigator.clipboard.readText()),
        'draw(setup_BoxplotConfig(x = c("mpg", "hp")), data = mtcars)');
      await page.locator('.tooltip-inner').filter({ hasText: 'Copied!' }).waitFor();

      // Exercise multiple source spans, intervening output, nested widget DOM,
      // metadata, ordinary code blocks, and normal user-selected copy.
      await page.evaluate(() => {
        const fixtures = document.createElement('section');
        fixtures.id = 'clipboard-fixtures';
        const make = (id, markup) => {
          const block = document.createElement('div');
          block.id = id;
          block.className = 'sourceCode hasCopyButton';
          block.innerHTML = '<button class="btn btn-copy-ex" data-clipboard-copy title="Copy to clipboard">Copy</button>' +
            '<pre><code>' + markup + '</code></pre>';
          fixtures.append(block);
          window.jQuery(block.querySelector('button')).tooltip({ container: 'body' });
        };
        make('multiple-inputs', '<span class="r-in">x &lt;- 1\n#&gt; a source comment</span>\n' +
          '<span class="r-out">#&gt; printed output</span>\n<span class="r-in">print(x)</span>' +
          '<div class="html-widget">plot tooltip</div><script type="application/json">{"x":123}</script>');
        make('plain-input', '<span># A comment\nx &lt;- "hello"</span>' +
          '<span class="r-out">output</span><script type="application/json">{"data":1}</script>');
        fixtures.insertAdjacentHTML('beforeend', '<p id="normal-selection">Ordinary selected text</p>');
        document.querySelector('main').append(fixtures);
      });
      for (const [id, expected] of [
        ['multiple-inputs', 'x <- 1\n#> a source comment\nprint(x)'],
        ['plain-input', '# A comment\nx <- "hello"']
      ]) {
        await page.locator(`#${id}`).hover();
        await page.locator(`#${id} button`).click();
        assert.equal(await page.evaluate(() => navigator.clipboard.readText()), expected);
      }
      await page.evaluate(() => {
        getSelection().selectAllChildren(document.querySelector('#normal-selection'));
        document.execCommand('copy');
      });
      assert.equal(await page.evaluate(() => navigator.clipboard.readText()), 'Ordinary selected text');
      if (system === 'dark') {
        // Verify actual generated examples, including multiple outputs and all
        // three widget backends, at desktop and phone widths in both modes.
        for (const width of [1280, 390]) {
          await page.setViewportSize({ width, height: 1000 });
          for (const mode of ['light', 'dark']) {
            await page.evaluate((value) => localStorage.setItem('theme', value), mode);
            for (const topic of ['setup_LineConfig', 'draw_boxplot', 'draw_graph', 'draw_choropleth']) {
              await page.goto(new URL(`reference/${topic}.html`, base).href);
              await page.waitForFunction(() => {
                const widgets = [...document.querySelectorAll('.html-widget')];
                return widgets.length && widgets.every((widget) => widget.querySelector('canvas'));
              });
              const layout = await page.evaluate(() => {
                const usage = document.querySelector('#ref-usage + .sourceCode pre');
                const inputs = [...document.querySelectorAll('#ref-examples ~ .sourceCode pre')];
                const widgets = [...document.querySelectorAll('.rtemis-output .html-widget')];
                const rect = (node) => node.getBoundingClientRect();
                const surface = (node) => {
                  const style = getComputedStyle(node);
                  return [rect(node).width, style.backgroundColor, style.padding,
                    style.borderRadius, style.fontSize, style.lineHeight];
                };
                return {
                  usage: surface(usage), inputs: inputs.map(surface),
                  codeBackgrounds: inputs.map((pre) => getComputedStyle(pre.querySelector('code')).backgroundColor),
                  widgets: widgets.map((widget) => ({
                    outsideCode: !widget.closest('pre, code, .sourceCode'),
                    withinColumn: rect(widget).width <= rect(usage).width + 1,
                    centered: Math.abs((rect(widget).left + rect(widget).right) / 2 -
                      (rect(usage).left + rect(usage).right) / 2) < 1,
                    canvasWidth: rect(widget.querySelector('canvas')).width,
                    width: rect(widget).width,
                    background: getComputedStyle(widget).backgroundColor
                  })),
                  misplaced: document.querySelectorAll('.sourceCode pre .html-widget, .sourceCode pre script').length,
                  outputButtons: document.querySelectorAll('.rtemis-output .btn-copy-ex').length,
                  overflow: document.documentElement.scrollWidth > innerWidth,
                  sources: inputs.map((pre) => [...pre.querySelectorAll('.r-in')].map((n) => n.textContent.trimEnd()).join('\n'))
                };
              });
              assert.ok(layout.inputs.length && layout.widgets.length, `${topic}: missing examples`);
              layout.inputs.forEach((input) => assert.deepEqual(input, layout.usage, `${topic}: Usage/Examples mismatch`));
              assert.ok(layout.codeBackgrounds.every((bg) => bg === 'rgba(0, 0, 0, 0)'));
              assert.equal(layout.misplaced, 0);
              assert.equal(layout.outputButtons, 0);
              assert.equal(layout.overflow, false, `${topic}: page overflow at ${width}px`);
              layout.widgets.forEach((widget) => {
                assert.ok(widget.outsideCode && widget.withinColumn && widget.centered, JSON.stringify(widget));
                assert.ok(Math.abs(widget.canvasWidth - widget.width) < 1, `${topic}: canvas size mismatch`);
                assert.equal(widget.background, mode === 'dark' ? 'rgb(24, 24, 24)' : 'rgb(255, 255, 255)');
              });
              // Every separated source block gets its own exact copy action.
              if (width === 1280 && mode === 'dark' && topic === 'draw_boxplot') {
                const blocks = page.locator('#ref-examples ~ .sourceCode');
                for (let i = 0; i < layout.sources.length; i++) {
                  await blocks.nth(i).hover();
                  await blocks.nth(i).locator('.btn-copy-ex').click();
                  assert.equal(await page.evaluate(() => navigator.clipboard.readText()), layout.sources[i]);
                }
              }
            }
          }
        }
      }
      assert.deepEqual(errors, []);
      await context.close();
    }
    console.log('Widget modes, exact source-only copying, and separate responsive output layouts passed.');
  } finally {
    await browser.close();
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
