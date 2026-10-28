class_name MapGen
## Procedural map: valleys carved out of a mountain massif, connected by passes.

const SIZE := 252
## Distance of each ring of valleys from the map centre.
const RINGS := [0.0, 62.0, 98.0]
const BASE_RADIUS := 16.5


## Fills the tile arrays of `w` and returns valley centres + passes.
static func generate(w: World, seed: int) -> void:
	var n := SIZE * SIZE
	w.size = SIZE
	w.terrain.resize(n); w.terrain.fill(World.MOUNTAIN)
	w.valley.resize(n); w.valley.fill(-1)
	w.nature.resize(n); w.nature.fill(World.N_NONE)
	w.road.resize(n); w.road.fill(0)
	w.bmap.resize(n); w.bmap.fill(0)
	w.pass_of.resize(n); w.pass_of.fill(-1)
	w.deposit = {}

	var rot := SimNoise.hash2(1, 2, seed) * TAU
	var centers := []
	for i in Content.valleys.size():
		var def: Dictionary = Content.valleys[i]
		var ring := int(def.get("ring", 1))
		var a := rot + deg_to_rad(float(def.get("angle", 0))) + (SimNoise.hash2(i, 9, seed) - 0.5) * 0.18
		var dist: float = RINGS[ring] + (SimNoise.hash2(i, 11, seed) - 0.5) * 6.0
		var c := {"cx": SIZE / 2.0 + cos(a) * dist, "cy": SIZE / 2.0 + sin(a) * dist}
		c.r = BASE_RADIUS * float(def.size)
		c.def = def
		centers.append(c)

	# Carve valleys: noisy distance field, nearest valley wins.
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var best := -1
			var best_d := 1e9
			var nz := (SimNoise.fbm(x * 0.09, y * 0.09, seed + 17) - 0.5) * 0.7
			for i in centers.size():
				var c: Dictionary = centers[i]
				var ddx: float = x - c.cx
				var ddy: float = y - c.cy
				if absf(ddx) > c.r * 1.4 or absf(ddy) > c.r * 1.4:
					continue
				var d: float = sqrt(ddx * ddx + ddy * ddy) / c.r + nz
				if d < 1.0 and d < best_d:
					best_d = d
					best = i
			if best >= 0:
				var idx := y * SIZE + x
				w.terrain[idx] = World.GRASS
				w.valley[idx] = best

	# Water: lakes and streams.
	for i in centers.size():
		var c: Dictionary = centers[i]
		var ang := SimNoise.hash2(i, 21, seed) * TAU
		if c.def.water == "lake":
			var lx: float = c.cx + cos(ang) * c.r * 0.45
			var ly: float = c.cy + sin(ang) * c.r * 0.45
			var lr: float = c.r * 0.26
			for y in range(floori(ly - lr - 2), ceili(ly + lr + 3)):
				for x in range(floori(lx - lr - 2), ceili(lx + lr + 3)):
					if not w.inside(x, y) or w.valley[y * SIZE + x] != i:
						continue
					var d := Vector2(x - lx, y - ly).length() / lr + (SimNoise.fbm(x * 0.3, y * 0.3, seed + 31) - 0.5) * 0.6
					if d < 1.0:
						w.terrain[y * SIZE + x] = World.WATER
		elif c.def.water == "stream":
			var x: float = c.cx + cos(ang) * c.r * 1.05
			var y: float = c.cy + sin(ang) * c.r * 1.05
			var tx: float = c.cx + cos(ang) * c.r * 0.3
			var ty: float = c.cy + sin(ang) * c.r * 0.3
			for s in 200:
				var dx := tx - x
				var dy := ty - y
				var d := sqrt(dx * dx + dy * dy)
				if d < 1.0:
					break
				var wob := (SimNoise.fbm(s * 0.15, i, seed + 41) - 0.5) * 1.6
				x += dx / d * 0.5 - dy / d * wob * 0.5
				y += dy / d * 0.5 + dx / d * wob * 0.5
				var ix := roundi(x)
				var iy := roundi(y)
				if w.inside(ix, iy) and w.valley[iy * SIZE + ix] == i:
					w.terrain[iy * SIZE + ix] = World.WATER
			for yy in range(-2, 3):
				for xx in range(-2, 3):
					if xx * xx + yy * yy > 5:
						continue
					var ix := roundi(tx) + xx
					var iy := roundi(ty) + yy
					if w.inside(ix, iy) and w.valley[iy * SIZE + ix] == i:
						w.terrain[iy * SIZE + ix] = World.WATER

	# Nature: forests everywhere, berry bushes only in berry valleys; keep each valley's heart open.
	for y in SIZE:
		for x in SIZE:
			var idx := y * SIZE + x
			if w.terrain[idx] != World.GRASS:
				continue
			var c: Dictionary = centers[w.valley[idx]]
			if Vector2(x - c.cx, y - c.cy).length() < 4.5:
				continue
			if SimNoise.fbm(x * 0.09, y * 0.09, seed + 51) > 0.53:
				w.nature[idx] = World.N_TREE
			elif "berries" in c.def.fertilities and SimNoise.fbm(x * 0.2, y * 0.2, seed + 61) > 0.63:
				w.nature[idx] = World.N_BUSH
			elif SimNoise.hash2(x, y, seed + 71) > 0.985:
				w.nature[idx] = World.N_ROCK

	# Deposits: 2x2 patches on valley ground touching the mountains.
	for i in centers.size():
		var c: Dictionary = centers[i]
		var k := 0
		for dep in c.def.deposits:
			for attempt in 400:
				var a := SimNoise.hash2(k * 31 + attempt, i, seed + 81) * TAU
				var rr: float = c.r * (0.55 + SimNoise.hash2(attempt, k, seed + 83) * 0.45)
				var x := roundi(c.cx + cos(a) * rr)
				var y := roundi(c.cy + sin(a) * rr)
				var patch := [Vector2i(x, y), Vector2i(x + 1, y), Vector2i(x, y + 1), Vector2i(x + 1, y + 1)]
				var ok := true
				var near_mountain := false
				for p in patch:
					if not w.inside(p.x, p.y) or w.terrain[w.idx(p.x, p.y)] != World.GRASS or w.valley[w.idx(p.x, p.y)] != i or w.deposit.has(w.idx(p.x, p.y)):
						ok = false
						break
					for yy in range(-2, 3):
						for xx in range(-2, 3):
							if w.inside(p.x + xx, p.y + yy) and w.terrain[w.idx(p.x + xx, p.y + yy)] == World.MOUNTAIN:
								near_mountain = true
				if not ok or not near_mountain:
					continue
				for p in patch:
					w.deposit[w.idx(p.x, p.y)] = dep
					w.nature[w.idx(p.x, p.y)] = World.N_NONE
				break
			k += 1

	# Valleys.
	w.valleys = []
	for i in centers.size():
		var c: Dictionary = centers[i]
		var owner = null
		if c.def.get("home", false):
			owner = World.PLAYER
		elif c.def.has("rival"):
			owner = c.def.rival
		w.valleys.append({
			"idx": i, "def": c.def.id, "cx": c.cx, "cy": c.cy, "owner": owner,
			"discovered": c.def.get("home", false), "fertilities": c.def.fertilities.duplicate(),
			"storage": {}, "workforce": {}, "population": {},
		})

	# Passes through the mountains; each may be blocked by an obstacle that must be overcome.
	w.passes = []
	for e in Content.passes:
		var a := _find(centers, e.a)
		var b := _find(centers, e.b)
		if a < 0 or b < 0:
			continue
		var core := []
		var tiles := _carve(w, centers[a], centers[b], seed + w.passes.size() * 13, core)
		for t in tiles:
			w.terrain[t] = World.PASS
			w.pass_of[t] = w.passes.size()
			w.nature[t] = World.N_NONE
		var obstacle: String = e.get("obstacle", "none")
		w.passes.append({
			"idx": w.passes.size(), "a": a, "b": b, "tiles": tiles, "discovered": false,
			"obstacle": obstacle, "cleared": obstacle == "none", "plank": false, "project": null,
			"mid": core[core.size() / 2] if core.size() > 0 else -1, "core": core,
		})


static func _find(centers: Array, id: String) -> int:
	for i in centers.size():
		if centers[i].def.id == id:
			return i
	return -1


## Walks from centre A to centre B with a gentle wobble; returns the mountain tiles crossed (4-connected).
static func _carve(w: World, a: Dictionary, b: Dictionary, seed: int, core: Array) -> Array:
	var out := []
	var seen := {}
	var dx: float = b.cx - a.cx
	var dy: float = b.cy - a.cy
	var length := sqrt(dx * dx + dy * dy)
	var nx := -dy / length
	var ny := dx / length
	var px := roundi(a.cx)
	var py := roundi(a.cy)
	var steps := ceili(length * 3.0)
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var wob := sin(t * PI) * (SimNoise.fbm(t * 4.0, 0, seed) - 0.5) * 10.0
		var tx := roundi(a.cx + dx * t + nx * wob)
		var ty := roundi(a.cy + dy * t + ny * wob)
		while px != tx or py != ty:
			if px != tx:
				px += signi(tx - px)
			else:
				py += signi(ty - py)
			var i := w.idx(px, py)
			if w.terrain[i] == World.MOUNTAIN and not seen.has(i):
				seen[i] = true
				out.append(i)
				core.append(i)
				# widen the trail to a small gorge so it reads from the camera
				for j in [i + 1, i - 1, i + w.size, i - w.size]:
					if j >= 0 and j < w.size * w.size and w.terrain[j] == World.MOUNTAIN and not seen.has(j):
						seen[j] = true
						out.append(j)
	return out
