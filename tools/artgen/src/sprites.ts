// Procedural painted sprites. Each sprite is a cached canvas with an anchor point.
// These are the *placeholder art*: any sprite can be replaced by an image via public/assets/manifest.json.
import { BUILDING } from './content';
import { INK, blob, canvas, currentPath, inkLine, makeRng, mix, paintPath, rgba, shade, wobblyShape, type Rng } from './painter';
import { PAL } from './palette';
import { TH, TW } from './iso';

export const SCALE = 2; // sprites are painted at 2x for crisp zooming

export interface Sprite { img: CanvasImageSource; ax: number; ay: number; w: number; h: number }

const cache = new Map<string, Sprite>();
export function cached(key: string, make: () => Sprite): Sprite {
  let s = cache.get(key);
  if (!s) { s = make(); cache.set(key, s); }
  return s;
}
export function overrideSprite(key: string, sprite: Sprite) { cache.set(key, sprite); }

function sprite(w: number, h: number, ax: number, ay: number, draw: (ctx: CanvasRenderingContext2D) => void): Sprite {
  const [c, ctx] = canvas(w * SCALE, h * SCALE);
  ctx.scale(SCALE, SCALE);
  draw(ctx);
  return { img: c, ax, ay, w, h };
}

// ---------------------------------------------------------------- nature

export function treeSprite(variant: number): Sprite {
  return cached(`tree.${variant}`, () => sprite(48, 64, 24, 58, (ctx) => {
    const rng = makeRng(1000 + variant * 77);
    // soft contact shadow
    ctx.fillStyle = 'rgba(40,40,20,0.22)';
    ctx.beginPath(); ctx.ellipse(27, 58, 15, 6, 0, 0, Math.PI * 2); ctx.fill();
    if (variant % 3 === 2) {
      // conifer
      ctx.fillStyle = PAL.bark; ctx.fillRect(22.5, 46, 3, 12);
      const green = mix(PAL.pine, PAL.treeDark, rng() * 0.5);
      for (let i = 0; i < 3; i++) {
        const y = 16 + i * 11, wdt = 9 + i * 4.5;
        wobblyShape(ctx, [[24, y - 12], [24 + wdt, y + 12], [24 - wdt, y + 12]], rng, 1.2);
        paintPath(ctx, shade(green, 0.03 * i), rng, { strokes: 10, inkWidth: 1.1, dir: 1.1 });
      }
      blob(ctx, 20, 26, 3, 6, rgba(PAL.treeLight, 0.35), rng, false, 3);
    } else {
      ctx.fillStyle = PAL.bark; ctx.fillRect(22, 38, 4, 20);
      inkLine(ctx, 22, 40, 22, 58, rng, 0.8); inkLine(ctx, 26, 40, 26, 58, rng, 0.8);
      const base = [PAL.tree, mix(PAL.tree, PAL.meadow, 0.3), mix(PAL.tree, '#7a8a3a', 0.4)][variant % 3];
      blob(ctx, 17, 32, 11, 10, shade(base, -0.06), rng);
      blob(ctx, 31, 31, 11, 10, shade(base, -0.1), rng);
      blob(ctx, 24, 22, 14, 12, base, rng);
      blob(ctx, 20, 18, 6, 5, rgba(PAL.treeLight, 0.55), rng, false, 4);
    }
  }));
}

export function bushSprite(variant: number): Sprite {
  return cached(`bush.${variant}`, () => sprite(30, 24, 15, 19, (ctx) => {
    const rng = makeRng(2000 + variant * 31);
    ctx.fillStyle = 'rgba(40,40,20,0.2)';
    ctx.beginPath(); ctx.ellipse(16, 19, 11, 4, 0, 0, Math.PI * 2); ctx.fill();
    blob(ctx, 11, 13, 7, 6, shade(PAL.tree, -0.04), rng);
    blob(ctx, 19, 12, 8, 7, PAL.tree, rng);
    for (let i = 0; i < 7; i++) {
      ctx.fillStyle = i % 3 ? PAL.berry : '#5a1a6a';
      ctx.beginPath(); ctx.arc(7 + rng() * 17, 7 + rng() * 10, 1.4, 0, Math.PI * 2); ctx.fill();
    }
  }));
}

export function rockSprite(variant: number, tint?: string): Sprite {
  return cached(`rock.${variant}.${tint ?? ''}`, () => sprite(28, 20, 14, 16, (ctx) => {
    const rng = makeRng(3000 + variant * 17);
    ctx.fillStyle = 'rgba(40,40,20,0.2)';
    ctx.beginPath(); ctx.ellipse(15, 16, 11, 4, 0, 0, Math.PI * 2); ctx.fill();
    blob(ctx, 12, 12, 8, 5.5, PAL.stone, rng);
    blob(ctx, 19, 13, 6, 4, shade(PAL.stone, -0.08), rng);
    if (tint) for (let i = 0; i < 6; i++) { ctx.fillStyle = tint; ctx.beginPath(); ctx.arc(6 + rng() * 16, 9 + rng() * 6, 1.3, 0, Math.PI * 2); ctx.fill(); }
  }));
}

export function depositSprite(dep: string): Sprite {
  const tint = dep === 'flint' ? '#2d3138' : dep === 'copper' ? '#3f9a7a' : '#d6dde0';
  return cached(`deposit.${dep}`, () => sprite(70, 44, 35, 22, (ctx) => {
    const rng = makeRng(dep.length * 999);
    for (let i = 0; i < 6; i++) {
      const x = 14 + rng() * 42, y = 12 + rng() * 22;
      blob(ctx, x, y, 5 + rng() * 5, 3 + rng() * 3, i % 2 ? PAL.stone : shade(PAL.stone, -0.12), rng);
      for (let k = 0; k < 4; k++) { ctx.fillStyle = tint; ctx.beginPath(); ctx.arc(x + (rng() - 0.5) * 8, y + (rng() - 0.5) * 4, 1.5, 0, Math.PI * 2); ctx.fill(); }
    }
  }));
}

/** Painted mountain peak. Size 0..1 controls height; large peaks get snow. */
export function peakSprite(variant: number, size: number): Sprite {
  const sz = Math.round(size * 4) / 4;
  return cached(`peak.${variant}.${sz}`, () => {
    const w = 80 + sz * 70, h = 50 + sz * 110;
    return sprite(w, h, w / 2, h - 8, (ctx) => {
      const rng = makeRng(4000 + variant * 13 + sz * 100);
      const base = h - 8, cx = w / 2 + (rng() - 0.5) * w * 0.35, top = 6 + rng() * 8;
      const left = 4, right = w - 4;
      const ridge: [number, number][] = [[left, base]];
      const steps = 5;
      const shoulder = rng() > 0.5; // some peaks get a secondary summit
      for (let i = 1; i < steps; i++) {
        const t = i / steps;
        const bump = shoulder && i === 2 ? -(base - top) * 0.18 : 0;
        ridge.push([left + (cx - left) * t, base - (base - top) * Math.pow(t, 0.8) + (rng() - 0.5) * 12 + bump]);
      }
      ridge.push([cx, top]);
      for (let i = 1; i < steps; i++) { const t = i / steps; ridge.push([cx + (right - cx) * t, top + (base - top) * t + (rng() - 0.5) * 10]); }
      ridge.push([right, base]);
      ridge.push([w / 2 + 10, base + 6]);
      ridge.push([w / 2 - 10, base + 6]);
      const rock = mix(PAL.rock, ['#7a6e5c', '#6e6a68', '#857462'][variant % 3], 0.5);
      wobblyShape(ctx, ridge, rng, 2);
      paintPath(ctx, rock, rng, { strokes: 30, dir: 1.2, texture: 0.15, inkWidth: 1.6 });
      // shadow side (light from the upper left)
      ctx.save();
      wobblyShape(ctx, ridge, rng, 0); ctx.clip(currentPath());
      const shadow: [number, number][] = [[cx, top], [cx + 6 + rng() * 8, base * 0.45], [cx - 4 + rng() * 10, base + 10], [right + 4, base + 10], [right + 4, base]];
      wobblyShape(ctx, shadow, rng, 3);
      ctx.fillStyle = rgba(PAL.rockDark, 0.45); ctx.fill(currentPath());
      // lit facets
      for (let i = 0; i < 5; i++) {
        ctx.strokeStyle = rgba(PAL.rockLight, 0.5); ctx.lineWidth = 2 + rng() * 2;
        const sx = cx - rng() * (cx - left) * 0.8, sy = top + (base - top) * (0.2 + rng() * 0.6);
        ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx - 6 - rng() * 10, sy + 10 + rng() * 14); ctx.stroke();
      }
      if (sz >= 0.5) {
        const sh = (base - top) * (0.22 + sz * 0.1);
        const cap: [number, number][] = [[cx, top - 2], [cx + sh * 0.7, top + sh], [cx + sh * 0.3, top + sh * 0.8], [cx, top + sh * 1.1], [cx - sh * 0.35, top + sh * 0.75], [cx - sh * 0.75, top + sh]];
        wobblyShape(ctx, cap, rng, 1.5);
        paintPath(ctx, PAL.snow, rng, { strokes: 6, ink: false, texture: 0.05 });
      }
      ctx.restore();
      wobblyShape(ctx, ridge, rng, 0.5);
      ctx.strokeStyle = INK; ctx.globalAlpha = 0.7; ctx.lineWidth = 1.5; ctx.stroke(currentPath()); ctx.globalAlpha = 1;
    });
  });
}

// ---------------------------------------------------------------- buildings

interface Frame { ctx: CanvasRenderingContext2D; rng: Rng; w: number; h: number; P: (u: number, v: number) => [number, number]; accent: string }

const PAD = 18, TOP = 120;

export function buildingSprite(type: string, owner = 'player'): Sprite {
  const def = BUILDING[type];
  return cached(`building.${type}.${owner === 'player' ? 'p' : 'r'}`, () => {
    const [w, h] = def.size;
    const cw = ((w + h) * TW) / 2 + PAD * 2, ch = TOP + ((w + h) * TH) / 2 + PAD;
    const ox = (h * TW) / 2 + PAD, oy = TOP;
    return sprite(cw, ch, ox, oy, (ctx) => {
      const rng = makeRng(hashStr(type));
      const P = (u: number, v: number): [number, number] => [ox + ((u - v) * TW) / 2, oy + ((u + v) * TH) / 2];
      const f: Frame = { ctx, rng, w, h, P, accent: def.accent };
      groundPatch(f, def.style === 'field' || def.style === 'pasture' ? PAL.earth : PAL.earthLight);
      (STYLES[def.style] ?? STYLES.workshop)(f);
      if (owner !== 'player') flag(f, P(w * 0.15, h * 0.85), '#6a7a8a');
    });
  });
}

function hashStr(s: string) { let h = 2166136261; for (const c of s) h = Math.imul(h ^ c.charCodeAt(0), 16777619); return h >>> 0; }

function groundPatch(f: Frame, color: string) {
  const { ctx, rng, P, w, h } = f;
  const m = 0.08;
  wobblyShape(ctx, [P(m, m), P(w - m, m), P(w - m, h - m), P(m, h - m)], rng, 2.5);
  ctx.globalAlpha = 0.85;
  paintPath(ctx, color, rng, { ink: false, texture: 0.1 });
  ctx.globalAlpha = 1;
}

/** Iso box with optional gable roof. Returns the roof ridge for decoration. */
function box(f: Frame, u0: number, v0: number, u1: number, v1: number, height: number, wall: string, roof: { color: string; h: number; thatch?: boolean } | null) {
  const { ctx, rng, P } = f;
  const up = (p: [number, number], d: number): [number, number] => [p[0], p[1] - d];
  const A = P(u0, v0), B = P(u1, v0), C = P(u1, v1), D = P(u0, v1);
  // walls
  wobblyShape(ctx, [D, C, up(C, height), up(D, height)], rng, 0.8);
  paintPath(ctx, shade(wall, 0.04, 0.3), rng, { dir: -1.4 });
  wobblyShape(ctx, [C, B, up(B, height), up(C, height)], rng, 0.8);
  paintPath(ctx, shade(wall, -0.12, -0.2), rng, { dir: -1.4 });
  // door on the left face
  const dm = (D[0] + C[0]) / 2, dmy = (D[1] + C[1]) / 2;
  wobblyShape(ctx, [[dm - 4, dmy], [dm + 4, dmy + 1], [dm + 4, dmy - height * 0.65], [dm - 4, dmy - height * 0.7]], rng, 0.6);
  paintPath(ctx, '#3a2818', rng, { strokes: 2 });
  if (!roof) {
    wobblyShape(ctx, [up(A, height), up(B, height), up(C, height), up(D, height)], rng, 0.8);
    paintPath(ctx, shade(wall, 0.1), rng);
    return;
  }
  const vm = (v0 + v1) / 2, oh = 0.12;
  const R0 = up(P(u0 - oh, vm), height + roof.h), R1 = up(P(u1 + oh, vm), height + roof.h);
  const eave = (u: number, v: number) => up(P(u, v), height - 3);
  // back slope
  wobblyShape(ctx, [eave(u0 - oh, v0 - oh), eave(u1 + oh, v0 - oh), R1, R0], rng, 1);
  paintPath(ctx, shade(roof.color, -0.14), rng, { dir: 1.3 });
  // gable end
  wobblyShape(ctx, [up(C, height), up(B, height), up(P(u1, vm), height + roof.h - 2)], rng, 0.6);
  paintPath(ctx, shade(wall, -0.18), rng);
  // front slope
  const front: [number, number][] = [eave(u0 - oh, v1 + oh), eave(u1 + oh, v1 + oh), R1, R0];
  wobblyShape(ctx, front, rng, 1.2);
  paintPath(ctx, roof.color, rng, { dir: 1.2, texture: 0.18 });
  if (roof.thatch) {
    for (let i = 0; i < 14; i++) {
      const t = rng();
      const a = lerp2(front[0], front[1], t), b = lerp2(front[3], front[2], t);
      ctx.strokeStyle = rgba(PAL.thatchDark, 0.55); ctx.lineWidth = 0.9;
      ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(a[0] + (b[0] - a[0]) * 0.7, a[1] + (b[1] - a[1]) * 0.7); ctx.stroke();
    }
  }
  inkLine(ctx, R0[0], R0[1], R1[0], R1[1], rng, 1.8);
}

const lerp2 = (a: [number, number], b: [number, number], t: number): [number, number] => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];

function cone(f: Frame, cx: number, cy: number, r: number, height: number, color: string) {
  const { ctx, rng } = f;
  const apex: [number, number] = [cx + (rng() - 0.5) * 2, cy - height];
  const pts: [number, number][] = [[cx - r, cy]];
  for (let i = 1; i < 8; i++) { const a = Math.PI - (i / 8) * Math.PI; pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r * 0.5]); }
  pts.push([cx + r, cy], apex);
  wobblyShape(ctx, pts, rng, 1);
  paintPath(ctx, color, rng, { dir: -1.3, texture: 0.16 });
  // shaded right half
  ctx.save();
  wobblyShape(ctx, [apex, [cx + r + 2, cy], [cx + r * 0.2, cy + r * 0.52], [cx + 2, cy - height * 0.4]], rng, 1);
  ctx.fillStyle = 'rgba(50,30,20,0.22)'; ctx.fill(currentPath());
  ctx.restore();
  // seams
  for (let i = 0; i < 3; i++) inkLine(ctx, apex[0], apex[1] + 4, cx - r * 0.6 + i * r * 0.6, cy + 2 + (i === 1 ? r * 0.45 : r * 0.25), rng, 0.6, rgba(INK, 0.5));
  // poles
  for (const dx of [-5, 0, 5]) inkLine(ctx, apex[0], apex[1] + 2, apex[0] + dx, apex[1] - 9, rng, 1.6, PAL.bark);
  // entrance
  wobblyShape(ctx, [[cx - r * 0.35, cy + r * 0.38], [cx + r * 0.05, cy + r * 0.48], [cx - r * 0.12, cy - height * 0.35]], rng, 0.5);
  paintPath(ctx, '#3a2818', rng, { strokes: 2 });
}

function dome(f: Frame, cx: number, cy: number, r: number, height: number, color: string, ring = true) {
  const { ctx, rng } = f;
  const pts: [number, number][] = [];
  for (let i = 0; i <= 10; i++) { const a = Math.PI + (i / 10) * Math.PI; pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * height]); }
  for (let i = 1; i < 8; i++) { const a = (i / 8) * Math.PI; pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r * 0.45]); }
  wobblyShape(ctx, pts, rng, 1);
  paintPath(ctx, color, rng, { dir: 0, texture: 0.18 });
  if (ring) for (let i = 1; i < 4; i++) {
    const yy = cy - height * (i / 4);
    const rr = r * Math.sqrt(1 - (i / 4) ** 2);
    ctx.strokeStyle = rgba(INK, 0.35); ctx.lineWidth = 0.8;
    ctx.beginPath(); ctx.ellipse(cx, yy, rr, rr * 0.3, 0, 0.1, Math.PI - 0.1); ctx.stroke();
  }
  ctx.save();
  ctx.beginPath(); ctx.ellipse(cx + r * 0.45, cy - height * 0.3, r * 0.55, height * 0.8, 0, 0, Math.PI * 2);
  ctx.fillStyle = 'rgba(50,30,20,0.16)'; ctx.fill();
  ctx.restore();
}

function poles(f: Frame, pts: [number, number][], height: number) {
  for (const [x, y] of pts) inkLine(f.ctx, x, y, x + (f.rng() - 0.5) * 2, y - height, f.rng, 2.2, PAL.bark);
}

function leanTo(f: Frame, u0: number, v0: number, u1: number, v1: number, height: number, color: string) {
  const { ctx, rng, P } = f;
  const up = (p: [number, number], d: number): [number, number] => [p[0], p[1] - d];
  poles(f, [P(u0, v1), P(u1, v1)], height * 0.55);
  poles(f, [P(u1, v0)], height);
  wobblyShape(ctx, [up(P(u0, v0), height), up(P(u1, v0), height), up(P(u1, v1), height * 0.55), up(P(u0, v1), height * 0.55)], rng, 1.2);
  paintPath(ctx, color, rng, { dir: 1.1, texture: 0.2 });
}

function logs(f: Frame, x: number, y: number, n = 4) {
  for (let i = 0; i < n; i++) {
    const yy = y - (i % 2) * 3 - Math.floor(i / 2) * 3, xx = x + (i % 2) * 6 - 3;
    blob(f.ctx, xx, yy, 7, 2.6, PAL.wood, f.rng, true, 3);
    f.ctx.fillStyle = PAL.earthLight; f.ctx.beginPath(); f.ctx.arc(xx + 6, yy, 1.8, 0, Math.PI * 2); f.ctx.fill();
  }
}

function basket(f: Frame, x: number, y: number, fill: string) {
  blob(f.ctx, x, y, 6, 4.5, PAL.thatchDark, f.rng, true, 4);
  blob(f.ctx, x, y - 3, 5, 2.4, fill, f.rng, false, 3);
}

function pot(f: Frame, x: number, y: number, color = PAL.clay) {
  blob(f.ctx, x, y, 4.5, 5.5, color, f.rng, true, 3);
  f.ctx.fillStyle = '#3a2818'; f.ctx.beginPath(); f.ctx.ellipse(x, y - 5, 2.4, 1, 0, 0, Math.PI * 2); f.ctx.fill();
}

function flag(f: Frame, [x, y]: [number, number], color: string) {
  inkLine(f.ctx, x, y, x, y - 34, f.rng, 1.6, PAL.bark);
  wobblyShape(f.ctx, [[x, y - 34], [x + 14, y - 30], [x, y - 25]], f.rng, 0.8);
  paintPath(f.ctx, color, f.rng, { strokes: 3 });
}

function stones(f: Frame, cx: number, cy: number, rx: number, n: number, tall = 4) {
  const items: [number, number][] = [];
  for (let i = 0; i < n; i++) { const a = (i / n) * Math.PI * 2; items.push([cx + Math.cos(a) * rx, cy + Math.sin(a) * rx * 0.5]); }
  items.sort((a, b) => a[1] - b[1]);
  for (const [x, y] of items) {
    if (tall > 6) {
      wobblyShape(f.ctx, [[x - 3.5, y], [x + 3.5, y + 1], [x + 3, y - tall], [x - 2.5, y - tall - 1]], f.rng, 0.8);
      paintPath(f.ctx, PAL.stone, f.rng, { dir: -1.4 });
    } else blob(f.ctx, x, y, 3.2, 2.4, PAL.stone, f.rng, true, 3);
  }
}

function person(f: Frame, x: number, y: number, color: string) {
  const { ctx } = f;
  ctx.fillStyle = color; ctx.strokeStyle = INK; ctx.lineWidth = 0.8;
  ctx.beginPath(); ctx.moveTo(x - 2.5, y); ctx.lineTo(x + 2.5, y); ctx.lineTo(x + 1.5, y - 7); ctx.lineTo(x - 1.5, y - 7); ctx.closePath(); ctx.fill(); ctx.stroke();
  ctx.fillStyle = '#c99a72'; ctx.beginPath(); ctx.arc(x, y - 9, 2, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
}

const STYLES: Record<string, (f: Frame) => void> = {
  tent: (f) => {
    const [cx, cy] = f.P(1, 1.15);
    cone(f, cx, cy + 4, 20, 46, PAL.hide);
    basket(f, cx + 24, cy + 6, PAL.berry);
  },
  hut: (f) => {
    const [cx, cy] = f.P(1, 1.1);
    dome(f, cx, cy + 6, 24, 34, mix(PAL.bark, PAL.hideDark, 0.4));
    logs(f, cx + 26, cy + 8, 3);
    for (let i = 0; i < 3; i++) inkLine(f.ctx, cx - 4 + i * 4, cy - 26, cx - 6 + i * 6, cy - 34, f.rng, 1.4, PAL.bark);
  },
  cottage: (f) => {
    box(f, 0.35, 0.4, 1.7, 1.6, 20, PAL.clay, { color: PAL.thatch, h: 22, thatch: true });
    pot(f, f.P(1.85, 1.6)[0], f.P(1.85, 1.6)[1]);
  },
  longhouse: (f) => {
    box(f, 0.15, 0.55, 1.9, 1.5, 18, mix(PAL.clay, PAL.wood, 0.4), { color: shade(PAL.thatch, -0.04), h: 26, thatch: true });
  },
  farmstead: (f) => {
    box(f, 0.2, 0.25, 1.35, 1.25, 20, PAL.clay, { color: PAL.thatch, h: 22, thatch: true });
    box(f, 1.35, 1.3, 1.95, 1.9, 12, PAL.wood, { color: PAL.thatchDark, h: 12, thatch: true });
    const [x, y] = f.P(0.3, 1.8); pot(f, x + 8, y - 2, PAL.clay);
  },
  storage: (f) => {
    const { P } = f;
    leanTo(f, 0.5, 0.4, 2.4, 1.6, 34, PAL.hide);
    logs(f, P(0.8, 2.2)[0], P(0.8, 2.2)[1], 6);
    basket(f, P(2.2, 2.0)[0], P(2.2, 2.0)[1], PAL.berry);
    basket(f, P(2.6, 2.4)[0], P(2.6, 2.4)[1], '#c9a24a');
    pot(f, P(1.7, 2.5)[0], P(1.7, 2.5)[1]);
    pot(f, P(2.0, 2.7)[0], P(2.0, 2.7)[1], shade(PAL.clay, -0.1));
    const [fx, fy] = P(0.2, 0.3); flag(f, [fx + 30, fy + 8], f.accent);
    person(f, P(1.4, 2.4)[0], P(1.4, 2.4)[1], PAL.hideDark);
  },
  fire: (f) => {
    const [cx, cy] = f.P(1, 1);
    stones(f, cx, cy + 2, 13, 9);
    logs(f, cx, cy + 2, 3);
    f.ctx.fillStyle = 'rgba(255,170,60,0.25)'; f.ctx.beginPath(); f.ctx.ellipse(cx, cy + 2, 22, 10, 0, 0, Math.PI * 2); f.ctx.fill();
    for (const [dx, dy] of [[-22, 6], [20, 4], [0, 14]]) blob(f.ctx, cx + dx, cy + dy, 6, 3, PAL.wood, f.rng, true, 3);
  },
  workshop: (f) => {
    box(f, 0.25, 0.25, 1.25, 1.25, 16, PAL.wood, { color: PAL.thatch, h: 16, thatch: true });
    leanTo(f, 1.25, 0.3, 1.9, 1.3, 18, PAL.hideDark);
    const [x, y] = f.P(1.5, 1.7);
    if (f.accent === '#8a5a32') logs(f, x, y, 6);
    else for (let i = 0; i < 4; i++) blob(f.ctx, x + (i % 2) * 8 - 4, y - Math.floor(i / 2) * 4, 4, 3, f.accent, f.rng, true, 3);
  },
  basket: (f) => {
    leanTo(f, 0.2, 0.3, 1.3, 1.2, 26, PAL.thatch);
    const [x, y] = f.P(1.5, 1.6);
    basket(f, x - 8, y, f.accent); basket(f, x + 6, y + 3, f.accent); basket(f, x - 1, y + 8, f.accent);
    person(f, f.P(0.8, 1.6)[0], f.P(0.8, 1.6)[1], PAL.hideDark);
  },
  lean: (f) => {
    leanTo(f, 0.2, 0.3, 1.4, 1.3, 28, PAL.hideDark);
    const [x, y] = f.P(1.55, 1.2);
    inkLine(f.ctx, x - 10, y, x - 10, y - 22, f.rng, 2, PAL.bark); inkLine(f.ctx, x + 10, y + 5, x + 10, y - 17, f.rng, 2, PAL.bark);
    inkLine(f.ctx, x - 12, y - 20, x + 12, y - 15, f.rng, 2, PAL.bark);
    blob(f.ctx, x - 3, y - 12, 4, 6, f.accent, f.rng, true, 3); blob(f.ctx, x + 5, y - 10, 4, 6, f.accent, f.rng, true, 3);
    const [bx, by] = f.P(0.4, 1.7);
    inkLine(f.ctx, bx, by, bx + 14, by - 22, f.rng, 1.2, PAL.bark); // bow / spear
  },
  rack: (f) => {
    box(f, 0.2, 0.2, 1.1, 1.1, 14, PAL.wood, { color: PAL.thatch, h: 14, thatch: true });
    const [x, y] = f.P(1.5, 1.4);
    for (let i = 0; i < 2; i++) {
      const xx = x - 8 + i * 16, yy = y + i * 6;
      inkLine(f.ctx, xx - 9, yy, xx - 9, yy - 24, f.rng, 1.8, PAL.bark); inkLine(f.ctx, xx + 9, yy, xx + 9, yy - 24, f.rng, 1.8, PAL.bark);
      wobblyShape(f.ctx, [[xx - 8, yy - 22], [xx + 8, yy - 22], [xx + 7, yy - 6], [xx - 7, yy - 6]], f.rng, 1);
      paintPath(f.ctx, f.accent, f.rng, { strokes: 6 });
    }
  },
  totem: (f) => {
    const [cx, cy] = f.P(1, 1);
    stones(f, cx, cy + 4, 20, 8);
    const cols = [f.accent, PAL.clay, '#2f4a5a', PAL.fire];
    for (let i = 0; i < 4; i++) {
      const y = cy - i * 13;
      wobblyShape(f.ctx, [[cx - 6, y], [cx + 6, y], [cx + 5.5, y - 13], [cx - 5.5, y - 13]], f.rng, 0.6);
      paintPath(f.ctx, cols[i], f.rng, { strokes: 4 });
      f.ctx.fillStyle = PAL.snow; f.ctx.fillRect(cx - 3, y - 9, 2, 2); f.ctx.fillRect(cx + 1.5, y - 9, 2, 2);
    }
    wobblyShape(f.ctx, [[cx - 16, cy - 50], [cx, cy - 46], [cx + 16, cy - 50], [cx + 6, cy - 54], [cx - 6, cy - 54]], f.rng, 1);
    paintPath(f.ctx, PAL.snow, f.rng, { strokes: 3 });
  },
  cave: (f) => {
    const { ctx, rng, P } = f;
    const [x0, y0] = P(0, 0), [x1, y1] = P(2, 0.6), [x2, y2] = P(0, 1.6);
    wobblyShape(ctx, [[x2 - 4, y2], [x0 - 10, y0 - 30], [x0 + 6, y0 - 56], [x1 + 4, y1 - 40], [x1 + 10, y1 + 6], [(x1 + x2) / 2, (y1 + y2) / 2 + 10]], rng, 3);
    paintPath(ctx, PAL.rock, rng, { dir: 1.2, texture: 0.18 });
    const [mx, my] = P(1, 1);
    wobblyShape(ctx, [[mx - 14, my], [mx + 12, my + 2], [mx + 8, my - 20], [mx - 2, my - 26], [mx - 12, my - 18]], rng, 1.2);
    paintPath(ctx, '#2a1e18', rng, { strokes: 4 });
    for (let i = 0; i < 4; i++) { ctx.fillStyle = rgba(f.accent, 0.9); ctx.beginPath(); ctx.arc(mx - 22 + i * 4, my - 30 + (i % 2) * 6, 2.3, 0, Math.PI * 2); ctx.fill(); }
    ctx.strokeStyle = f.accent; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(mx + 14, my - 28); ctx.lineTo(mx + 24, my - 32); ctx.lineTo(mx + 20, my - 24); ctx.stroke();
  },
  pit: (f) => {
    const [cx, cy] = f.P(1, 1);
    blob(f.ctx, cx, cy + 2, 22, 10, '#4a3626', f.rng, true, 6);
    blob(f.ctx, cx - 2, cy, 15, 6, '#2e2218', f.rng, false, 3);
    for (let i = 0; i < 5; i++) blob(f.ctx, cx + 18 + (i % 2) * 6, cy + 10 - i * 3, 4.5, 3.2, f.accent, f.rng, true, 3);
    inkLine(f.ctx, cx - 10, cy + 2, cx - 18, cy - 18, f.rng, 1.6, PAL.bark);
    inkLine(f.ctx, cx - 6, cy + 2, cx - 14, cy - 18, f.rng, 1.6, PAL.bark);
    person(f, cx - 26, cy + 14, PAL.hideDark);
  },
  scout: (f) => {
    const [cx, cy] = f.P(0.9, 1.2);
    cone(f, cx, cy + 4, 15, 34, mix(PAL.hide, f.accent, 0.25));
    flag(f, f.P(1.6, 0.6), f.accent);
    const [x, y] = f.P(1.6, 1.7); logs(f, x, y, 2);
  },
  fisher: (f) => {
    box(f, 0.2, 0.2, 1.1, 1.1, 14, PAL.wood, { color: PAL.thatch, h: 16, thatch: true });
    const [x, y] = f.P(1.5, 1.3);
    inkLine(f.ctx, x - 12, y - 18, x + 12, y - 12, f.rng, 1.8, PAL.bark);
    for (let i = 0; i < 4; i++) blob(f.ctx, x - 8 + i * 6, y - 10 + i * 1.5, 1.8, 4.5, f.accent, f.rng, true, 2);
    const [cx, cy] = f.P(1.1, 1.85);
    wobblyShape(f.ctx, [[cx - 18, cy - 2], [cx + 18, cy + 4], [cx + 14, cy + 8], [cx - 14, cy + 4]], f.rng, 1);
    paintPath(f.ctx, PAL.wood, f.rng, { strokes: 4 });
  },
  kiln: (f) => {
    box(f, 0.15, 0.2, 1.0, 1.1, 14, PAL.wood, { color: PAL.thatch, h: 14, thatch: true });
    const [cx, cy] = f.P(1.45, 1.45);
    dome(f, cx, cy, 14, 18, shade(PAL.clay, -0.05), false);
    blob(f.ctx, cx - 4, cy - 2, 4, 4, '#2a1a10', f.rng, false, 2);
    f.ctx.fillStyle = 'rgba(255,140,40,0.7)'; f.ctx.beginPath(); f.ctx.arc(cx - 4, cy - 1, 2.2, 0, Math.PI * 2); f.ctx.fill();
    pot(f, cx + 18, cy + 4, f.accent); pot(f, cx + 12, cy + 9, shade(f.accent, -0.1));
  },
  dance: (f) => {
    const [cx, cy] = f.P(1, 1);
    for (let i = 0; i < 6; i++) { const a = (i / 6) * Math.PI * 2; const x = cx + Math.cos(a) * 22, y = cy + Math.sin(a) * 11; inkLine(f.ctx, x, y + 2, x, y - 20, f.rng, 2, PAL.bark); f.ctx.fillStyle = f.accent; f.ctx.fillRect(x - 1.5, y - 20, 3, 6); }
    logs(f, cx, cy + 2, 2);
    for (let i = 0; i < 3; i++) person(f, cx - 10 + i * 10, cy + 10 - (i % 2) * 14, [f.accent, PAL.hideDark, '#4a6a7a'][i]);
  },
  field: (f) => {
    const { ctx, P, w, h, rng } = f;
    for (let i = 1; i < w * 4; i++) {
      const a = P(i / 4, 0.15), b = P(i / 4, h - 0.15);
      ctx.strokeStyle = rgba('#5a3a20', 0.45); ctx.lineWidth = 1.6;
      ctx.beginPath(); ctx.moveTo(a[0], a[1]); ctx.lineTo(b[0], b[1]); ctx.stroke();
      for (let k = 0; k < h * 3; k++) {
        const t = 0.08 + (k / (h * 3)) * 0.84;
        const x = a[0] + (b[0] - a[0]) * t, y = a[1] + (b[1] - a[1]) * t;
        ctx.strokeStyle = f.accent; ctx.lineWidth = 1.2;
        ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x - 1 + rng() * 2, y - 6 - rng() * 4); ctx.stroke();
      }
    }
    fence(f);
  },
  pasture: (f) => {
    const { P, w, h } = f;
    fence(f);
    const animal = f.accent === '#e8e0d0' ? '#eee8da' : '#6a4a2e';
    for (let i = 0; i < 5; i++) {
      const [x, y] = P(0.6 + ((i * 1.7) % (w - 1)), 0.6 + ((i * 1.3) % (h - 1)));
      blob(f.ctx, x, y - 4, 7, 4.5, animal, f.rng, true, 4);
      blob(f.ctx, x + 7, y - 7, 2.6, 2.2, shade(animal, -0.3), f.rng, true, 2);
    }
    box(f, w - 0.9, 0.1, w - 0.1, 0.9, 12, PAL.wood, { color: PAL.thatchDark, h: 10, thatch: true });
  },
  stonecircle: (f) => {
    const [cx, cy] = f.P(1.5, 1.5);
    stones(f, cx, cy, 42, 12, 22);
    const [x, y] = [cx, cy]; wobblyShape(f.ctx, [[x - 6, y + 2], [x + 6, y + 3], [x + 5, y - 30], [x - 5, y - 32]], f.rng, 1);
    paintPath(f.ctx, shade(PAL.stone, 0.05), f.rng);
  },
  square: (f) => {
    const [cx, cy] = f.P(1.5, 1.5);
    blob(f.ctx, cx, cy + 4, 34, 15, PAL.grassLight, f.rng, false, 8);
    stones(f, cx, cy + 4, 30, 8);
    const t = treeSprite(0);
    f.ctx.drawImage(t.img as CanvasImageSource, cx - t.ax * 1.3, cy - t.ay * 1.3, t.w * 1.3, t.h * 1.3);
    pot(f, cx + 22, cy + 10); basket(f, cx - 26, cy + 8, '#c9a24a');
  },
};

function fence(f: Frame) {
  const { ctx, P, w, h, rng } = f;
  const ring: [number, number][] = [P(0.1, 0.1), P(w - 0.1, 0.1), P(w - 0.1, h - 0.1), P(0.1, h - 0.1), P(0.1, 0.1)];
  ctx.strokeStyle = PAL.bark; ctx.lineWidth = 1.5;
  ctx.beginPath(); ring.forEach(([x, y], i) => (i ? ctx.lineTo(x, y - 5) : ctx.moveTo(x, y - 5))); ctx.stroke();
  for (let i = 0; i < 4; i++) {
    const a = ring[i], b = ring[i + 1];
    for (let k = 0; k <= 4; k++) { const x = a[0] + (b[0] - a[0]) * (k / 4), y = a[1] + (b[1] - a[1]) * (k / 4); inkLine(ctx, x, y, x, y - 8, rng, 1.4, PAL.bark); }
  }
}

// ---------------------------------------------------------------- walkers & goods

export function walkerSprite(color: string, load?: string): Sprite {
  return cached(`walker.${color}.${load ?? ''}`, () => sprite(14, 22, 7, 20, (ctx) => {
    const rng = makeRng(7);
    ctx.fillStyle = 'rgba(30,30,20,0.25)'; ctx.beginPath(); ctx.ellipse(7, 20, 4, 1.6, 0, 0, Math.PI * 2); ctx.fill();
    person({ ctx, rng } as Frame, 7, 19, color);
    if (load) blob(ctx, 10, 9, 3.5, 3, load, rng, true, 2);
  }));
}

/** Round clay token with a painted glyph – the placeholder icon for every good. */
export function goodIcon(color: string, glyph: string, size = 40): HTMLCanvasElement {
  const [c, ctx] = canvas(size, size);
  const rng = makeRng(hashStr(glyph + color));
  const s = size / 40;
  ctx.scale(s, s);
  blob(ctx, 20, 21, 17, 16, '#e8d6b0', rng, true, 6);
  ctx.save();
  ctx.translate(20, 21);
  const g = GLYPHS[glyph] ?? GLYPHS.lump;
  g(ctx, color, rng);
  ctx.restore();
  return c;
}

const GLYPHS: Record<string, (ctx: CanvasRenderingContext2D, c: string, rng: Rng) => void> = {
  log: (ctx, c, r) => { blob(ctx, -2, 2, 11, 4.5, c, r, true, 4); ctx.fillStyle = PAL.earthLight; ctx.beginPath(); ctx.ellipse(9, 2, 3, 4, 0, 0, 7); ctx.fill(); ctx.stroke(); },
  berries: (ctx, c, r) => { for (const [x, y] of [[-5, 2], [4, 3], [0, -4], [-1, 6], [6, -3]]) blob(ctx, x, y, 4, 4, c, r, true, 2); blob(ctx, 2, -9, 4, 2, PAL.tree, r, true, 2); },
  nut: (ctx, c, r) => { blob(ctx, -4, 2, 6, 7, c, r, true, 3); blob(ctx, 5, 3, 5, 6, shade(c, -0.08), r, true, 3); },
  hide: (ctx, c, r) => { wobblyShape(ctx, [[-11, -8], [-4, -10], [4, -10], [11, -8], [8, 0], [11, 9], [0, 7], [-11, 9], [-8, 0]], r, 1); paintPath(ctx, c, r, { strokes: 5 }); },
  meat: (ctx, c, r) => { blob(ctx, -2, 0, 10, 7, c, r, true, 4); ctx.fillStyle = '#f0e8d8'; ctx.beginPath(); ctx.ellipse(9, 4, 3, 2.5, 0, 0, 7); ctx.fill(); ctx.stroke(); },
  cloth: (ctx, c, r) => { wobblyShape(ctx, [[-9, -10], [-3, -7], [3, -7], [9, -10], [12, -2], [7, 0], [7, 10], [-7, 10], [-7, 0], [-12, -2]], r, 0.8); paintPath(ctx, c, r, { strokes: 5 }); },
  stone: (ctx, c, r) => { blob(ctx, -3, 2, 8, 7, c, r, true, 4); blob(ctx, 6, 4, 5, 4, shade(c, 0.1), r, true, 3); },
  fish: (ctx, c, r) => { wobblyShape(ctx, [[-11, 0], [-3, -6], [6, -4], [12, -7], [10, 0], [12, 7], [6, 4], [-3, 6]], r, 0.6); paintPath(ctx, c, r, { strokes: 4 }); ctx.fillStyle = INK; ctx.beginPath(); ctx.arc(-6, -1, 1.2, 0, 7); ctx.fill(); },
  axe: (ctx, c, r) => { inkLine(ctx, -8, 10, 6, -8, r, 2.6, PAL.bark); wobblyShape(ctx, [[0, -12], [11, -9], [9, -1], [3, -4]], r, 0.6); paintPath(ctx, c, r, { strokes: 3 }); },
  lump: (ctx, c, r) => { blob(ctx, 0, 1, 10, 8, c, r, true, 4); },
  pot: (ctx, c, r) => { blob(ctx, 0, 3, 9, 8, c, r, true, 4); ctx.fillStyle = shade(c, -0.25); ctx.fillRect(-4, -9, 8, 5); ctx.strokeRect(-4, -9, 8, 5); },
  drop: (ctx, c, r) => { wobblyShape(ctx, [[0, -11], [7, 0], [6, 7], [0, 10], [-6, 7], [-7, 0]], r, 0.6); paintPath(ctx, c, r, { strokes: 4 }); },
  grain: (ctx, c, r) => { for (let i = -1; i <= 1; i++) { inkLine(ctx, i * 4, 11, i * 5, -6, r, 1.2, shade(c, -0.25)); for (let k = 0; k < 4; k++) blob(ctx, i * 5 + 1.5, -8 + k * 3.5, 1.8, 2.5, c, r, true, 1); } },
  bowl: (ctx, c, r) => { wobblyShape(ctx, [[-11, -2], [11, -2], [7, 8], [-7, 8]], r, 0.6); paintPath(ctx, PAL.clay, r, { strokes: 3 }); blob(ctx, 0, -3, 10, 3, c, r, true, 2); },
  bar: (ctx, c, r) => { wobblyShape(ctx, [[-10, 2], [-4, -6], [10, -6], [4, 2]], r, 0.5); paintPath(ctx, c, r, { strokes: 3 }); wobblyShape(ctx, [[-10, 2], [4, 2], [4, 7], [-10, 7]], r, 0.5); paintPath(ctx, shade(c, -0.15), r, { strokes: 2 }); },
  ring: (ctx, c) => { ctx.lineWidth = 3.5; ctx.strokeStyle = c; ctx.beginPath(); ctx.ellipse(0, 1, 9, 7, 0, 0, 7); ctx.stroke(); ctx.lineWidth = 1; ctx.strokeStyle = INK; ctx.beginPath(); ctx.ellipse(0, 1, 11, 9, 0, 0, 7); ctx.stroke(); },
  bread: (ctx, c, r) => { blob(ctx, 0, 1, 11, 7, c, r, true, 4); for (let i = -1; i <= 1; i++) inkLine(ctx, i * 5 - 2, -2, i * 5 + 2, 3, r, 1, shade(c, -0.3)); },
  leaf: (ctx, c, r) => { wobblyShape(ctx, [[-10, 8], [-6, -4], [4, -10], [10, -10], [8, 0], [0, 8]], r, 0.6); paintPath(ctx, c, r, { strokes: 4 }); inkLine(ctx, -10, 8, 8, -8, r, 0.8); },
  wheel: (ctx, c) => { ctx.strokeStyle = c; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(0, 0, 10, 0, 7); ctx.stroke(); for (let i = 0; i < 4; i++) { const a = (i / 4) * Math.PI; ctx.beginPath(); ctx.moveTo(Math.cos(a) * 10, Math.sin(a) * 10); ctx.lineTo(-Math.cos(a) * 10, -Math.sin(a) * 10); ctx.stroke(); } ctx.lineWidth = 1; ctx.strokeStyle = INK; ctx.beginPath(); ctx.arc(0, 0, 11.5, 0, 7); ctx.stroke(); },
};
