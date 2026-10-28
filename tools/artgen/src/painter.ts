// Painterly drawing primitives. Everything here aims for a hand-painted gouache look:
// irregular outlines, layered translucent strokes, warm ink lines instead of perfect geometry.

export type Rng = () => number;

export function makeRng(seed: number): Rng {
  let a = seed >>> 0 || 1;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const INK = '#3a2a1e';

export function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace('#', '');
  const n = parseInt(h.length === 3 ? h.split('').map((c) => c + c).join('') : h, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

/** Shift a colour lighter (+) or darker (−) and optionally towards warm/cool. */
export function shade(hex: string, amt: number, warm = 0): string {
  const [r, g, b] = hexToRgb(hex);
  const f = (c: number, w: number) => Math.max(0, Math.min(255, Math.round(c + amt * 255 + w)));
  return `rgb(${f(r, warm * 18)},${f(g, warm * 6)},${f(b, -warm * 14)})`;
}

export function rgba(hex: string, a: number): string {
  const [r, g, b] = hexToRgb(hex);
  return `rgba(${r},${g},${b},${a})`;
}

export function mix(a: string, b: string, t: number): string {
  const [r1, g1, b1] = hexToRgb(a), [r2, g2, b2] = hexToRgb(b);
  const m = (x: number, y: number) => Math.round(x + (y - x) * t);
  return `#${[m(r1, r2), m(g1, g2), m(b1, b2)].map((v) => v.toString(16).padStart(2, '0')).join('')}`;
}

// The last shape built with wobblyShape – paintPath fills, textures and inks it.
let lastBox: [number, number, number, number] = [0, 0, 1, 1];
let lastPath: Path2D = new Path2D();

/** Closed shape through points with jittered, softly curved edges. */
export function wobblyShape(_ctx: CanvasRenderingContext2D, pts: [number, number][], rng: Rng, jitter = 1.5) {
  const p = pts.map(([x, y]) => [x + (rng() - 0.5) * jitter * 2, y + (rng() - 0.5) * jitter * 2] as [number, number]);
  const xs = p.map((q) => q[0]), ys = p.map((q) => q[1]);
  const x0 = Math.min(...xs) - 4, y0 = Math.min(...ys) - 4;
  lastBox = [x0, y0, Math.max(...xs) + 4 - x0, Math.max(...ys) + 4 - y0];
  const path = new Path2D();
  for (let i = 0; i < p.length; i++) {
    const [x0, y0] = p[i];
    const [x1, y1] = p[(i + 1) % p.length];
    const mx = (x0 + x1) / 2 + (rng() - 0.5) * jitter, my = (y0 + y1) / 2 + (rng() - 0.5) * jitter;
    if (i === 0) path.moveTo(x0, y0);
    path.quadraticCurveTo(mx, my, x1, y1);
  }
  path.closePath();
  lastPath = path;
}

/** Fill the last wobbly shape with a base colour plus layered brush strokes, then ink the edge. */
export function paintPath(ctx: CanvasRenderingContext2D, color: string, rng: Rng, opts: { strokes?: number; ink?: boolean; inkWidth?: number; dir?: number; texture?: number } = {}) {
  const path = lastPath;
  ctx.save();
  ctx.fillStyle = color;
  ctx.fill(path);
  ctx.clip(path);
  const [bx, by, bw, bh] = lastBox;
  const n = opts.strokes ?? Math.max(4, Math.min(40, Math.round((bw * bh) / 120)));
  const dir = opts.dir ?? -0.5;
  const tex = opts.texture ?? 0.12;
  for (let i = 0; i < n; i++) {
    const light = (rng() - 0.45) * tex * 2;
    ctx.strokeStyle = shade(cssToHex(color), light, light > 0 ? 0.6 : -0.3);
    ctx.globalAlpha = 0.25 + rng() * 0.35;
    ctx.lineWidth = 1.5 + rng() * 3.5;
    ctx.lineCap = 'round';
    const len = 4 + rng() * Math.min(18, bw * 0.5);
    const x = bx + rng() * bw - len * 0.3, y = by + rng() * bh;
    const a = dir + (rng() - 0.5) * 0.6;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x + Math.cos(a) * len * 0.5 + (rng() - 0.5) * 4, y + Math.sin(a) * len * 0.5 + (rng() - 0.5) * 4, x + Math.cos(a) * len, y + Math.sin(a) * len);
    ctx.stroke();
  }
  ctx.restore();
  if (opts.ink !== false) {
    ctx.save();
    ctx.strokeStyle = INK;
    ctx.globalAlpha = 0.8;
    ctx.lineWidth = opts.inkWidth ?? 1.4;
    ctx.lineJoin = 'round';
    ctx.stroke(path);
    ctx.restore();
  }
}

/** Converts rgb()/#hex to #hex so shade() can work with both. */
export function cssToHex(c: string): string {
  if (c.startsWith('#')) return c;
  const m = c.match(/\d+/g);
  if (!m) return '#888888';
  return `#${m.slice(0, 3).map((v) => (+v).toString(16).padStart(2, '0')).join('')}`;
}

/** A soft painted ellipse (used for canopies, bushes, smoke, clouds). */
export function blob(ctx: CanvasRenderingContext2D, x: number, y: number, rx: number, ry: number, color: string, rng: Rng, ink = true, strokes = 8) {
  const pts: [number, number][] = [];
  const n = 9;
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const r = 0.85 + rng() * 0.3;
    pts.push([x + Math.cos(a) * rx * r, y + Math.sin(a) * ry * r]);
  }
  wobblyShape(ctx, pts, rng, Math.min(rx, ry) * 0.12);
  paintPath(ctx, color, rng, { strokes, ink, inkWidth: 1.1, texture: 0.14 });
}

/** A hand-drawn line with slight wobble. */
export function inkLine(ctx: CanvasRenderingContext2D, x0: number, y0: number, x1: number, y1: number, rng: Rng, width = 1.4, color = INK) {
  ctx.save();
  ctx.strokeStyle = color;
  ctx.lineWidth = width;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(x0, y0);
  ctx.quadraticCurveTo((x0 + x1) / 2 + (rng() - 0.5) * 2, (y0 + y1) / 2 + (rng() - 0.5) * 2, x1, y1);
  ctx.stroke();
  ctx.restore();
}

export function canvas(w: number, h: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement('canvas');
  c.width = Math.ceil(w); c.height = Math.ceil(h);
  return [c, c.getContext('2d')!];
}

/** Paper grain used as a multiply overlay and as UI background. */
export function paperTexture(size = 256, base = '#efe2c4', seed = 7): HTMLCanvasElement {
  const [c, ctx] = canvas(size, size);
  const rng = makeRng(seed);
  ctx.fillStyle = base;
  ctx.fillRect(0, 0, size, size);
  const img = ctx.getImageData(0, 0, size, size);
  for (let i = 0; i < img.data.length; i += 4) {
    const n = (rng() - 0.5) * 22;
    img.data[i] += n; img.data[i + 1] += n; img.data[i + 2] += n * 0.8;
  }
  ctx.putImageData(img, 0, 0);
  // fibres
  for (let i = 0; i < 90; i++) {
    ctx.strokeStyle = rng() > 0.5 ? 'rgba(120,90,50,0.08)' : 'rgba(255,255,255,0.12)';
    ctx.lineWidth = 0.6 + rng();
    const x = rng() * size, y = rng() * size, a = rng() * Math.PI, l = 4 + rng() * 16;
    ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + Math.cos(a) * l, y + Math.sin(a) * l); ctx.stroke();
  }
  return c;
}

/** The path of the last wobblyShape call, for custom fills/clips. */
export const currentPath = () => lastPath;
