class_name GroundChunk
extends Node2D
## A 16x16 tile block of painted ground. Godot caches the draw commands, so a chunk is only
## repainted when one of its tiles changes (paths, discovery, ...). Off-screen chunks are culled.

const N := 16

var view # WorldView
var cx := 0
var cy := 0
var signature := 0

static var _strokes: Array[Texture2D] = []


func setup(v, chunk_x: int, chunk_y: int) -> void:
	view = v
	cx = chunk_x
	cy = chunk_y
	if _strokes.is_empty():
		for i in 4:
			_strokes.append(Art.tex("brush/stroke_%d" % i))


func compute_signature() -> int:
	var w: World = view.world
	var h := 17
	for y in range(cy * N - 1, cy * N + N + 1):
		for x in range(cx * N - 1, cx * N + N + 1):
			if not w.inside(x, y):
				continue
			var i := w.idx(x, y)
			var pd := 0
			if w.terrain[i] == World.PASS and w.passes[w.pass_of[i]].discovered:
				pd = 5
			h = (h * 31 + w.terrain[i] * 7 + w.road[i] * 3 + roundi(view.reveal[i] * 8.0) * 11 + pd + (1 if w.nature[i] == World.N_TREE else 0)) & 0x7FFFFFFF
	return h


func refresh() -> void:
	var s := compute_signature()
	if s != signature:
		signature = s
		queue_redraw()


func _tiles() -> Array:
	var out := []
	var w: World = view.world
	for y in range(cy * N, cy * N + N):
		for x in range(cx * N, cx * N + N):
			if w.inside(x, y):
				out.append(Vector2i(x, y))
	return out


func _draw() -> void:
	var w: World = view.world
	var tiles := _tiles()
	for t in tiles:
		_paint_tile(w, t.x, t.y)
	_paint_water(w, tiles)
	for t in tiles:
		_paint_paths(w, t.x, t.y)
	for t in tiles:
		_paint_fog(w, t.x, t.y)


func _rng(x: int, y: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = x * 92821 + y * 68917 + salt * 7919 + view.world.seed
	return r


func _diamond(x: float, y: float, grow := 1.0) -> PackedVector2Array:
	var p := Art.iso(x, y)
	return PackedVector2Array([p + Vector2(0, -grow), p + Vector2(Art.TW / 2 + grow, Art.TH / 2), p + Vector2(0, Art.TH + grow), p + Vector2(-Art.TW / 2 - grow, Art.TH / 2)])


func _ellipse(c: Vector2, rx: float, ry: float, n := 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _stroke(pos: Vector2, length: float, width: float, angle: float, color: Color) -> void:
	var tex: Texture2D = _strokes[(int(pos.x * 7 + pos.y * 13) & 0x7FFFFFFF) % _strokes.size()]
	draw_set_transform(pos, angle, Vector2(length / tex.get_width(), width / tex.get_height()))
	draw_texture(tex, -tex.get_size() / 2.0, color)
	draw_set_transform(Vector2.ZERO)


func _paint_tile(w: World, x: int, y: int) -> void:
	var i := w.idx(x, y)
	var t := w.terrain[i]
	var r := _rng(x, y, 1)
	var base: Color = Pal.EARTH_LIGHT if t == World.WATER else view.color_at(x + 0.5, y + 0.5, x, y)
	draw_colored_polygon(_diamond(x, y), base)
	if t == World.WATER:
		return
	for k in 7:
		var fx := x + r.randf() * 1.3 - 0.15
		var fy := y + r.randf() * 1.3 - 0.15
		var light := r.randf() - 0.5
		var c: Color = view.color_at(fx, fy, x, y)
		c = c.lightened(light * 0.25) if light > 0 else c.darkened(-light * 0.25)
		c.a = 0.45 + r.randf() * 0.4
		_stroke(Art.iso(fx, fy), 16 + r.randf() * 26, 7 + r.randf() * 8, -0.5 + r.randf(), c)
	if t == World.GRASS:
		var cpos := Art.iso(x + 0.5, y + 0.5)
		for k in 3:
			var g := cpos + Vector2((r.randf() - 0.5) * 36, (r.randf() - 0.5) * 14)
			var col := Color(Pal.GRASS_DARK, 0.55)
			draw_line(g + Vector2(-2, -3), g, col, 1.0, true)
			draw_line(g, g + Vector2(1, -4), col, 1.0, true)
			draw_line(g, g + Vector2(3, -2), col, 1.0, true)
		if w.nature[i] == World.N_NONE and r.randf() > 0.8:
			var fc := Color("efe0a8") if r.randf() > 0.5 else Color("c96a6a")
			for k in 3:
				draw_circle(cpos + Vector2((r.randf() - 0.5) * 30, (r.randf() - 0.5) * 12), 1.4, fc)
		if w.nature[i] == World.N_TREE:
			draw_colored_polygon(_ellipse(cpos, Art.TW * 0.5, Art.TH * 0.5), Color(Pal.TREE_DARK, 0.22))


## Water as overlapping rounded blobs: soft, organic shorelines instead of tile staircases.
func _paint_water(w: World, tiles: Array) -> void:
	var water := tiles.filter(func(t): return w.terrain[w.idx(t.x, t.y)] == World.WATER)
	if water.is_empty():
		return
	var shore := {}
	for t in water:
		shore[t] = view.count_around(t.x, t.y, 1, World.WATER, true) > 0
	for t in water:
		if shore[t]:
			draw_colored_polygon(_blob(w, t, 0.8), Pal.EARTH_LIGHT)
	for t in water:
		if shore[t]:
			draw_colored_polygon(_blob(w, t, 0.67), Pal.FOAM)
	for t in water:
		draw_colored_polygon(_blob(w, t, 0.6), view.color_at(t.x + 0.5, t.y + 0.5, t.x, t.y))
	for t in water:
		var r := _rng(t.x, t.y, 3)
		var c := Art.iso(t.x + 0.5, t.y + 0.5)
		for k in 2:
			var col := Color(Pal.WATER_LIGHT if r.randf() > 0.5 else Pal.WATER_DEEP, 0.4)
			_stroke(c + Vector2((r.randf() - 0.5) * 24, (r.randf() - 0.5) * 10), 18, 4, 0.0, col)


func _blob(w: World, t: Vector2i, radius: float) -> PackedVector2Array:
	var k := radius * (0.93 + SimNoise.hash2(t.x, t.y, w.seed + 19) * 0.14)
	return _ellipse(Art.iso(t.x + 0.5, t.y + 0.5), Art.TW * k, Art.TH * k)


func _paint_paths(w: World, x: int, y: int) -> void:
	var i := w.idx(x, y)
	var is_road := w.road[i] == 1
	var is_trail := w.terrain[i] == World.PASS
	if not is_road and not is_trail:
		return
	var discovered: bool = w.passes[w.pass_of[i]].discovered if is_trail else true
	var c := Art.iso(x + 0.5, y + 0.5)
	var links := []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if not w.inside(nx, ny):
			continue
		var j := w.idx(nx, ny)
		var ok := false
		if is_road:
			ok = w.road[j] == 1 or (w.bmap[j] != 0 and w.buildings[w.bmap[j]].type == "storage")
		else:
			ok = w.terrain[j] == World.PASS or w.terrain[j] == World.GRASS
		if ok:
			links.append((c + Art.iso(nx + 0.5, ny + 0.5)) / 2.0)
	if is_road:
		_path_line(c, links, 15.0, Color(Pal.PATH_DARK, 0.55))
		_path_line(c, links, 11.0, Pal.PATH)
		var r := _rng(x, y, 5)
		for k in 3:
			draw_circle(c + Vector2((r.randf() - 0.5) * 14, (r.randf() - 0.5) * 6), 1.2, Color(Pal.PATH_DARK, 0.6))
	else:
		_path_line(c, links, 6.0 if discovered else 4.0, Color(Pal.PATH, 0.85) if discovered else Color(Pal.PARCHMENT_DARK, 0.6))


func _path_line(c: Vector2, links: Array, width: float, color: Color) -> void:
	draw_circle(c, width / 2.0, color)
	for l in links:
		draw_line(c, l, color, width)
		draw_circle(l, width / 2.0, color)


## The unknown is parchment with pencil hatching – the world gets painted as you explore it.
func _paint_fog(w: World, x: int, y: int) -> void:
	var i := w.idx(x, y)
	var rv: float = view.reveal[i]
	if rv >= 1.0:
		return
	var c := Art.iso(x + 0.5, y + 0.5)
	draw_colored_polygon(_ellipse(c, Art.TW * 0.72, Art.TH * 0.72, 14), Color(Pal.PARCHMENT, minf(1.0, (1.0 - rv) * 1.05)))
	if rv < 0.05:
		var r := _rng(x, y, 7)
		var mountain := w.terrain[i] == World.MOUNTAIN
		var pencil := Color(Pal.PENCIL, 0.22 if mountain else 0.1)
		if mountain and (x + y) % 3 == 0 and r.randf() > 0.4:
			var h := 6.0 + r.randf() * 10.0
			draw_polyline(PackedVector2Array([c + Vector2(-10, 4), c + Vector2(-1, -h), c + Vector2(10, 4)]), pencil, 1.0, true)
			for k in 3:
				draw_line(c + Vector2(2 + k * 2, -h + 4 + k * 3), c + Vector2(5 + k * 2, 3), pencil, 1.0, true)
		elif r.randf() > 0.7:
			draw_line(c + Vector2(-8, 3), c + Vector2(8, -3), pencil, 1.0, true)
