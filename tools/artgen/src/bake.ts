// Bakes the procedural "painted" placeholder art into PNG files for the Godot project.
// Run with `npm run bake` (see tools/artgen/bake.cjs). Every PNG can later be replaced by real art
// of the same name – the game only knows asset ids and the anchors in assets/sprites.json.
import { BUILDINGS, GOODS, TIERS } from './content';
import { blob, canvas, inkLine, makeRng, paintPath, paperTexture, rgba, wobblyShape, INK } from './painter';
import { PAL } from './palette';
import { SCALE, bushSprite, buildingSprite, depositSprite, goodIcon, peakSprite, rockSprite, treeSprite, walkerSprite, type Sprite } from './sprites';

interface Out { path: string; data: string; anchor?: [number, number] }
const out: Out[] = [];

function addSprite(path: string, s: Sprite) {
  const c = s.img as HTMLCanvasElement;
  out.push({ path, data: c.toDataURL('image/png'), anchor: [Math.round(s.ax * SCALE), Math.round(s.ay * SCALE)] });
}
function addCanvas(path: string, c: HTMLCanvasElement) { out.push({ path, data: c.toDataURL('image/png') }); }

// `npm run bake:goods` (?only=goods) re-bakes just the goods icons and leaves every other file alone.
const ONLY_GOODS = new URLSearchParams(location.search).get('only') === 'goods';
if (ONLY_GOODS) for (const g of GOODS) addCanvas(`goods/${g.id}.png`, goodIcon(g.color, g.glyph, 64));
if (!ONLY_GOODS) {
for (const b of BUILDINGS) if (b.id !== 'path') addSprite(`buildings/${b.id}.png`, buildingSprite(b.id));
for (let i = 0; i < 9; i++) addSprite(`nature/tree_${i}.png`, treeSprite(i));
for (let i = 0; i < 4; i++) addSprite(`nature/bush_${i}.png`, bushSprite(i));
for (let i = 0; i < 3; i++) addSprite(`nature/rock_${i}.png`, rockSprite(i));
for (const d of ['flint', 'copper', 'tin']) addSprite(`nature/deposit_${d}.png`, depositSprite(d));
for (let v = 0; v < 6; v++) for (const sz of [0, 0.25, 0.5, 0.75, 1]) addSprite(`nature/peak_${v}_${Math.round(sz * 100)}.png`, peakSprite(v, sz));
const walkerColors: Record<string, string> = { porter: '#6b4a2e', scout: '#3a6a8a' };
for (const t of TIERS) walkerColors[t.id] = t.color;
for (const [id, c] of Object.entries(walkerColors)) addSprite(`people/${id}.png`, walkerSprite(c));
for (const g of GOODS) addCanvas(`goods/${g.id}.png`, goodIcon(g.color, g.glyph, 64));

// brush dabs (white, tinted in-engine) for the painted ground
for (let i = 0; i < 4; i++) {
  const [c, ctx] = canvas(96, 32);
  const rng = makeRng(500 + i);
  for (let k = 0; k < 7; k++) {
    ctx.strokeStyle = `rgba(255,255,255,${0.25 + rng() * 0.35})`;
    ctx.lineWidth = 6 + rng() * 10; ctx.lineCap = 'round';
    const y = 16 + (rng() - 0.5) * 8;
    ctx.beginPath(); ctx.moveTo(10 + rng() * 10, y + (rng() - 0.5) * 6); ctx.quadraticCurveTo(48, y + (rng() - 0.5) * 10, 86 - rng() * 10, y + (rng() - 0.5) * 6); ctx.stroke();
  }
  addCanvas(`brush/stroke_${i}.png`, c);
}
{
  const [c, ctx] = canvas(64, 64);
  const g = ctx.createRadialGradient(32, 32, 4, 32, 32, 31);
  g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.7, 'rgba(255,255,255,0.8)'); g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(32, 32, 32, 0, Math.PI * 2); ctx.fill();
  addCanvas('brush/dab.png', c);
}

// UI skin: paper, panels (9-slice), buttons, leather bar, flags
addCanvas('ui/paper.png', paperTexture(256, '#ecdfc0', 7));
function panel(w: number, h: number, base: string, seed: number, inkW = 2.4, edge = 6) {
  const [c, ctx] = canvas(w, h);
  const rng = makeRng(seed);
  const pts: [number, number][] = [];
  const m = edge;
  const steps = 10;
  for (let i = 0; i <= steps; i++) pts.push([m + (w - 2 * m) * (i / steps), m + (rng() - 0.5) * 2]);
  for (let i = 1; i <= steps; i++) pts.push([w - m + (rng() - 0.5) * 2, m + (h - 2 * m) * (i / steps)]);
  for (let i = 1; i <= steps; i++) pts.push([w - m - (w - 2 * m) * (i / steps), h - m + (rng() - 0.5) * 2]);
  for (let i = 1; i < steps; i++) pts.push([m + (rng() - 0.5) * 2, h - m - (h - 2 * m) * (i / steps)]);
  ctx.fillStyle = 'rgba(58,42,30,0.35)';
  ctx.fillRect(m + 2, m + 4, w - 2 * m, h - 2 * m);
  wobblyShape(ctx, pts, rng, 1.2);
  paintPath(ctx, base, rng, { strokes: 60, inkWidth: inkW, texture: 0.08 });
  const p = paperTexture(256, base, seed);
  ctx.save(); ctx.globalCompositeOperation = 'multiply'; ctx.globalAlpha = 0.5;
  wobblyShape(ctx, pts, makeRng(seed), 0); ctx.clip(); ctx.drawImage(p, 0, 0); ctx.restore();
  return c;
}
addCanvas('ui/panel.png', panel(128, 128, '#ecdfc0', 11));
addCanvas('ui/panel_dark.png', panel(128, 128, '#d8c49a', 12));
addCanvas('ui/button.png', panel(96, 48, '#d99a48', 21, 2.2, 3));
addCanvas('ui/button_hover.png', panel(96, 48, '#e8b066', 22, 2.2, 3));
addCanvas('ui/button_pressed.png', panel(96, 48, '#b07432', 23, 2.2, 3));
addCanvas('ui/button_disabled.png', panel(96, 48, '#b8ac98', 24, 2.2, 3));
addCanvas('ui/button_active.png', panel(96, 48, '#a2bd6e', 25, 2.2, 3));
addCanvas('ui/slot.png', panel(80, 80, '#f2e6c8', 31, 2, 3));
{
  const [c, ctx] = canvas(256, 64);
  const rng = makeRng(41);
  const g = ctx.createLinearGradient(0, 0, 0, 64);
  g.addColorStop(0, '#7a5536'); g.addColorStop(0.5, PAL.hideDark); g.addColorStop(1, '#47301f');
  ctx.fillStyle = g; ctx.fillRect(0, 0, 256, 60);
  for (let i = 0; i < 120; i++) { ctx.strokeStyle = rgba(rng() > 0.5 ? '#9a7048' : '#3a2616', 0.25); ctx.lineWidth = 2 + rng() * 4; const x = rng() * 256, y = rng() * 60; ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + 20 + rng() * 30, y + (rng() - 0.5) * 4); ctx.stroke(); }
  ctx.strokeStyle = 'rgba(240,220,180,0.55)'; ctx.setLineDash([7, 6]); ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(0, 52); ctx.lineTo(256, 52); ctx.stroke(); ctx.setLineDash([]);
  ctx.fillStyle = INK; ctx.fillRect(0, 60, 256, 4);
  addCanvas('ui/leather.png', c);
}
{
  const [c, ctx] = canvas(40, 40);
  const rng = makeRng(51);
  blob(ctx, 20, 21, 16, 14, '#efe2c4', rng, true, 6);
  ctx.strokeStyle = '#8a6a40'; ctx.lineWidth = 2;
  for (let i = -1; i <= 1; i++) { ctx.beginPath(); ctx.moveTo(20 + i * 6, 10); ctx.quadraticCurveTo(20 + i * 8, 22, 20 + i * 4, 32); ctx.stroke(); }
  addCanvas('ui/shell.png', c);
}
{
  const s = { img: (() => { const [c, ctx] = canvas(40 * SCALE, 48 * SCALE); ctx.scale(SCALE, SCALE); const rng = makeRng(61); inkLine(ctx, 8, 46, 8, 6, rng, 2, PAL.bark); wobblyShape(ctx, [[8, 6], [34, 12], [8, 20]], rng, 1); paintPath(ctx, '#6a7a8a', rng, { strokes: 4 }); return c; })(), ax: 8, ay: 46, w: 40, h: 48 };
  addSprite('misc/flag_rival.png', s);
}
{
  const [c, ctx] = canvas(48, 48);
  const rng = makeRng(71);
  blob(ctx, 24, 24, 18, 18, '#d9962a', rng, true, 5);
  ctx.fillStyle = '#fff4dc'; ctx.font = 'bold 26px serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('!', 24, 26);
  addCanvas('misc/warning.png', c);
}

} // !ONLY_GOODS

(window as unknown as { BAKED: Out[] }).BAKED = out;
document.title = 'done';
