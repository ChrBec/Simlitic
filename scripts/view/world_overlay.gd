class_name WorldOverlay
extends Node3D
## Build previews, selection, service radii and porter routes, drawn as flat shapes hugging the terrain.

const LIFT := 0.05

var view # WorldView
var _im := ImmediateMesh.new()
var _mi := MeshInstance3D.new()
var _ghost := MeshInstance3D.new()
var _ghost_type := ""
var _ghost_ok_mat := StandardMaterial3D.new()
var _ghost_bad_mat := StandardMaterial3D.new()
var _t := 0.0


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = 1
	_mi.mesh = _im
	_mi.material_override = m
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	for pair in [[_ghost_ok_mat, Color(0.75, 1.0, 0.6, 0.6)], [_ghost_bad_mat, Color(1.0, 0.45, 0.35, 0.6)]]:
		var gm: StandardMaterial3D = pair[0]
		gm.albedo_color = pair[1]
		gm.vertex_color_use_as_albedo = true
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.emission_enabled = true
		gm.emission = Color(pair[1], 1.0) * 0.25
	_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.visible = false
	add_child(_ghost)


func _p(x: float, z: float) -> Vector3:
	return Vector3(x, view.terrain.height_at(x, z) + LIFT, z)


func redraw() -> void:
	_t += get_process_delta_time()
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_draw_all()
	_im.surface_end()


func _draw_all() -> void:
	var g = view.game
	var w: World = view.world
	# a dummy invisible triangle keeps the surface valid when nothing else is drawn
	_tri(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Color(0, 0, 0, 0))
	for r in w.routes:
		for k in range(0, r.path.size() - 1, 2):
			var a: int = r.path[k]
			var b: int = r.path[k + 1]
			_segment(Vector2(a % w.size + 0.5, a / w.size + 0.5), Vector2(b % w.size + 0.5, b / w.size + 0.5), 0.12, Color(0.35, 0.23, 0.12, 0.7))
	var radius = g.preview_radius()
	if radius != null:
		_disc(Vector2(radius.x, radius.y), radius.r, Color(1, 0.9, 0.62, 0.16))
		_ring(Vector2(radius.x, radius.y), radius.r, 0.08, Color(0.35, 0.23, 0.12, 0.8), true)
	if g.tool.kind == "path" and g.hover != null:
		for t in g.path_preview():
			if not w.inside(t.x, t.y):
				continue
			var i := w.idx(t.x, t.y)
			var valid: bool = w.terrain[i] == World.GRASS and w.bmap[i] == 0 and not w.road[i] and w.valley[i] >= 0 and w.valleys[w.valley[i]].owner == World.PLAYER
			_rect(t.x + 0.08, t.y + 0.08, 0.84, 0.84, Color(0.95, 0.82, 0.5, 0.6) if valid else Color(0.85, 0.25, 0.16, 0.5))
	var ghost = g.ghost()
	if ghost != null:
		var def: Dictionary = Content.BUILDING[ghost.building]
		var sw := int(def.size[0])
		var sh := int(def.size[1])
		_rect(ghost.x, ghost.y, sw, sh, Color(0.63, 0.86, 0.47, 0.35) if ghost.ok else Color(0.86, 0.27, 0.2, 0.4))
		_outline(ghost.x, ghost.y, sw, sh, 0.06, Color(0.24, 0.35, 0.12, 0.9) if ghost.ok else Color(0.47, 0.12, 0.08, 0.9), false)
		if _ghost_type != def.id:
			_ghost_type = def.id
			_ghost.mesh = Models.mesh("buildings/" + def.id)
		_ghost.material_override = _ghost_ok_mat if ghost.ok else _ghost_bad_mat
		_ghost.position = Vector3(ghost.x + sw / 2.0, view.terrain.footprint_height(ghost.x, ghost.y, sw, sh) + 0.02, ghost.y + sh / 2.0)
		_ghost.rotation.y = view.facing({"type": def.id, "x": ghost.x, "y": ghost.y})
		_ghost.visible = true
	else:
		_ghost.visible = false
		if g.hover != null and w.inside(g.hover.x, g.hover.y):
			var demolish: bool = g.tool.kind == "demolish"
			_outline(g.hover.x, g.hover.y, 1, 1, 0.05, Color(0.75, 0.16, 0.12, 0.95) if demolish else Color(0.98, 0.94, 0.8, 0.7), false)
	if g.selected != 0 and w.buildings.has(g.selected):
		var b: Dictionary = w.buildings[g.selected]
		var def: Dictionary = Content.BUILDING[b.type]
		var pulse := 0.75 + sin(_t * 4.0) * 0.2
		_outline(b.x - 0.1, b.y - 0.1, def.size[0] + 0.2, def.size[1] + 0.2, 0.09, Color(1, 0.95, 0.75, pulse), true)


func _tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	for v in [a, b, c]:
		_im.surface_set_color(col)
		_im.surface_add_vertex(v)


## Rectangle on the ground, subdivided per tile so it follows the terrain.
func _rect(x: float, y: float, w: float, h: float, col: Color) -> void:
	var nx := maxi(1, ceili(w))
	var ny := maxi(1, ceili(h))
	for j in ny:
		for i in nx:
			var x0 := x + w * i / nx
			var x1 := x + w * (i + 1) / nx
			var y0 := y + h * j / ny
			var y1 := y + h * (j + 1) / ny
			_tri(_p(x0, y0), _p(x1, y0), _p(x1, y1), col)
			_tri(_p(x0, y0), _p(x1, y1), _p(x0, y1), col)


func _segment(a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var d := (b - a)
	if d.length() < 0.001:
		return
	var n := Vector2(-d.y, d.x).normalized() * width / 2.0
	var steps := maxi(1, ceili(d.length() * 2.0))
	for s in steps:
		var p0 := a.lerp(b, float(s) / steps)
		var p1 := a.lerp(b, float(s + 1) / steps)
		_tri(_p(p0.x - n.x, p0.y - n.y), _p(p1.x - n.x, p1.y - n.y), _p(p1.x + n.x, p1.y + n.y), col)
		_tri(_p(p0.x - n.x, p0.y - n.y), _p(p1.x + n.x, p1.y + n.y), _p(p0.x + n.x, p0.y + n.y), col)


func _outline(x: float, y: float, w: float, h: float, width: float, col: Color, dashed: bool) -> void:
	var c := [Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]
	for k in 4:
		var a: Vector2 = c[k]
		var b: Vector2 = c[(k + 1) % 4]
		if not dashed:
			_segment(a, b, width, col)
			continue
		var n := ceili(a.distance_to(b) / 0.4)
		for s in n:
			if s % 2 == 0:
				_segment(a.lerp(b, float(s) / n), a.lerp(b, float(s + 1) / n), width, col)


func _ring(c: Vector2, r: float, width: float, col: Color, dashed: bool) -> void:
	var n := maxi(32, int(r * 8))
	for i in n:
		if dashed and i % 2 == 1:
			continue
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		_segment(c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, width, col)


func _disc(c: Vector2, r: float, col: Color) -> void:
	var n := maxi(32, int(r * 8))
	var rings := maxi(1, int(r))
	for k in rings:
		var r0 := r * k / rings
		var r1 := r * (k + 1) / rings
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var p00 := c + Vector2(cos(a0), sin(a0)) * r0
			var p01 := c + Vector2(cos(a1), sin(a1)) * r0
			var p10 := c + Vector2(cos(a0), sin(a0)) * r1
			var p11 := c + Vector2(cos(a1), sin(a1)) * r1
			_tri(_p(p00.x, p00.y), _p(p10.x, p10.y), _p(p11.x, p11.y), col)
			if k > 0:
				_tri(_p(p00.x, p00.y), _p(p11.x, p11.y), _p(p01.x, p01.y), col)
