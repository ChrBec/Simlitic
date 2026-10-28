// Isometric projection helpers. Tile (x, y) has its top vertex at iso(x, y).
export const TW = 64;
export const TH = 32;

export const iso = (x: number, y: number): [number, number] => [(x - y) * (TW / 2), (x + y) * (TH / 2)];

/** Inverse projection: world pixel -> fractional tile coordinates. */
export const unIso = (px: number, py: number): [number, number] => {
  const a = px / (TW / 2), b = py / (TH / 2);
  return [(a + b) / 2, (b - a) / 2];
};

export interface Camera { x: number; y: number; zoom: number }
