class_name WorldOverlay
extends Node2D
## Build previews, selection, service radii and porter routes drawn above the world.

var view


func _draw() -> void:
	var g = view.game
	var w: World = view.world
	for r in w.routes:
		var pts := PackedVector2Array()
		for i in r.path:
			pts.append(Art.iso(i % w.size + 0.5, i / w.size + 0.5))
		for k in range(0, pts.size() - 1, 2):
			draw_line(pts[k], pts[k + 1], Color(0.35, 0.23, 0.12, 0.55), 3.0, true)
	var radius = g.preview_radius()
	if radius != null:
		var c := Art.iso(radius.x, radius.y)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(c + Vector2(cos(a) * radius.r * Art.TW / sqrt(2.0), sin(a) * radius.r * Art.TH / sqrt(2.0)))
		draw_colored_polygon(pts, Color(1, 0.9, 0.62, 0.14))
		for i in range(0, 48, 2):
			draw_line(pts[i], pts[i + 1], Color(0.35, 0.23, 0.12, 0.75), 2.5, true)
	if g.tool.kind == "path" and g.hover != null:
		var ok := false
		for t in g.path_preview():
			if not w.inside(t.x, t.y):
				continue
			var i := w.idx(t.x, t.y)
			var valid: bool = w.terrain[i] == World.GRASS and w.bmap[i] == 0 and not w.road[i] and w.valley[i] >= 0 and w.valleys[w.valley[i]].owner == World.PLAYER
			ok = ok or valid
			draw_colored_polygon(_diamond(t.x, t.y, 1, 1), Color(0.9, 0.78, 0.47, 0.55) if valid else Color(0.78, 0.24, 0.16, 0.4))
	var ghost = g.ghost()
	if ghost != null:
		var def: Dictionary = Content.BUILDING[ghost.building]
		var poly := _diamond(ghost.x, ghost.y, int(def.size[0]), int(def.size[1]))
		draw_colored_polygon(poly, Color(0.63, 0.86, 0.47, 0.4) if ghost.ok else Color(0.86, 0.27, 0.2, 0.45))
		poly.append(poly[0])
		draw_polyline(poly, Color(0.24, 0.35, 0.12) if ghost.ok else Color(0.47, 0.12, 0.08), 2.0, true)
		var tex := Art.tex("buildings/" + def.id)
		var anchor := Art.anchor("buildings/" + def.id)
		var top := Art.iso(ghost.x, ghost.y)
		draw_set_transform(top, 0, Vector2(Art.SPRITE_SCALE, Art.SPRITE_SCALE))
		draw_texture(tex, -anchor, Color(1, 1, 1, 0.65))
		draw_set_transform(Vector2.ZERO)
	elif g.hover != null and w.inside(g.hover.x, g.hover.y):
		var poly := _diamond(g.hover.x, g.hover.y, 1, 1)
		poly.append(poly[0])
		draw_polyline(poly, Color(0.67, 0.16, 0.12, 0.9) if g.tool.kind == "demolish" else Color(0.24, 0.16, 0.08, 0.5), 1.5, true)
	if g.selected != 0 and w.buildings.has(g.selected):
		var b: Dictionary = w.buildings[g.selected]
		var def: Dictionary = Content.BUILDING[b.type]
		var poly := _diamond(b.x, b.y, int(def.size[0]), int(def.size[1]))
		poly.append(poly[0])
		for k in poly.size() - 1:
			draw_dashed_line(poly[k], poly[k + 1], Color(1, 0.95, 0.8, 0.95), 2.5, 6.0)


func _diamond(x: int, y: int, w: int, h: int) -> PackedVector2Array:
	return PackedVector2Array([Art.iso(x, y), Art.iso(x + w, y), Art.iso(x + w, y + h), Art.iso(x, y + h)])
