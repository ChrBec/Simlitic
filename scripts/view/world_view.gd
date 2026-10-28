class_name WorldView
extends Node2D
## Renders the world: painted ground chunks, y-sorted sprites (nature, mountains, buildings, people),
## build previews, camera and map input.

signal tile_clicked(tile: Vector2i, button: int)

var game # Game
var world: World
var reveal := PackedFloat32Array()
var depth := PackedByteArray()

var ground := Node2D.new()
var overlay := WorldOverlay.new()
var objects := Node2D.new()
var camera := Camera2D.new()
var chunks: Array[GroundChunk] = []
var _seen_dirty := -1
var _nature_sprites := {} # tile index -> Array[Sprite2D]
var _peak_sprites := {}
var _building_sprites := {} # building id -> {node, type}
var _walkers: Array = []
var _porters := {} # route id -> Array[Sprite2D]
var _scouts: Array[Sprite2D] = []
var _panning := false
var _pan_from := Vector2.ZERO
var _cam_from := Vector2.ZERO
var zoom := 1.0
var interactive := true


func setup(g, w: World) -> void:
	game = g
	world = w
	add_child(ground)
	add_child(objects)
	objects.y_sort_enabled = true
	add_child(overlay)
	overlay.view = self
	overlay.z_index = 5
	add_child(camera)
	camera.make_current()
	depth = _mountain_depth()
	var n := ceili(float(w.size) / GroundChunk.N)
	for cy in n:
		for cx in n:
			var c := GroundChunk.new()
			c.setup(self, cx, cy)
			ground.add_child(c)
			chunks.append(c)
	var home := w.home_valley()
	center_on(home.cx, home.cy)
	sync()


func center_on(tx: float, ty: float) -> void:
	camera.position = Art.iso(tx, ty)


func _process(delta: float) -> void:
	if world == null:
		return
	if world.dirty != _seen_dirty:
		sync()
	_update_walkers(delta)
	_update_porters()
	overlay.queue_redraw()
	if interactive:
		_keyboard_pan(delta)


# ---------------------------------------------------------------- world sync

func sync() -> void:
	_seen_dirty = world.dirty
	reveal = _compute_reveal()
	for c in chunks:
		c.refresh()
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
		if d >= 5:
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
		out[i] = 1.0 if dist[i] == 0 else maxf(0.0, 1.0 - dist[i] / 5.5)
	return out


func _mountain_depth() -> PackedByteArray:
	var w := world
	var n := w.size * w.size
	var d := PackedByteArray()
	d.resize(n)
	d.fill(255)
	var q: Array[int] = []
	for i in n:
		if w.terrain[i] != World.MOUNTAIN:
			d[i] = 0
			q.append(i)
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		var x := i % w.size
		var y := i / w.size
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + o.x
			var ny: int = y + o.y
			if not w.inside(nx, ny):
				continue
			var j := w.idx(nx, ny)
			if d[j] > d[i] + 1:
				d[j] = d[i] + 1
				q.append(j)
	return d


## Ground colour at fractional tile coordinates – continuous, so brush strokes blend across tiles.
func color_at(fx: float, fy: float, x: int, y: int) -> Color:
	var w := world
	var i := w.idx(x, y)
	var t := w.terrain[i]
	var n := SimNoise.fbm(fx * 0.13, fy * 0.13, w.seed + 5)
	if t == World.WATER:
		return Pal.WATER_DEEP.lerp(Pal.WATER, minf(1.0, count_around(x, y, 2, World.WATER, true) / 6.0 + n * 0.25))
	if t == World.GRASS:
		var vd: Dictionary = w.valleys[w.valley[i]]
		var c: Color = Pal.VALLEY_TINT.get(vd.def, Pal.GRASS)
		c = c.lerp(Pal.GRASS_LIGHT, maxf(0.0, n - 0.42) * 1.5)
		c = c.lerp(Pal.GRASS_DARK, maxf(0.0, 0.45 - n) * 1.2)
		var m := SimNoise.fbm(fx * 0.07, fy * 0.07, w.seed + 9)
		if m > 0.58:
			c = c.lerp(Pal.MEADOW, minf(0.6, (m - 0.58) * 2.0))
		if "clay" in vd.fertilities:
			var k := SimNoise.fbm(fx * 0.2, fy * 0.2, w.seed + 13)
			if k > 0.62:
				c = c.lerp(Pal.CLAY, minf(0.4, (k - 0.62) * 2.0))
		return c
	var dd := depth[i]
	var rock := Pal.ROCK.lerp(Pal.ROCK_DARK, minf(1.0, dd / 10.0) * 0.6 + n * 0.25)
	return rock.lerp(Pal.GRASS_DARK, 0.3) if dd <= 1 else rock


## Counts neighbours of a terrain kind (or, with `invert`, of any other kind).
func count_around(x: int, y: int, r: int, kind: int, invert := false) -> int:
	var n := 0
	for yy in range(y - r, y + r + 1):
		for xx in range(x - r, x + r + 1):
			if world.inside(xx, yy):
				var is_kind := world.terrain[world.idx(xx, yy)] == kind
				if is_kind != invert:
					n += 1
	return n


func _near_trail(x: int, y: int) -> bool:
	for yy in range(y - 1, y + 2):
		for xx in range(x - 1, x + 2):
			if world.inside(xx, yy) and world.terrain[world.idx(xx, yy)] == World.PASS:
				return true
	return false


func _sync_nature() -> void:
	var w := world
	for i in w.size * w.size:
		var rv := reveal[i]
		var x := i % w.size
		var y := i / w.size
		var want := rv > 0.02 and w.bmap[i] == 0 and not w.road[i] and w.nature[i] != World.N_NONE
		var have: bool = _nature_sprites.has(i)
		if want and not have:
			_nature_sprites[i] = _make_nature(i, x, y)
		elif not want and have:
			for s in _nature_sprites[i]:
				s.queue_free()
			_nature_sprites.erase(i)
		if have and want:
			for s in _nature_sprites[i]:
				s.modulate.a = rv
		# deposits and mountain peaks appear once revealed
		if rv > 0.02 and not _peak_sprites.has(i):
			var list := []
			var h := SimNoise.hash2(x, y, w.seed + 101)
			if w.terrain[i] == World.MOUNTAIN and (x + y) % 2 == 0 and depth[i] >= 1 and h < 0.7 and not _near_trail(x, y):
				var size := minf(1.0, (depth[i] - 1) / 5.0) * 0.75 + SimNoise.hash2(x, y, w.seed + 7) * 0.25
				var sz := clampi(roundi(size * 4.0), 0, 4) * 25
				var id := "nature/peak_%d_%d" % [int(h * 30) % 6, sz]
				var c := Art.iso(x + 0.5, y + 0.5) + Vector2((h - 0.35) * 20, Art.TH * 0.6)
				list.append(_sprite(id, c, c))
			if w.deposit.has(i) and w.bmap[i] == 0:
				var dep: String = w.deposit[i]
				var left: String = w.deposit.get(i - 1, "")
				var up: String = w.deposit.get(i - w.size, "")
				if left != dep and up != dep:
					var c := Art.iso(x + 1, y + 1)
					list.append(_sprite("nature/deposit_" + dep, c, c))
			for s in list:
				s.modulate.a = minf(1.0, rv * 1.4)
			_peak_sprites[i] = list
		elif _peak_sprites.has(i):
			for s in _peak_sprites[i]:
				if w.bmap[i] != 0 and w.deposit.has(i):
					s.visible = false
				s.modulate.a = minf(1.0, rv * 1.4)


func _make_nature(i: int, x: int, y: int) -> Array:
	var w := world
	var h := SimNoise.hash2(x, y, w.seed + 101)
	var c := Art.iso(x + 0.5, y + 0.5)
	var out := []
	match w.nature[i]:
		World.N_TREE:
			var p := c + Vector2((h - 0.5) * 14, 4)
			out.append(_sprite("nature/tree_%d" % (int(h * 9) % 9), p, p))
			if h > 0.45:
				var p2 := c + Vector2(-12 + h * 6, -4)
				out.append(_sprite("nature/tree_%d" % (int(h * 97) % 9), p2, p2))
		World.N_BUSH:
			out.append(_sprite("nature/bush_%d" % (int(h * 4) % 4), c + Vector2(0, 3), c + Vector2(0, 3)))
		World.N_ROCK:
			out.append(_sprite("nature/rock_%d" % (int(h * 3) % 3), c + Vector2(0, 3), c + Vector2(0, 3)))
	for s in out:
		s.modulate.a = reveal[i]
	return out


func _sprite(id: String, ground_pt: Vector2, sort: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	Art.setup_sprite(s, id, ground_pt, sort)
	objects.add_child(s)
	return s


func _sync_buildings() -> void:
	var w := world
	for id in _building_sprites.keys():
		if not w.buildings.has(id):
			_building_sprites[id].node.queue_free()
			_building_sprites.erase(id)
	for b in w.buildings.values():
		var entry = _building_sprites.get(b.id)
		if entry != null and entry.type == b.type:
			continue
		if entry != null:
			entry.node.queue_free()
		var node := BuildingNode.new()
		node.setup(self, b)
		objects.add_child(node)
		_building_sprites[b.id] = {"node": node, "type": b.type}


# ---------------------------------------------------------------- people

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
		var n := mini(70, mini(int(houses.size() * 1.2), roads[owner].size()))
		for k in n:
			want.append({"owner": owner, "tier": houses[k % houses.size()].tier})
	while _walkers.size() > want.size():
		_walkers.pop_back().node.queue_free()
	while _walkers.size() < want.size():
		var spec: Dictionary = want[_walkers.size()]
		var tiles: Array = roads[spec.owner]
		var i: int = tiles[randi() % tiles.size()]
		var p := Vector2i(i % w.size, i / w.size)
		var s := _sprite("people/" + spec.tier, Vector2.ZERO, Vector2.ZERO)
		_walkers.append({"node": s, "at": p, "from": p, "t": randf(), "id": "people/" + spec.tier})


func _update_walkers(delta: float) -> void:
	var w := world
	for wk in _walkers:
		wk.t += delta * 1.1
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
		var f: Vector2 = Vector2(wk.from).lerp(Vector2(wk.at), wk.t)
		var p := Art.iso(f.x + 0.5, f.y + 0.5)
		Art.setup_sprite(wk.node, wk.id, p, p)


func _update_porters() -> void:
	var w := world
	var live := {}
	for r in w.routes:
		live[r.id] = true
		if not _porters.has(r.id):
			var list: Array[Sprite2D] = []
			for k in 3:
				list.append(_sprite("people/porter", Vector2.ZERO, Vector2.ZERO))
			_porters[r.id] = list
		if r.path.size() < 2:
			continue
		var k := 0
		for s in _porters[r.id]:
			var pos := clampf(r.pos - r.dir * k * 0.8, 0.0, r.path.size() - 1)
			var i0 := floori(pos)
			var i1 := mini(r.path.size() - 1, i0 + 1)
			var a := Vector2(r.path[i0] % w.size, r.path[i0] / w.size)
			var b := Vector2(r.path[i1] % w.size, r.path[i1] / w.size)
			var f := a.lerp(b, pos - i0)
			var p := Art.iso(f.x + 0.5, f.y + 0.5) + Vector2((k - 1) * 3, 0)
			Art.setup_sprite(s, "people/porter", p, p)
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
			_scouts.append(_sprite("people/scout", Vector2.ZERO, Vector2.ZERO))
	var p: Dictionary = w.passes[ex.pass]
	var tiles: Array = p.tiles if p.a == ex.from else p.tiles.duplicate()
	if p.a != ex.from:
		tiles.reverse()
	var prog: float = 1.0 - ex.time_left / ex.total
	var along := prog * 2.0 if prog < 0.5 else (1.0 - prog) * 2.0
	var ti: int = tiles[mini(tiles.size() - 1, int(along * tiles.size()))]
	var c := Art.iso(ti % w.size + 0.5, ti / w.size + 0.5)
	for k in _scouts.size():
		var q := c + Vector2(-6 * k, 3 * k)
		Art.setup_sprite(_scouts[k], "people/scout", q, q)


# ---------------------------------------------------------------- camera & input

func screen_to_tile(screen: Vector2) -> Vector2i:
	var world_pos := get_canvas_transform().affine_inverse() * screen
	var t := Art.un_iso(world_pos)
	return Vector2i(floori(t.x), floori(t.y))


func set_zoom(z: float, around_screen := Vector2(-1, -1)) -> void:
	var before := get_canvas_transform().affine_inverse() * around_screen if around_screen.x >= 0 else Vector2.ZERO
	zoom = clampf(z, 0.35, 2.2)
	camera.zoom = Vector2(zoom, zoom)
	if around_screen.x >= 0:
		force_update_transform()
		camera.force_update_scroll()
		var after := get_canvas_transform().affine_inverse() * around_screen
		camera.position += before - after
	_clamp_camera()


func _clamp_camera() -> void:
	var s := float(world.size)
	camera.position.x = clampf(camera.position.x, -s * Art.TW / 2.0, s * Art.TW / 2.0)
	camera.position.y = clampf(camera.position.y, 0.0, s * Art.TH)


func _keyboard_pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): dir.x += 1
	if Settings.data.edge_scroll and DisplayServer.window_is_focused():
		var m := get_viewport().get_mouse_position()
		var vs := get_viewport().get_visible_rect().size
		if m.x < 8: dir.x -= 1
		if m.x > vs.x - 8: dir.x += 1
		if m.y < 8: dir.y -= 1
		if m.y > vs.y - 8: dir.y += 1
	if dir != Vector2.ZERO:
		camera.position += dir.normalized() * 700.0 * delta * float(Settings.data.scroll_speed) / zoom
		_clamp_camera()


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
				set_zoom(zoom * (1.12 if up else 1.0 / 1.12), mb.position)
			get_viewport().set_input_as_handled()
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE or (mb.button_index == MOUSE_BUTTON_RIGHT and game.tool.kind == "select"):
			_panning = mb.pressed
			_pan_from = mb.position
			_cam_from = camera.position
			return
		var tile := screen_to_tile(mb.position)
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT and game.tool.kind == "select":
				var i := world.idx(tile.x, tile.y) if world.inside(tile.x, tile.y) else -1
				if i < 0 or world.bmap[i] == 0:
					# dragging empty ground pans the view
					_panning = true
					_pan_from = mb.position
					_cam_from = camera.position
			game.pointer_down(tile, mb.button_index)
		else:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_panning = false
			game.pointer_up(tile, mb.button_index)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _panning:
			camera.position = _cam_from - (mm.position - _pan_from) / zoom
			_clamp_camera()
		game.pointer_move(screen_to_tile(mm.position))


## A building's sprite plus its living details (fire, smoke, warning markers).
class BuildingNode extends Node2D:
	var view
	var b: Dictionary
	var sprite := Sprite2D.new()
	var flag: Sprite2D
	var warn := Sprite2D.new()
	var fire := false
	var t := 0.0

	func setup(v, building: Dictionary) -> void:
		view = v
		b = building
		var def: Dictionary = Content.BUILDING[b.type]
		var w := float(def.size[0])
		var h := float(def.size[1])
		position = Art.iso(b.x + w / 2.0, b.y + h / 2.0)
		add_child(sprite)
		Art.setup_sprite(sprite, "buildings/" + b.type, Art.iso(b.x, b.y), position)
		sprite.position = Vector2.ZERO
		sprite.show_behind_parent = true # flames (drawn by this node) go on top
		if b.owner != World.PLAYER:
			flag = Sprite2D.new()
			add_child(flag)
			var fp := Art.iso(b.x + w * 0.15, b.y + h * 0.85)
			Art.setup_sprite(flag, "misc/flag_rival", fp, position)
			flag.position = Vector2.ZERO
		fire = def.style == "fire" or def.style == "dance"
		var smoky: bool = (def.category == "residence" and def.style != "tent") or def.style == "kiln" or def.style == "storage" or fire
		if smoky:
			var p := CPUParticles2D.new()
			p.texture = Art.tex("brush/dab")
			p.amount = 10
			p.lifetime = 3.5
			p.position = Art.iso(b.x + w * 0.55, b.y + h * 0.45) - position + Vector2(0, -26 if def.style == "kiln" or fire else -44)
			p.direction = Vector2(0.3, -1)
			p.spread = 12
			p.gravity = Vector2(6, -4)
			p.initial_velocity_min = 10
			p.initial_velocity_max = 18
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.22
			var curve := Curve.new()
			curve.add_point(Vector2(0, 0.4))
			curve.add_point(Vector2(1, 1.6))
			p.scale_amount_curve = curve
			var grad := Gradient.new()
			grad.set_color(0, Color(0.85, 0.82, 0.77, 0.45 if def.style != "storage" else 0.25))
			grad.set_color(1, Color(0.85, 0.82, 0.77, 0.0))
			p.color_ramp = grad
			add_child(p)
		warn.texture = Art.tex("misc/warning")
		warn.scale = Vector2(0.4, 0.4)
		warn.position = Vector2(0, -78)
		warn.visible = false
		add_child(warn)

	func _process(delta: float) -> void:
		t += delta
		if b.owner == World.PLAYER:
			var def: Dictionary = Content.BUILDING[b.type]
			var bad: bool = (def.category == "production" and b.status != "ok" and b.status != "full") or (not b.connected and def.category != "infrastructure")
			warn.visible = bad
			if bad:
				warn.position.y = -78 + sin(t * 3.0) * 2.0
		if fire:
			queue_redraw()

	func _draw() -> void:
		if not fire:
			return
		var c := Vector2(0, 2)
		draw_colored_polygon(_ell(c, 34 + sin(t * 7) * 3, 16), Color(1, 0.75, 0.35, 0.18))
		for i in 4:
			var h := 12.0 + sin(t * 9 + i * 1.7) * 4.0 + i * 2.0
			var ox := (i - 1.5) * 3.0
			var col := Pal.FIRE if i < 2 else Pal.FIRE_CORE
			var pts := PackedVector2Array([c + Vector2(ox - 4, 0), c + Vector2(ox - 2 + sin(t * 11 + i) * 2, -h * 0.6), c + Vector2(ox + sin(t * 13 + i) * 2, -h), c + Vector2(ox + 3, -h * 0.5), c + Vector2(ox + 4, 0)])
			draw_colored_polygon(pts, Color(col, 0.9))

	func _ell(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts
