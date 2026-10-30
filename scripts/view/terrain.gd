class_name Terrain
extends Node3D
## The 3D landscape: a height model (flat valley floors, mountains that rise with distance from the
## valleys, sunken lakes), split into chunks, painted by terrain.gdshader. Per-tile colours and flags
## (roads, trails, plots, water, explored) live in two tiny textures that are cheap to update.

const CHUNK := 16
const MARGIN := 24 # mountains continue beyond the playable map
const WATER_LEVEL := -0.32
const UPSAMPLE := 4 # paint textures are upsampled this much from one texel per tile
const PEAK_SCALE := 1.2

var world: World
var size := 0
var depth := PackedInt32Array() # distance of each tile to the nearest non-mountain tile
var corner := PackedFloat32Array() # heights at tile corners, (size + 2 * MARGIN + 1)^2
var _cw := 0 # corners per row
var tint_img: Image
var data_img: Image
var tint_tex: ImageTexture
var data_tex: ImageTexture
var mat := ShaderMaterial.new()
var water_mat := ShaderMaterial.new()


var _pass_rise := {} # pass tile -> extra height towards the saddle
var pass_dist := PackedInt32Array() # mountain tiles: distance to the nearest pass (passes cross low saddles)


func setup(w: World) -> void:
	world = w
	size = w.size
	depth = _mountain_depth()
	pass_dist = _pass_distance()
	for p in w.passes:
		var n: int = p.core.size()
		for k in n:
			var rise := sin(PI * (k + 0.5) / n) * minf(2.4, n * 0.08)
			var c: int = p.core[k]
			for t in [c, c + 1, c - 1, c + size, c - size]:
				if w.pass_of[clampi(t, 0, size * size - 1)] == p.idx:
					_pass_rise[t] = maxf(_pass_rise.get(t, 0.0), rise)
	_build_heights()
	tint_img = Image.create(size * UPSAMPLE, size * UPSAMPLE, false, Image.FORMAT_RGBA8)
	data_img = Image.create(size * UPSAMPLE, size * UPSAMPLE, false, Image.FORMAT_RGBA8)
	tint_tex = ImageTexture.create_from_image(tint_img)
	data_tex = ImageTexture.create_from_image(data_img)
	mat.shader = load("res://scripts/view/shaders/terrain.gdshader")
	mat.set_shader_parameter("tint_tex", tint_tex)
	mat.set_shader_parameter("data_tex", data_tex)
	mat.set_shader_parameter("map_size", float(size))
	water_mat.shader = load("res://scripts/view/shaders/water.gdshader")
	water_mat.set_shader_parameter("data_tex", data_tex)
	water_mat.set_shader_parameter("map_size", float(size))
	_build_meshes()
	_build_water()


# ---------------------------------------------------------------- heights

func _mountain_depth() -> PackedInt32Array:
	var w := world
	var d := PackedInt32Array()
	d.resize(size * size)
	d.fill(999)
	var q: Array[int] = []
	for i in size * size:
		if w.terrain[i] != World.MOUNTAIN:
			d[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		var x := i % size
		var y := i / size
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + o.x
			var ny: int = y + o.y
			if nx < 0 or ny < 0 or nx >= size or ny >= size:
				continue
			var j := ny * size + nx
			if d[j] > d[i] + 1:
				d[j] = d[i] + 1
				q.append(j)
	return d


func _pass_distance() -> PackedInt32Array:
	var w := world
	var d := PackedInt32Array()
	d.resize(size * size)
	d.fill(99)
	var q: Array[int] = []
	for i in size * size:
		if w.terrain[i] == World.PASS:
			d[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		if d[i] >= 9:
			continue
		var x := i % size
		for j in [i + 1 if x < size - 1 else -1, i - 1 if x > 0 else -1, i + size, i - size]:
			if j >= 0 and j < size * size and w.terrain[j] == World.MOUNTAIN and d[j] > d[i] + 1:
				d[j] = d[i] + 1
				q.append(j)
	return d


## Target height of a tile; tiles outside the map continue the edge mountains.
func _tile_height(x: int, y: int) -> float:
	var s := world.seed
	var cx := clampi(x, 0, size - 1)
	var cy := clampi(y, 0, size - 1)
	var i := cy * size + cx
	var outside := maxi(absi(x - cx), absi(y - cy))
	var t := world.terrain[i] if outside == 0 else World.MOUNTAIN
	match t:
		World.WATER:
			return -1.0
		World.PASS:
			# trails climb to a saddle half-way between the valleys
			return 0.35 + _pass_rise.get(i, 0.0) + SimNoise.fbm(x * 0.2, y * 0.2, s + 3) * 0.4
		World.GRASS:
			return SimNoise.fbm(x * 0.09, y * 0.09, s + 21) * 0.32
	var d := float(depth[i] + outside) if world.terrain[i] == World.MOUNTAIN else float(1 + outside)
	var n := SimNoise.fbm(x * 0.07, y * 0.07, s + 31)
	var ridge := 1.0 - absf(SimNoise.fbm(x * 0.13, y * 0.13, s + 47) * 2.0 - 1.0)
	var h := pow(d, 0.92) * (0.75 + 0.55 * n) + ridge * minf(d, 4.0) * 0.55
	if outside == 0:
		h *= lerpf(0.5, 1.0, clampf(pass_dist[i] / 9.0, 0.0, 1.0))
	return minf(h * PEAK_SCALE, 14.0 + n * 3.0)


func _build_heights() -> void:
	var tiles := size + 2 * MARGIN
	_cw = tiles + 1
	var th := PackedFloat32Array()
	th.resize(tiles * tiles)
	for y in tiles:
		for x in tiles:
			th[y * tiles + x] = _tile_height(x - MARGIN, y - MARGIN)
	corner.resize(_cw * _cw)
	for y in _cw:
		for x in _cw:
			var sum := 0.0
			var n := 0
			var lo := 99.0
			for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
				var tx: int = x + o.x
				var ty: int = y + o.y
				if tx >= 0 and ty >= 0 and tx < tiles and ty < tiles:
					var v := th[ty * tiles + tx]
					sum += v
					lo = minf(lo, v)
					n += 1
			var h := sum / maxi(1, n)
			# rugged mountain corners, smooth valley floors
			if lo > 1.0:
				h += (SimNoise.hash2(x, y, world.seed + 77) - 0.5) * minf(1.2, lo * 0.25)
			corner[y * _cw + x] = h


func _corner_h(cx: int, cy: int) -> float:
	cx = clampi(cx + MARGIN, 0, _cw - 1)
	cy = clampi(cy + MARGIN, 0, _cw - 1)
	return corner[cy * _cw + cx]


## Ground height at a world position (x, z in tile units).
func height_at(fx: float, fz: float) -> float:
	var x0 := floori(fx)
	var y0 := floori(fz)
	var tx := fx - x0
	var ty := fz - y0
	var a := _corner_h(x0, y0)
	var b := _corner_h(x0 + 1, y0)
	var c := _corner_h(x0, y0 + 1)
	var d := _corner_h(x0 + 1, y0 + 1)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


## Mean height over a rectangle of tiles (buildings sit on this).
func footprint_height(x: int, y: int, w: int, h: int) -> float:
	var sum := 0.0
	var n := 0
	for yy in range(y, y + h + 1):
		for xx in range(x, x + w + 1):
			sum += _corner_h(xx, yy)
			n += 1
	return sum / n


# ---------------------------------------------------------------- meshes

func _build_meshes() -> void:
	var from := -MARGIN
	var to := size + MARGIN
	var cy := from
	while cy < to:
		var cx := from
		while cx < to:
			var mi := MeshInstance3D.new()
			mi.mesh = _chunk_mesh(cx, cy, mini(cx + CHUNK, to), mini(cy + CHUNK, to))
			mi.material_override = mat
			add_child(mi)
			cx += CHUNK
		cy += CHUNK


func _normal_at(x: int, y: int) -> Vector3:
	var l := _corner_h(x - 1, y)
	var r := _corner_h(x + 1, y)
	var u := _corner_h(x, y - 1)
	var d := _corner_h(x, y + 1)
	return Vector3(l - r, 2.0, u - d).normalized()


func _chunk_mesh(x0: int, y0: int, x1: int, y1: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	for y in range(y0, y1):
		for x in range(x0, x1):
			var p00 := Vector3(x, _corner_h(x, y), y)
			var p10 := Vector3(x + 1, _corner_h(x + 1, y), y)
			var p01 := Vector3(x, _corner_h(x, y + 1), y + 1)
			var p11 := Vector3(x + 1, _corner_h(x + 1, y + 1), y + 1)
			var tris := [[p00, p10, p11], [p00, p11, p01]] if (x + y) % 2 == 0 else [[p00, p10, p01], [p10, p11, p01]]
			for t in tris:
				var a: Vector3 = t[0]
				var b: Vector3 = t[1]
				var c: Vector3 = t[2]
				var face := (c - a).cross(b - a).normalized()
				# faceted, low-poly mountains; soft valley floors
				var faceted := (a.y + b.y + c.y) / 3.0 > 1.0
				for v in [a, b, c]:
					verts.append(v)
					norms.append(face if faceted else _normal_at(int(v.x), int(v.z)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


func _build_water() -> void:
	var plane := PlaneMesh.new()
	var extent := float(size + 2 * MARGIN)
	plane.size = Vector2(extent, extent)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = water_mat
	mi.position = Vector3(size / 2.0, WATER_LEVEL, size / 2.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# ---------------------------------------------------------------- per-tile paint

## Rewrites the tint and flag textures (cheap: one texel per tile).
var _tint_bytes := PackedByteArray()
var _data_bytes := PackedByteArray()


## Full repaint of the per-tile textures (after discovery or pass changes).
func refresh(reveal: PackedFloat32Array) -> void:
	_tint_bytes.resize(size * size * 4)
	_data_bytes.resize(size * size * 4)
	for i in size * size:
		_paint_tile(i, reveal)
	_upload()


## Repaints only the given tiles (buildings and paths placed or removed).
func refresh_tiles(tiles: PackedInt32Array, reveal: PackedFloat32Array) -> void:
	if _tint_bytes.is_empty():
		refresh(reveal)
		return
	var done := {}
	for i in tiles:
		# neighbours too: trodden ground spreads around new buildings and paths
		for j in [i, i - 1, i + 1, i - size, i + size]:
			if j >= 0 and j < size * size and not done.has(j):
				done[j] = true
				_paint_tile(j, reveal)
	_upload()


func _paint_tile(i: int, reveal: PackedFloat32Array) -> void:
	var w := world
	var c := _tint(i, i % size, i / size)
	var o := i * 4
	_tint_bytes[o] = c.r8
	_tint_bytes[o + 1] = c.g8
	_tint_bytes[o + 2] = c.b8
	var plot: bool = w.bmap[i] != 0 and Content.BUILDING[w.buildings[w.bmap[i]].type].style != "field"
	_tint_bytes[o + 3] = 255 if plot else (130 if _trampled(i) else 0)
	var road: bool = w.road[i] != 0
	var tr := 0
	if w.terrain[i] == World.PASS:
		var p: Dictionary = w.passes[w.pass_of[i]]
		tr = 255 if p.discovered else 150
		road = road or p.plank
	_data_bytes[o] = 255 if road else 0
	_data_bytes[o + 1] = tr
	# the mountains' silhouettes stay visible through the mist; valleys stay hidden
	var rv := reveal[i] if w.terrain[i] != World.MOUNTAIN else maxf(reveal[i], 0.85)
	_data_bytes[o + 2] = int(clampf(rv, 0.0, 1.0) * 255.0)
	_data_bytes[o + 3] = 255 if w.terrain[i] == World.WATER else 0


## Ground next to homes and paths is trodden bare: the warm ochre earth of a settlement.
func _trampled(i: int) -> bool:
	var w := world
	if w.terrain[i] != World.GRASS:
		return false
	var x := i % size
	var y := i / size
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + o.x
		var ny: int = y + o.y
		if nx < 0 or ny < 0 or nx >= size or ny >= size:
			continue
		var j := ny * size + nx
		if w.bmap[j] != 0 and Content.BUILDING[w.buildings[w.bmap[j]].type].style != "field":
			return true
		if w.road[j] and (SimNoise.hash2(x, y, w.seed + 5) > 0.45 or w.road[i]):
			return true
	return false


func _upload() -> void:
	# cubic upsampling turns the tile grid into soft, rounded shapes
	tint_img.set_data(size, size, false, Image.FORMAT_RGBA8, _tint_bytes)
	data_img.set_data(size, size, false, Image.FORMAT_RGBA8, _data_bytes)
	tint_img.resize(size * UPSAMPLE, size * UPSAMPLE, Image.INTERPOLATE_CUBIC)
	data_img.resize(size * UPSAMPLE, size * UPSAMPLE, Image.INTERPOLATE_CUBIC)
	tint_tex.update(tint_img)
	data_tex.update(data_img)


func _tint(i: int, x: int, y: int) -> Color:
	var w := world
	var s := w.seed
	var n := SimNoise.fbm(x * 0.13, y * 0.13, s + 5)
	match w.terrain[i]:
		World.GRASS:
			var vd: Dictionary = w.valleys[w.valley[i]]
			var c: Color = Pal.VALLEY_TINT.get(vd.def, Pal.GRASS)
			c = c.lerp(Pal.GRASS_LIGHT, maxf(0.0, n - 0.42) * 1.5)
			c = c.lerp(Pal.GRASS_DARK, maxf(0.0, 0.45 - n) * 1.2)
			var m := SimNoise.fbm(x * 0.07, y * 0.07, s + 9)
			if m > 0.58:
				c = c.lerp(Pal.MEADOW, minf(0.6, (m - 0.58) * 2.0))
			if "clay" in vd.fertilities:
				var k := SimNoise.fbm(x * 0.2, y * 0.2, s + 13)
				if k > 0.62:
					c = c.lerp(Pal.CLAY, minf(0.4, (k - 0.62) * 2.0))
			if w.nature[i] == World.N_TREE:
				c = c.lerp(Pal.TREE_DARK, 0.35)
			return c
		World.WATER:
			return Pal.EARTH_LIGHT
		World.PASS:
			return Pal.GRASS_DARK.lerp(Pal.ROCK, 0.4)
	# mountain foothills stay green, higher up it turns to stone
	var d := depth[i]
	return Pal.GRASS_DARK.lerp(Pal.ROCK, clampf((d - 1) / 3.0, 0.0, 1.0)).lerp(Pal.ROCK_DARK, n * 0.3)
