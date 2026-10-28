class_name SimNoise
## Stateless hash noise for map generation and render variation (deterministic per seed).


static func imul(a: int, b: int) -> int:
	a &= 0xFFFFFFFF
	b &= 0xFFFFFFFF
	return (((a & 0xFFFF) * b) + ((((a >> 16) * b) & 0xFFFF) << 16)) & 0xFFFFFFFF


static func hash2(x: int, y: int, seed: int) -> float:
	var h := (imul(x, 374761393) + imul(y, 668265263) + imul(seed, 1442695041)) & 0xFFFFFFFF
	h = imul(h ^ (h >> 13), 1274126177)
	h ^= h >> 16
	return float(h & 0xFFFFFFFF) / 4294967296.0


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


static func value(x: float, y: float, seed: int) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var xf := _smooth(x - xi)
	var yf := _smooth(y - yi)
	var a := hash2(xi, yi, seed)
	var b := hash2(xi + 1, yi, seed)
	var c := hash2(xi, yi + 1, seed)
	var d := hash2(xi + 1, yi + 1, seed)
	var top := a + (b - a) * xf
	var bottom := c + (d - c) * xf
	return top + (bottom - top) * yf


## Fractal noise in [0, 1].
static func fbm(x: float, y: float, seed: int, octaves := 4) -> float:
	var sum := 0.0
	var amp := 0.5
	var freq := 1.0
	var norm := 0.0
	for i in octaves:
		sum += value(x * freq, y * freq, seed + i * 97) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return sum / norm
