class_name Game
extends Node
## A running game session: owns the world, the view, the HUD, tools and the fixed-step loop.

signal exit_to_menu

var world: World
var view: WorldView
var hud # Hud
var speed := 1
var paused := false
var tool := {"kind": "select"}
var selected := 0
var hover = null # Vector2i or null
var focus := 0 # valley under the screen centre
var _acc := 0.0
var _path_start = null
var _demolishing := false
var _last_autosave := 0.0


func start(w: World, with_hud := true) -> void:
	world = w
	view = WorldView.new()
	add_child(view)
	view.setup(self, w)
	if with_hud:
		hud = Hud.new()
		add_child(hud)
		hud.setup(self)
	focus = w.home_valley().idx
	_last_autosave = w.time


func _process(delta: float) -> void:
	if world == null:
		return
	if not paused:
		_acc += delta * speed
		var n := 0
		while _acc >= World.TICK and n < 60:
			world.step()
			_acc -= World.TICK
			n += 1
		if n >= 60:
			_acc = 0.0
	var vs := get_viewport().get_visible_rect().size
	var t := view.screen_to_tile(vs / 2.0)
	if world.inside(t.x, t.y):
		var v := world.valley[world.idx(t.x, t.y)]
		if v >= 0 and world.valleys[v].discovered:
			focus = v
	var every: float = Settings.data.autosave_minutes
	if hud and every > 0 and world.time - _last_autosave > every * 60.0:
		_last_autosave = world.time
		Saves.save("autosave", Content.L("Automatische Speicherung", "Autosave"), world)


## All UI actions go through here so they could be sent to lockstep peers.
func command(c: Dictionary, sound := "click") -> bool:
	var r := Commands.apply(world, c)
	if not r.ok:
		Sfx.play("error")
		if r.has("reason") and hud:
			hud.flash(Content.tx(r.reason))
	elif sound != "":
		Sfx.play(sound)
	return r.ok


func set_tool(t: Dictionary) -> void:
	tool = t
	_path_start = null
	if t.kind != "select":
		selected = 0
	if hud:
		hud.refresh_buildbar()


func _ghost_origin(tile: Vector2i, def: Dictionary) -> Vector2i:
	return Vector2i(tile.x - int((def.size[0] - 1) / 2), tile.y - int((def.size[1] - 1) / 2))


func ghost():
	if tool.kind != "build" or hover == null:
		return null
	var def: Dictionary = Content.BUILDING[tool.building]
	var o := _ghost_origin(hover, def)
	return {"building": def.id, "x": o.x, "y": o.y, "ok": world.check_placement(def.id, o.x, o.y).ok}


func preview_radius():
	if tool.kind == "build" and hover != null:
		var def: Dictionary = Content.BUILDING[tool.building]
		var o := _ghost_origin(hover, def)
		var c := Vector2(o.x + def.size[0] / 2.0, o.y + def.size[1] / 2.0)
		if def.has("service"):
			return {"x": c.x, "y": c.y, "r": float(def.service.radius)}
		if def.get("requires", {}).has("nature"):
			return {"x": c.x, "y": c.y, "r": float(def.requires.nature.radius) + def.size[0] / 2.0}
	if tool.kind == "select" and selected != 0 and world.buildings.has(selected):
		var b: Dictionary = world.buildings[selected]
		var def: Dictionary = Content.BUILDING[b.type]
		if def.has("service"):
			return {"x": b.x + def.size[0] / 2.0, "y": b.y + def.size[1] / 2.0, "r": float(def.service.radius)}
	return null


func path_preview() -> Array:
	if hover == null:
		return []
	return l_path(_path_start, hover) if _path_start != null else [hover]


## L-shaped path from a to b (first along x, then along y), like dragging roads in Anno.
static func l_path(a: Vector2i, b: Vector2i) -> Array:
	var out := [a]
	var p := a
	while p.x != b.x:
		p.x += signi(b.x - p.x)
		out.append(p)
	while p.y != b.y:
		p.y += signi(b.y - p.y)
		out.append(p)
	return out


func pointer_down(tile: Vector2i, button: int) -> void:
	if button == MOUSE_BUTTON_RIGHT:
		if tool.kind != "select":
			set_tool({"kind": "select"})
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	match tool.kind:
		"build":
			var def: Dictionary = Content.BUILDING[tool.building]
			var o := _ghost_origin(tile, def)
			command({"type": "build", "building": def.id, "x": o.x, "y": o.y}, "build")
			if def.id == "storage":
				set_tool({"kind": "select"})
		"path":
			_path_start = tile
		"demolish":
			_demolishing = true
			command({"type": "demolish", "x": tile.x, "y": tile.y}, "demolish")
		_:
			selected = world.bmap[world.idx(tile.x, tile.y)] if world.inside(tile.x, tile.y) else 0
			if hud == null:
				return
			if selected != 0:
				Sfx.play("click")
				hud.open_panel("building")
			elif hud.panel == "building":
				hud.open_panel("")


func pointer_move(tile: Vector2i) -> void:
	hover = tile
	if _demolishing and tool.kind == "demolish" and world.inside(tile.x, tile.y):
		var i := world.idx(tile.x, tile.y)
		if world.road[i] or world.bmap[i] != 0:
			command({"type": "demolish", "x": tile.x, "y": tile.y}, "")


func pointer_up(tile: Vector2i, button: int) -> void:
	_demolishing = false
	if button == MOUSE_BUTTON_LEFT and tool.kind == "path" and _path_start != null:
		command({"type": "path", "tiles": l_path(_path_start, tile)}, "build")
		_path_start = null
