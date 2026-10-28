class_name WorldView
extends Node3D
## Renders the world in 3D: terrain, forests (multimeshes), buildings, people, light and the
## Anno-style camera (pan, zoom, rotate), and turns mouse input into tile clicks for the game.

const MIN_ZOOM := 0.35
const MAX_ZOOM := 2.2
const FAR := 95.0
const NEAR := 8.0

var game # Game
var world: World
var terrain := Terrain.new()
var overlay := WorldOverlay.new()
var reveal := PackedFloat32Array()
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var target := Vector3.ZERO # ground point the camera looks at
var yaw := deg_to_rad(45.0)
var zoom := 1.0
var interactive := true
var show_markers := true # warning markers over buildings (off for the menu backdrop)

var _seen_dirty := -1
var _nature := {} # mesh id -> MultiMeshInstance3D
var _deposits: Array[Node3D] = []
var _buildings := {} # building id -> {node, type}
var _walkers: Array = []
var _porters := {} # route id -> Array[MeshInstance3D]
var _scouts: Array[MeshInstance3D] = []
var _panning := false
var _rotating := false
var _grab := Vector3.ZERO
var _rot_from := 0.0
var _rot_yaw := 0.0


func setup(g, w: World) -> void:
	game = g
	world = w
	_setup_environment()
	terrain.setup(w)
	add_child(terrain)
	overlay.view = self
	add_child(overlay)
	camera.fov = 30.0
	camera.near = 0.5
	camera.far = 400.0
	add_child(camera)
	camera.make_current()
	var home := w.home_valley()
	center_on(home.cx, home.cy)
	sync()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d9cdb2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b9c4d6")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_light_color = Color("c9cdd0")
	env.fog_density = 0.0015
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun.light_color = Color("ffe9c8")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.85
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 140.0
	sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-20.0), 0.0)
	add_child(sun)


# ---------------------------------------------------------------- camera

func center_on(tx: float, ty: float) -> void:
	target = Vector3(tx, 0.0, ty)
	_apply_camera()


func set_zoom(z: float, around_screen := Vector2(-1, -1)) -> void:
	var before = ground_under(around_screen) if around_screen.x >= 0 else null
	zoom = clampf(z, MIN_ZOOM, MAX_ZOOM)
	_apply_camera()
	if before != null:
		var after = ground_under(around_screen)
		if after != null:
			target += before - after
			_apply_camera()


func _zoom_t() -> float:
	return inverse_lerp(MIN_ZOOM, MAX_ZOOM, zoom)


func _apply_camera() -> void:
	var s := float(world.size)
	target.x = clampf(target.x, 4.0, s - 4.0)
	target.z = clampf(target.z, 4.0, s - 4.0)
	target.y = maxf(0.0, terrain.height_at(target.x, target.z)) if terrain.world else 0.0
	var t := _zoom_t()
	var dist := FAR * pow(NEAR / FAR, t)
	var pitch := deg_to_rad(lerpf(52.0, 30.0, t))
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	camera.position = target - fwd * dist * cos(pitch) + Vector3.UP * dist * sin(pitch)
	camera.look_at(target, Vector3.UP)


## Point on the ground (y = 0 plane refined against the terrain) under a screen position.
func ground_under(screen: Vector2):
	var o := camera.project_ray_origin(screen)
	var d := camera.project_ray_normal(screen)
	if d.y > -0.01:
		return null
	var h := 0.0
	var p := o
	for i in 5:
		p = o + d * ((h - o.y) / d.y)
		h = terrain.height_at(p.x, p.z)
	return p


func screen_to_tile(screen: Vector2) -> Vector2i:
	var p = ground_under(screen)
	if p == null:
		return Vector2i(-1, -1)
	return Vector2i(floori(p.x), floori(p.z))


## Screen position of a tile centre (for UI markers).
func tile_to_screen(tx: float, ty: float) -> Vector2:
	return camera.unproject_position(Vector3(tx, terrain.height_at(tx, ty), ty))


func _process(delta: float) -> void:
	if world == null:
		return
	if world.dirty != _seen_dirty:
		sync()
	_update_walkers(delta)
	_update_porters(delta)
	overlay.redraw()
	if interactive:
		_keyboard(delta)


func _keyboard(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): dir.y += 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): dir.x += 1
	if Settings.data.edge_scroll and DisplayServer.window_is_focused():
		var m := get_viewport().get_mouse_position()
		var vs := get_viewport().get_visible_rect().size
		if m.x < 8: dir.x -= 1
		if m.x > vs.x - 8: dir.x += 1
		if m.y < 8: dir.y += 1
		if m.y > vs.y - 8: dir.y -= 1
	var turn := 0.0
	if Input.is_physical_key_pressed(KEY_Q): turn -= 1.0
	if Input.is_physical_key_pressed(KEY_E): turn += 1.0
	if dir == Vector2.ZERO and turn == 0.0:
		return
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var dist := FAR * pow(NEAR / FAR, _zoom_t())
	var speed := dist * 0.9 * float(Settings.data.scroll_speed)
	target += (fwd * dir.y + right * dir.x).normalized() * speed * delta if dir != Vector2.ZERO else Vector3.ZERO
	yaw += turn * delta * 1.6
	_apply_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				var up := mb.button_index == MOUSE_BUTTON_WHEEL_UP
				if Settings.data.invert_zoom:
					up = not up
				set_zoom(zoom * (1.1 if up else 1.0 / 1.1), mb.position)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_rotating = mb.pressed
			_rot_from = mb.position.x
			_rot_yaw = yaw
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT and game.tool.kind == "select":
			_start_pan(mb)
			return
		var tile := screen_to_tile(mb.position)
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT and game.tool.kind == "select":
				var i := world.idx(tile.x, tile.y) if world.inside(tile.x, tile.y) else -1
				if i < 0 or world.bmap[i] == 0:
					_start_pan(mb) # dragging empty ground pans the view
			game.pointer_down(tile, mb.button_index)
		else:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_panning = false
			game.pointer_up(tile, mb.button_index)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _rotating:
			yaw = _rot_yaw + (mm.position.x - _rot_from) * 0.006
			_apply_camera()
		elif _panning:
			var p = ground_under(mm.position)
			if p != null:
				target += _grab - p
				_apply_camera()
		game.pointer_move(screen_to_tile(mm.position))


func _start_pan(mb: InputEventMouseButton) -> void:
	_panning = mb.pressed
	var p = ground_under(mb.position)
	if p != null:
		_grab = p
	else:
		_panning = false


# ---------------------------------------------------------------- world sync

func sync() -> void:
	_seen_dirty = world.dirty
	reveal = _compute_reveal()
	terrain.refresh(reveal)
	_sync_nature()
	_sync_buildings()
	_spawn_walkers()


func _compute_reveal() -> PackedFloat32Array:
	var w := world
	var n := w.size * w.size
	var dist := PackedInt32Array()
	dist.resize(n)
	dist.fill(99)
	var q: Array[int] = []
	for i in n:
		var v := w.valley[i]
		var vis: bool = (v >= 0 and w.valleys[v].discovered) or (w.terrain[i] == World.PASS and w.passes[w.pass_of[i]].discovered)
		if vis:
			dist[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		var d := dist[i]
		if d >= 6:
			continue
		var x := i % w.size
		var y := i / w.size
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + o.x
			var ny: int = y + o.y
			if not w.inside(nx, ny):
				continue
			var j := w.idx(nx, ny)
			if dist[j] > d + 1:
				dist[j] = d + 1
				q.append(j)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = 1.0 if dist[i] == 0 else maxf(0.0, 1.0 - dist[i] / 6.5)
	return out


func _sync_nature() -> void:
	var w := world
	var s := w.seed
	var lists := {"nature/conifer": [], "nature/broadleaf": [], "nature/bush": [], "nature/hazel": [], "nature/rock": []}
	for i in w.size * w.size:
		if reveal[i] < 0.35:
			continue
		var x := i % w.size
		var y := i / w.size
		var h := SimNoise.hash2(x, y, s + 101)
		var h2 := SimNoise.hash2(x, y, s + 202)
		var free := w.bmap[i] == 0 and not w.road[i]
		match w.nature[i] if free else World.N_NONE:
			World.N_TREE:
				var pine := SimNoise.fbm(x * 0.1, y * 0.1, s + 61) > 0.52
				lists["nature/conifer" if pine else "nature/broadleaf"].append(_xf(x + 0.3 + h * 0.4, y + 0.3 + h2 * 0.4, 0.85 + h2 * 0.5, h))
				if h > 0.45:
					var pine2 := pine if h2 < 0.7 else not pine
					lists["nature/conifer" if pine2 else "nature/broadleaf"].append(_xf(x + 0.15 + h2 * 0.3, y + 0.6 + h * 0.3, 0.7 + h * 0.4, h2))
			World.N_BUSH:
				lists["nature/bush" if h2 < 0.6 else "nature/hazel"].append(_xf(x + 0.5, y + 0.5, 0.9 + h * 0.4, h2))
			World.N_ROCK:
				lists["nature/rock"].append(_xf(x + 0.5, y + 0.5, 0.9 + h * 0.6, h2))
		# pines on the lower mountain slopes
		if w.terrain[i] == World.MOUNTAIN and terrain.depth[i] <= 3 and h > 0.5:
			lists["nature/conifer"].append(_xf(x + 0.2 + h2 * 0.6, y + 0.2 + h * 0.6, 0.9 + h2 * 0.5, h))
	for id in lists:
		var mmi: MultiMeshInstance3D = _nature.get(id)
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.multimesh = MultiMesh.new()
			mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			mmi.multimesh.use_colors = true
			mmi.multimesh.mesh = Models.mesh(id)
			add_child(mmi)
			_nature[id] = mmi
		var mm := mmi.multimesh
		var list: Array = lists[id]
		mm.instance_count = list.size()
		for k in list.size():
			mm.set_instance_transform(k, list[k].xf)
			mm.set_instance_color(k, list[k].col)
	_sync_deposits()


func _xf(fx: float, fz: float, scale: float, h: float) -> Dictionary:
	var b := Basis(Vector3.UP, h * TAU).scaled(Vector3(scale, scale * (0.9 + h * 0.25), scale))
	var v := 0.9 + h * 0.2
	return {"xf": Transform3D(b, Vector3(fx, terrain.height_at(fx, fz) - 0.03, fz)), "col": Color(v, v, v * 0.97)}


func _sync_deposits() -> void:
	for n in _deposits:
		n.queue_free()
	_deposits.clear()
	var w := world
	for i in w.deposit:
		var dep: String = w.deposit[i]
		if w.deposit.get(i - 1, "") == dep or w.deposit.get(i - w.size, "") == dep:
			continue
		if reveal[i] < 0.35 or w.bmap[i] != 0:
			continue
		var x: int = i % w.size
		var y: int = i / w.size
		var mi := MeshInstance3D.new()
		mi.mesh = Models.mesh("nature/deposit_" + dep)
		mi.position = Vector3(x + 1, terrain.height_at(x + 1, y + 1), y + 1)
		add_child(mi)
		_deposits.append(mi)


func _sync_buildings() -> void:
	var w := world
	for id in _buildings.keys():
		if not w.buildings.has(id):
			_buildings[id].node.queue_free()
			_buildings.erase(id)
	for b in w.buildings.values():
		var entry = _buildings.get(b.id)
		if entry != null and entry.type == b.type:
			continue
		if entry != null:
			entry.node.queue_free()
		var node := BuildingNode.new()
		add_child(node)
		node.setup(self, b)
		_buildings[b.id] = {"node": node, "type": b.type}
	# buildings in unexplored valleys stay hidden under the mist
	for id in _buildings:
		var b: Dictionary = w.buildings[id]
		_buildings[id].node.visible = reveal[w.idx(b.x, b.y)] > 0.35


## Which way a building's door should face: towards an adjacent road, preferably towards the camera.
func facing(b: Dictionary) -> float:
	var def: Dictionary = Content.BUILDING[b.type]
	var sw := int(def.size[0])
	var sh := int(def.size[1])
	var sides := [[Vector2i(0, -1), PI], [Vector2i(-1, 0), -PI / 2.0], [Vector2i(0, 1), 0.0], [Vector2i(1, 0), PI / 2.0]]
	for side in sides:
		var d: Vector2i = side[0]
		for k in maxi(sw, sh):
			var t := Vector2i(b.x + (k if d.x == 0 else (-1 if d.x < 0 else sw)), b.y + (k if d.y == 0 else (-1 if d.y < 0 else sh)))
			if world.inside(t.x, t.y) and world.road[world.idx(t.x, t.y)]:
				return side[1]
	return PI


# ---------------------------------------------------------------- people

func _person(id: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.mesh(id)
	mi.scale = Vector3.ONE * 1.35
	add_child(mi)
	return mi


func _spawn_walkers() -> void:
	var w := world
	var roads := {} # owner -> Array[int]
	for i in w.size * w.size:
		if w.road[i] and w.valley[i] >= 0:
			var owner = w.valleys[w.valley[i]].owner
			if owner == null:
				continue
			if not roads.has(owner):
				roads[owner] = []
			roads[owner].append(i)
	var want := []
	for owner in roads:
		var houses := w.buildings.values().filter(func(b): return b.owner == owner and b.has("tier"))
		var n := mini(80, mini(int(houses.size() * 1.3), roads[owner].size()))
		for k in n:
			want.append({"owner": owner, "tier": houses[k % houses.size()].tier})
	while _walkers.size() > want.size():
		_walkers.pop_back().node.queue_free()
	while _walkers.size() < want.size():
		var spec: Dictionary = want[_walkers.size()]
		var tiles: Array = roads[spec.owner]
		var i: int = tiles[randi() % tiles.size()]
		var p := Vector2i(i % w.size, i / w.size)
		_walkers.append({"node": _person("people/" + spec.tier), "at": p, "from": p, "t": randf(), "side": randf_range(-0.22, 0.22)})


func _update_walkers(delta: float) -> void:
	var w := world
	for wk in _walkers:
		wk.t += delta * 0.8
		if wk.t >= 1.0:
			wk.t = 0.0
			var opts := []
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = wk.at + o
				if w.inside(n.x, n.y) and w.road[w.idx(n.x, n.y)] and n != wk.from:
					opts.append(n)
			if opts.is_empty():
				var back: Vector2i = wk.from
				wk.from = wk.at
				wk.at = back
			else:
				wk.from = wk.at
				wk.at = opts[randi() % opts.size()]
			if not w.road[w.idx(wk.at.x, wk.at.y)]:
				wk.at = wk.from
		var a := Vector2(wk.from) + Vector2(0.5, 0.5)
		var b := Vector2(wk.at) + Vector2(0.5, 0.5)
		var f := a.lerp(b, wk.t)
		var dir := (b - a).normalized()
		f += Vector2(-dir.y, dir.x) * wk.side
		_place(wk.node, f, dir, wk.t)


func _place(n: Node3D, f: Vector2, dir: Vector2, phase: float) -> void:
	var bob := absf(sin(phase * TAU * 2.0)) * 0.03
	n.position = Vector3(f.x, terrain.height_at(f.x, f.y) + bob, f.y)
	if dir != Vector2.ZERO:
		n.rotation.y = atan2(dir.x, dir.y)
	var r := reveal[world.idx(clampi(int(f.x), 0, world.size - 1), clampi(int(f.y), 0, world.size - 1))]
	n.visible = r > 0.3


func _update_porters(_delta: float) -> void:
	var w := world
	var live := {}
	for r in w.routes:
		live[r.id] = true
		if not _porters.has(r.id):
			var list: Array[MeshInstance3D] = []
			for k in 3:
				list.append(_person("people/porter"))
			_porters[r.id] = list
		if r.path.size() < 2:
			continue
		var k := 0
		for s in _porters[r.id]:
			var pos := clampf(r.pos - r.dir * k * 0.8, 0.0, r.path.size() - 1)
			var i0 := floori(pos)
			var i1 := mini(r.path.size() - 1, i0 + 1)
			var a := Vector2(r.path[i0] % w.size, r.path[i0] / w.size) + Vector2(0.5, 0.5)
			var b := Vector2(r.path[i1] % w.size, r.path[i1] / w.size) + Vector2(0.5, 0.5)
			_place(s, a.lerp(b, pos - i0), (b - a).normalized() * signf(r.dir), pos)
			k += 1
	for id in _porters.keys():
		if not live.has(id):
			for s in _porters[id]:
				s.queue_free()
			_porters.erase(id)
	# scouts walking a pass
	var ex = w.expedition
	if ex == null:
		for s in _scouts:
			s.queue_free()
		_scouts.clear()
		return
	if _scouts.is_empty():
		for k in 2:
			_scouts.append(_person("people/scout"))
	var p: Dictionary = w.passes[ex.pass]
	var tiles: Array = p.tiles.duplicate()
	if p.a != ex.from:
		tiles.reverse()
	var prog: float = 1.0 - ex.time_left / ex.total
	var along := prog * 2.0 if prog < 0.5 else (1.0 - prog) * 2.0
	var fi := along * (tiles.size() - 1)
	var i0 := floori(fi)
	var i1 := mini(tiles.size() - 1, i0 + 1)
	var a := Vector2(tiles[i0] % w.size, tiles[i0] / w.size) + Vector2(0.5, 0.5)
	var b := Vector2(tiles[i1] % w.size, tiles[i1] / w.size) + Vector2(0.5, 0.5)
	for k in _scouts.size():
		var f := a.lerp(b, fi - i0) + Vector2(-0.25 * k, 0.15 * k)
		_place(_scouts[k], f, (b - a).normalized() * (1.0 if prog < 0.5 else -1.0), fi)
		_scouts[k].visible = true


## A building's model plus its living details (fire, smoke, warning marker, rival flag).
class BuildingNode extends Node3D:
	var b: Dictionary
	var warn := MeshInstance3D.new()
	var _view
	var fire_light: OmniLight3D
	var t := 0.0
	var _puffs: Node3D
	var _puff_alpha := 0.5

	func setup(view, building: Dictionary) -> void:
		b = building
		var def: Dictionary = Content.BUILDING[b.type]
		var sw := float(def.size[0])
		var sh := float(def.size[1])
		var cx: float = b.x + sw / 2.0
		var cz: float = b.y + sh / 2.0
		position = Vector3(cx, view.terrain.footprint_height(b.x, b.y, int(sw), int(sh)), cz)
		var model := Models.building_node(b.type)
		model.rotation.y = view.facing(b)
		add_child(model)
		if b.owner != World.PLAYER:
			var flag := MeshInstance3D.new()
			var k := Models.Kit.new(7)
			k.cylinder(Vector3.ZERO, 0.035, 0.03, 1.5, 5, Models.WOOD_DARK)
			k.quad(Vector3(0, 1.45, 0), Vector3(0.45, 1.4, 0), Vector3(0.45, 1.15, 0), Vector3(0, 1.1, 0), Color("b0442c"), true)
			flag.mesh = k.commit(Models.material())
			flag.position = Vector3(-sw * 0.4, 0, -sh * 0.4)
			add_child(flag)
		var fire: bool = def.style == "fire" or def.style == "dance"
		if fire:
			add_child(_flames())
			fire_light = OmniLight3D.new()
			fire_light.light_color = Color("ffb060")
			fire_light.omni_range = 3.5
			fire_light.light_energy = 1.4
			fire_light.position = Vector3(0, 0.5, 0)
			add_child(fire_light)
		var smoky: bool = (def.category == "residence" and def.style != "tent") or def.style == "kiln" or def.style == "storage" or fire
		if smoky:
			var at := Vector3(0, 0.4, 0) if fire else Vector3(0.25, 1.3 if def.style != "kiln" else 1.0, -0.2)
			add_child(_smoke(at, def.style == "storage"))
		_view = view
		warn.mesh = Models.mesh("misc/warning")
		warn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		warn.position = Vector3(0, 2.6, 0)
		warn.visible = false
		add_child(warn)

	func _process(delta: float) -> void:
		t += delta
		if b.owner == World.PLAYER:
			var def: Dictionary = Content.BUILDING[b.type]
			var bad: bool = (def.category == "production" and b.status != "ok" and b.status != "full") or (not b.connected and def.category != "infrastructure")
			warn.visible = bad and _view.show_markers
			if warn.visible:
				warn.position.y = 2.4 + sin(t * 3.0) * 0.1
				warn.rotation.y = t * 1.5
		if _puffs:
			_animate_smoke()
		if fire_light:
			fire_light.light_energy = 1.3 + sin(t * 13.0) * 0.15 + sin(t * 7.3) * 0.1

	func _flames() -> CPUParticles3D:
		var p := CPUParticles3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.22, 0.32)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = Art.tex("brush/dab")
		q.material = m
		p.mesh = q
		p.amount = 24
		p.lifetime = 0.7
		p.position = Vector3(0, 0.12, 0)
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.12
		p.direction = Vector3.UP
		p.spread = 10.0
		p.gravity = Vector3(0, 1.2, 0)
		p.initial_velocity_min = 0.3
		p.initial_velocity_max = 0.6
		var grad := Gradient.new()
		grad.set_color(0, Color(1.0, 0.85, 0.4, 0.9))
		grad.set_color(1, Color(0.9, 0.25, 0.05, 0.0))
		p.color_ramp = grad
		var c := Curve.new()
		c.add_point(Vector2(0, 1.0))
		c.add_point(Vector2(1, 0.3))
		p.scale_amount_curve = c
		return p

	## Smoke: a few soft puffs that rise, grow and fade (cheap and renderer-independent).
	func _smoke(at: Vector3, faint: bool) -> Node3D:
		var root := Node3D.new()
		root.position = at
		for k in 6:
			var puff := Sprite3D.new()
			puff.texture = Art.tex("brush/dab")
			puff.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			puff.shaded = false
			puff.pixel_size = 0.008
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			puff.set_meta("phase", k / 6.0)
			root.add_child(puff)
		_puffs = root
		_puff_alpha = 0.45 if faint else 0.7
		return root

	func _animate_smoke() -> void:
		for puff in _puffs.get_children():
			var ph := fmod(t * 0.22 + float(puff.get_meta("phase")), 1.0)
			puff.position = Vector3(ph * 0.6, ph * 2.4, ph * 0.25)
			var sc := lerpf(0.35, 1.2, ph)
			puff.scale = Vector3(sc, sc, sc)
			puff.modulate = Color(0.93, 0.91, 0.88, _puff_alpha * (1.0 - ph) * smoothstep(0.0, 0.12, ph))
