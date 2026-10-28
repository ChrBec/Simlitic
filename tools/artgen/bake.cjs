// Renders the bake page headlessly and writes the PNGs + assets/sprites.json into the Godot project.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { createServer } = require('vite');
(async () => {
  const server = await createServer({ root: __dirname, server: { port: 5199 }, logLevel: 'error' });
  await server.listen();
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('pageerror', (e) => console.error(e));
  const only = process.env.ONLY || '';
  await page.goto('http://localhost:5199/' + (only ? '?only=' + only : ''));
  await page.waitForFunction(() => document.title === 'done', null, { timeout: 60000 });
  const baked = await page.evaluate(() => window.BAKED);
  const root = path.resolve(__dirname, '../../assets');
  const anchors = {};
  for (const item of baked) {
    const file = path.join(root, item.path);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, Buffer.from(item.data.split(',')[1], 'base64'));
    if (item.anchor) anchors[item.path.replace(/\.png$/, '')] = { anchor: item.anchor };
  }
  if (!only) fs.writeFileSync(path.join(root, 'sprites.json'), JSON.stringify(anchors, null, 1));
  console.log(`baked ${baked.length} files`);
  await browser.close();
  await server.close();
})();
