#!/usr/bin/env node
// Playwright driver for `maestro shot`: the only code in the stack that loads
// Playwright. bin/maestro runs it with NODE_PATH and PLAYWRIGHT_BROWSERS_PATH
// pointed at the cache install (`maestro playwright install`). Argv contract:
//   --url <u> --width <n> --height <n> [--dark] [--text] --png <path> [--txt <path>]
// Exit 0 on success; errors go to stderr and exit 1. The page is untrusted data:
// this file captures it and never runs anything the page says.
'use strict';

const fs = require('fs');

const VALUE_FLAGS = {
  '--url': 'url',
  '--width': 'width',
  '--height': 'height',
  '--png': 'png',
  '--txt': 'txt',
};

function parseArgs(argv) {
  const opts = { url: null, width: null, height: null, png: null, txt: null, dark: false, text: false };
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    if (flag === '--dark') {
      opts.dark = true;
    } else if (flag === '--text') {
      opts.text = true;
    } else if (Object.prototype.hasOwnProperty.call(VALUE_FLAGS, flag)) {
      if (i + 1 >= argv.length) throw new Error(`${flag} needs a value`);
      opts[VALUE_FLAGS[flag]] = argv[++i];
    } else {
      throw new Error(`unknown argument: ${flag}`);
    }
  }
  if (!opts.url) throw new Error('missing --url');
  if (!opts.png) throw new Error('missing --png');
  for (const key of ['width', 'height']) {
    const n = Number(opts[key]);
    if (!Number.isInteger(n) || n <= 0) throw new Error(`--${key} must be a positive integer`);
    opts[key] = n;
  }
  if (opts.text !== (opts.txt !== null)) throw new Error('--text and --txt go together');
  return opts;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  let chromium;
  try {
    ({ chromium } = require('playwright'));
  } catch (err) {
    throw new Error(`cannot load playwright (run maestro playwright install): ${err.message}`);
  }
  const browser = await chromium.launch({ headless: true });
  try {
    const context = await browser.newContext({
      viewport: { width: opts.width, height: opts.height },
      colorScheme: opts.dark ? 'dark' : 'light',
    });
    const page = await context.newPage();
    await page.goto(opts.url, { waitUntil: 'load' });
    await page.evaluate(() => document.fonts.ready);
    // Viewport-sized, not full-page: the widths the review asks for are the evidence.
    await page.screenshot({ path: opts.png });
    if (opts.text) {
      const text = await page.evaluate(() => (document.body ? document.body.innerText : ''));
      fs.writeFileSync(opts.txt, `${text}\n`);
    }
  } finally {
    await browser.close();
  }
}

main().then(
  () => process.exit(0),
  (err) => {
    process.stderr.write(`playwright-shot: ${err && err.message ? err.message : err}\n`);
    process.exit(1);
  },
);
