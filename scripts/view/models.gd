class_name Models
## Stylised low-poly 3D models, built in code from simple primitives with painted vertex colours.
## Every model can be replaced by a file: res://assets/models/<id>.glb (or .tscn/.res), e.g.
## assets/models/buildings/tent.glb, assets/models/nature/conifer.glb, assets/models/people/hunters.glb.
## Mods can drop the same paths into user://mods/models/. Units: 1 tile = 1 metre-ish unit,
## models stand on y = 0 and are centred on their footprint.

static var _mesh_cache := {}
static var _material: StandardMaterial3D


## Shared material for every procedural model: vertex colours, matte, soft wrap lighting.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 1.0
		_material.metallic_specular = 0.15
		_material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	return _material


## Scene file that overrides a procedural model, if one exists.
static func override_path(id: String) -> String:
	for base in ["user://mods/models/", "res://assets/models/"]:
		for ext in [".glb", ".gltf", ".tscn", ".scn"]:
			var p: String = base + id + ext
			if ResourceLoader.exists(p) or FileAccess.file_exists(p):
				return p
	return ""


## A node for a building: the override scene if present, otherwise the procedural mesh.
static func building_node(type: String) -> Node3D:
	var p := override_path("buildings/" + type)
	if p != "":
		var scene = load_scene(p)
		if scene is PackedScene:
			return scene.instantiate()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh("buildings/" + type)
	return mi


## A single Mesh for an id (used for MultiMesh nature, people, ghosts and icons).
static func mesh(id: String) -> Mesh:
	if _mesh_cache.has(id):
		return _mesh_cache[id]
	var m: Mesh = null
	var p := override_path(id)
	if p != "":
		m = _first_mesh(load_scene(p))
	if m == null:
		m = _build(id)
	_mesh_cache[id] = m
	return m


## Imported files load normally; glTF files dropped into the user mod folder are parsed at runtime.
static func load_scene(path: String) -> Resource:
	if path.begins_with("user://") and (path.ends_with(".glb") or path.ends_with(".gltf")):
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(path, state) != OK:
			return null
		var root := doc.generate_scene(state)
		var packed := PackedScene.new()
		packed.pack(root)
		root.free()
		return packed
	return load(path)


static func _first_mesh(res) -> Mesh:
	if res is Mesh:
		return res
	if res is PackedScene:
		var n: Node = res.instantiate()
		var found: Mesh = null
		var stack: Array[Node] = [n]
		while not stack.is_empty() and found == null:
			var c: Node = stack.pop_back()
			if c is MeshInstance3D:
				found = c.mesh
			stack.append_array(c.get_children())
		n.free()
		return found
	return null


static func _build(id: String) -> Mesh:
	var k := Kit.new(hash(id))
	var parts := id.split("/")
	match parts[0]:
		"buildings":
			var def: Dictionary = Content.BUILDING.get(parts[1], {})
			if not def.is_empty():
				_building(k, def)
		"nature":
			_nature(k, parts[1])
		"people":
			_person(k, parts[1])
		"misc":
			if parts[1] == "warning":
				# floating exclamation mark over buildings that lack something
				k.box(Vector3(0, 0.42, 0), Vector3(0.16, 0.5, 0.16), Color("e8a13a"))
				k.box(Vector3(0, 0.08, 0), Vector3(0.17, 0.17, 0.17), Color("e8a13a"))
	return k.commit(material())


# ---------------------------------------------------------------- palette

const THATCH := Color("9c7c42")
const THATCH_DARK := Color("8a6a36")
const WOOD := Color("7a5634")
const WOOD_DARK := Color("54392a")
const HIDE := Color("c49a6c")
const HIDE_DARK := Color("9a7048")
const STONE := Color("8e877c")
const STONE_DARK := Color("625c55")
const CLAY := Color("b8754a")
const EARTH := Color("8a6a46")
const LEAF := Color("5e8a3a")
const LEAF_DARK := Color("3f6a32")
const PINE := Color("355e3a")
const BERRY := Color("a8344a")


# ---------------------------------------------------------------- buildings

static func _building(k: Kit, def: Dictionary) -> void:
	var s := float(def.size[0])
	var accent := Color(def.get("accent", "#8a6a46"))
	var r := k.rng
	match def.style:
		"storage":
			k.disc(Vector3.ZERO, s * 0.47, 0.04, EARTH.lightened(0.1), 10)
			_shelter(k, Vector3(-0.3, 0, -0.2), 2.0, 1.4, 1.2, THATCH)
			for i in 4:
				k.box(Vector3(-0.8 + i * 0.42, 0.18, 0.75), Vector3(0.34, 0.36, 0.34), WOOD.lightened(r.randf() * 0.2), r.randf() * 0.4)
			_log_pile(k, Vector3(0.95, 0, -0.6), 0.7)
			for i in 3:
				_basket(k, Vector3(0.9 - i * 0.3, 0, 0.25 + (i % 2) * 0.15), [BERRY, THATCH, accent][i])
			k.cylinder(Vector3(1.2, 0, 1.15), 0.04, 0.04, 2.2, 5, WOOD_DARK)
			k.box(Vector3(1.42, 1.95, 1.15), Vector3(0.45, 0.3, 0.03), Color("b0442c"))
		"tent":
			_tipi(k, Vector3(-0.15, 0, -0.1), 0.72, 1.75, HIDE, accent)
			_tipi(k, Vector3(0.6, 0, 0.55), 0.38, 0.95, HIDE.darkened(0.08), accent)
			k.ring_stones(Vector3(0.55, 0, -0.55), 0.22, 7, STONE)
		"hut":
			k.dome(Vector3(0, 0, 0), 0.82, 1.05, WOOD.lightened(0.12), 9, 4)
			k.box(Vector3(0, 0.3, 0.78), Vector3(0.36, 0.6, 0.12), WOOD_DARK.darkened(0.4))
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				k.cylinder(Vector3(cos(a) * 0.7, 0.0, sin(a) * 0.7), 0.03, 0.02, 1.0, 4, WOOD_DARK, Vector3(-cos(a) * 0.25, 0, -sin(a) * 0.25))
			_log_pile(k, Vector3(0.75, 0, 0.6), 0.45)
		"cottage":
			k.cylinder(Vector3.ZERO, 0.78, 0.78, 0.62, 12, CLAY.lightened(0.15))
			k.cylinder(Vector3(0, 0.55, 0), 0.98, 0.0, 1.0, 12, THATCH)
			k.box(Vector3(0, 0.27, 0.78), Vector3(0.32, 0.54, 0.08), WOOD_DARK.darkened(0.3))
			k.box(Vector3(0.75, 0.25, -0.55), Vector3(0.4, 0.5, 0.4), WOOD.lightened(0.1))
		"longhouse":
			k.box(Vector3(0, 0.32, 0), Vector3(1.8, 0.64, 1.0), CLAY.lightened(0.05))
			k.gable(Vector3(0, 0.6, 0), 2.05, 1.3, 0.85, THATCH)
			k.box(Vector3(0.92, 0.27, 0), Vector3(0.06, 0.54, 0.34), WOOD_DARK.darkened(0.3))
			k.cylinder(Vector3(-0.5, 1.2, 0), 0.07, 0.07, 0.35, 5, STONE_DARK)
		"farmstead":
			k.box(Vector3(-0.15, 0.32, -0.25), Vector3(1.5, 0.64, 0.95), CLAY.lightened(0.1))
			k.gable(Vector3(-0.15, 0.6, -0.25), 1.75, 1.2, 0.8, THATCH.lightened(0.05))
			k.cylinder(Vector3(0.7, 0, 0.6), 0.28, 0.28, 0.55, 8, WOOD)
			k.cylinder(Vector3(0.7, 0.5, 0.6), 0.36, 0.0, 0.45, 8, THATCH_DARK)
			_fence(k, Vector3(-0.2, 0, 0.75), 1.3, 0.0)
		"fire":
			k.disc(Vector3.ZERO, 0.95, 0.03, EARTH, 12)
			k.ring_stones(Vector3.ZERO, 0.32, 9, STONE)
			for i in 3:
				var a := TAU * i / 3.0
				k.cylinder(Vector3(cos(a) * 0.12, 0.05, sin(a) * 0.12), 0.05, 0.04, 0.42, 5, WOOD_DARK, Vector3(-cos(a) * 0.15, 0, -sin(a) * 0.15))
			for i in 4:
				var a := TAU * i / 4.0 + 0.4
				k.cylinder(Vector3(cos(a) * 0.75, 0.1, sin(a) * 0.75), 0.1, 0.1, 0.55, 6, WOOD, Vector3.ZERO, Vector3(0, 0, 1).rotated(Vector3.UP, a))
		"workshop":
			_shelter(k, Vector3(-0.2, 0, -0.2), 1.4, 1.2, 1.05, THATCH_DARK)
			k.cylinder(Vector3(0.55, 0, 0.55), 0.22, 0.22, 0.32, 8, WOOD.lightened(0.15))
			_log_pile(k, Vector3(0.6, 0, -0.6), 0.6)
			k.box(Vector3(-0.2, 0.12, 0.65), Vector3(0.5, 0.24, 0.3), accent)
		"basket":
			_lean_to(k, Vector3(-0.2, 0, -0.3), 1.3, 0.95, HIDE_DARK)
			for i in 4:
				_basket(k, Vector3(-0.6 + i * 0.38, 0, 0.55 + (i % 2) * 0.12), accent)
			_bush(k, Vector3(0.7, 0, -0.6), 0.32, accent)
		"lean":
			_lean_to(k, Vector3(-0.25, 0, -0.25), 1.3, 1.1, HIDE)
			_rack(k, Vector3(0.45, 0, 0.5), 1.0, accent)
			k.ring_stones(Vector3(-0.6, 0, 0.6), 0.16, 6, STONE)
		"rack":
			_rack(k, Vector3(-0.3, 0, 0.0), 1.1, accent)
			_rack(k, Vector3(0.5, 0, 0.35), 0.8, accent.darkened(0.15))
			_lean_to(k, Vector3(0.35, 0, -0.55), 0.9, 0.8, HIDE_DARK)
		"totem":
			k.disc(Vector3.ZERO, 0.85, 0.03, EARTH.lightened(0.05), 12)
			k.ring_stones(Vector3.ZERO, 0.7, 12, STONE)
			var y := 0.0
			for c in [WOOD, accent, Color("c9a24a"), Color("b0442c"), accent.lightened(0.2)]:
				k.cylinder(Vector3(0, y, 0), 0.17, 0.15, 0.38, 6, c)
				y += 0.38
			k.box(Vector3(0, y - 0.15, 0), Vector3(0.75, 0.08, 0.12), Color("efe4cc"))
			k.cylinder(Vector3(0, y, 0), 0.14, 0.0, 0.22, 6, Color("b0442c"))
		"cave":
			k.rock(Vector3(0, 0, -0.1), Vector3(1.0, 0.9, 0.85), STONE)
			k.rock(Vector3(0.6, 0, 0.35), Vector3(0.45, 0.4, 0.4), STONE_DARK)
			k.box(Vector3(0, 0.3, 0.68), Vector3(0.5, 0.55, 0.1), Color("2a221e"))
			k.box(Vector3(-0.42, 0.55, 0.62), Vector3(0.22, 0.18, 0.02), accent)
			k.box(Vector3(0.38, 0.62, 0.6), Vector3(0.16, 0.2, 0.02), Color("efe4cc"))
		"pit":
			k.disc(Vector3.ZERO, 0.92, 0.03, EARTH.darkened(0.15), 10)
			for i in 7:
				var a := r.randf() * TAU
				var d := 0.35 + r.randf() * 0.5
				k.rock(Vector3(cos(a) * d, 0, sin(a) * d), Vector3.ONE * (0.18 + r.randf() * 0.2), accent.lerp(STONE, 0.4 + r.randf() * 0.3))
			_lean_to(k, Vector3(-0.45, 0, -0.5), 0.8, 0.75, WOOD)
			k.box(Vector3(0.35, 0.1, -0.2), Vector3(0.45, 0.2, 0.3), accent.darkened(0.2))
		"scout":
			for p in [Vector3(-0.4, 0, -0.4), Vector3(0.4, 0, -0.4), Vector3(-0.4, 0, 0.4), Vector3(0.4, 0, 0.4)]:
				k.cylinder(p, 0.06, 0.05, 2.1, 5, WOOD_DARK, -p * 0.15)
			k.box(Vector3(0, 1.85, 0), Vector3(0.95, 0.08, 0.95), WOOD)
			k.cylinder(Vector3(0, 1.9, 0), 0.72, 0.0, 0.6, 4, THATCH, Vector3.ZERO, Vector3.ZERO, PI / 4.0)
			k.box(Vector3(0.0, 1.98, 0.48), Vector3(0.9, 0.14, 0.04), accent)
		"fisher":
			k.dome(Vector3(-0.3, 0, -0.3), 0.6, 0.8, HIDE_DARK, 8, 3)
			_rack(k, Vector3(0.45, 0, 0.0), 0.9, accent)
			k.box(Vector3(-0.1, 0.1, 0.65), Vector3(1.2, 0.18, 0.3), WOOD.lightened(0.1), 0.15)
		"kiln":
			k.dome(Vector3(0.3, 0, -0.2), 0.55, 0.85, CLAY, 9, 4)
			k.cylinder(Vector3(0.3, 0.7, -0.2), 0.12, 0.1, 0.35, 6, CLAY.darkened(0.2))
			k.box(Vector3(0.3, 0.17, 0.33), Vector3(0.25, 0.3, 0.06), Color("2a1a14"))
			_shelter(k, Vector3(-0.5, 0, 0.25), 0.9, 0.9, 0.95, THATCH_DARK)
			for i in 3:
				k.cylinder(Vector3(-0.75 + i * 0.25, 0, 0.75), 0.1, 0.08, 0.22, 7, accent.lightened(i * 0.08))
		"dance":
			k.disc(Vector3.ZERO, 0.95, 0.03, EARTH.lightened(0.15), 14)
			for i in 6:
				var a := TAU * i / 6.0
				var p := Vector3(cos(a) * 0.8, 0, sin(a) * 0.8)
				k.cylinder(p, 0.04, 0.035, 1.2, 5, WOOD_DARK)
				k.box(p + Vector3(0.1, 1.0, 0), Vector3(0.2, 0.25, 0.02), [accent, Color("e0a12c"), Color("efe4cc")][i % 3])
			k.ring_stones(Vector3.ZERO, 0.25, 8, STONE)
		"field":
			k.disc(Vector3.ZERO, 0.0, 0.0, EARTH, 4)
			k.box(Vector3(0, 0.02, 0), Vector3(s * 0.94, 0.04, s * 0.94), EARTH.darkened(0.05))
			var rows := int(s * 3)
			for i in rows:
				var z := -s * 0.42 + (s * 0.84) * i / maxf(1.0, rows - 1.0)
				for j in int(s * 4):
					var x := -s * 0.42 + (s * 0.84) * j / maxf(1.0, s * 4.0 - 1.0)
					k.cylinder(Vector3(x, 0.03, z), 0.07, 0.03, 0.32 + r.randf() * 0.08, 4, accent.lerp(LEAF, r.randf() * 0.25))
			_fence(k, Vector3(0, 0, s * 0.48), s * 0.95, 0.0)
		"pasture":
			_fence(k, Vector3(0, 0, -s * 0.48), s * 0.95, 0.0)
			_fence(k, Vector3(0, 0, s * 0.48), s * 0.95, 0.0)
			_fence(k, Vector3(-s * 0.48, 0, 0), s * 0.95, PI / 2.0)
			_fence(k, Vector3(s * 0.48, 0, 0), s * 0.95, PI / 2.0)
			for i in 5:
				var p := Vector3(r.randf_range(-1, 1) * s * 0.3, 0, r.randf_range(-1, 1) * s * 0.3)
				_animal(k, p, r.randf() * TAU, accent)
			_lean_to(k, Vector3(-s * 0.28, 0, -s * 0.3), 0.9, 0.8, THATCH_DARK)
		"stonecircle":
			k.disc(Vector3.ZERO, s * 0.46, 0.03, Color("8a9a5a"), 14)
			for i in 10:
				var a := TAU * i / 10.0
				k.box(Vector3(cos(a) * 1.05, 0.45, sin(a) * 1.05), Vector3(0.24, 0.9 + r.randf() * 0.25, 0.16), STONE.lerp(STONE_DARK, r.randf() * 0.4), -a)
			k.box(Vector3(0, 0.15, 0), Vector3(0.6, 0.3, 0.35), STONE_DARK)
		"square":
			k.disc(Vector3.ZERO, s * 0.47, 0.04, Color("b8a27a"), 14)
			k.cylinder(Vector3.ZERO, 0.32, 0.36, 0.35, 10, STONE)
			k.cylinder(Vector3(0, 0.3, 0), 0.24, 0.24, 0.06, 10, Color("4d86a0"))
			for p in [Vector3(-0.9, 0, -0.9), Vector3(0.9, 0, -0.9), Vector3(-0.9, 0, 0.9)]:
				_shelter(k, p, 0.7, 0.6, 0.75, [accent, THATCH, Color("b0442c")][r.randi() % 3])
		_:
			k.box(Vector3(0, 0.4, 0), Vector3(s * 0.6, 0.8, s * 0.6), accent)


static func _tipi(k: Kit, at: Vector3, radius: float, h: float, hide: Color, accent: Color) -> void:
	k.cylinder(at, radius, 0.05, h, 9, hide)
	k.cylinder(at + Vector3(0, h * 0.35, 0), radius * 0.66, radius * 0.6, h * 0.08, 9, accent)
	k.box(at + Vector3(0, h * 0.14, radius * 0.75), Vector3(radius * 0.4, h * 0.28, 0.06), Color("3a2a1e"))
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		k.cylinder(at + Vector3(cos(a) * 0.04, h * 0.85, sin(a) * 0.04), 0.018, 0.012, h * 0.3, 4, WOOD_DARK, Vector3(cos(a) * 0.1, 0, sin(a) * 0.1))


## Open shelter: four posts and a gabled thatch roof.
static func _shelter(k: Kit, at: Vector3, w: float, d: float, h: float, roof: Color) -> void:
	for p in [Vector3(-w / 2 + 0.08, 0, -d / 2 + 0.08), Vector3(w / 2 - 0.08, 0, -d / 2 + 0.08), Vector3(-w / 2 + 0.08, 0, d / 2 - 0.08), Vector3(w / 2 - 0.08, 0, d / 2 - 0.08)]:
		k.cylinder(at + p, 0.05, 0.045, h, 5, WOOD_DARK)
	k.gable(at + Vector3(0, h, 0), w + 0.2, d + 0.25, h * 0.55, roof)


## Lean-to: a slanted roof of hides on two poles.
static func _lean_to(k: Kit, at: Vector3, w: float, h: float, roof: Color) -> void:
	k.cylinder(at + Vector3(-w / 2 + 0.05, 0, 0.3), 0.04, 0.04, h, 5, WOOD_DARK)
	k.cylinder(at + Vector3(w / 2 - 0.05, 0, 0.3), 0.04, 0.04, h, 5, WOOD_DARK)
	k.quad(at + Vector3(-w / 2, h, 0.32), at + Vector3(w / 2, h, 0.32), at + Vector3(w / 2, 0.02, -0.45), at + Vector3(-w / 2, 0.02, -0.45), roof, true)


static func _rack(k: Kit, at: Vector3, w: float, cloth: Color) -> void:
	k.cylinder(at + Vector3(-w / 2, 0, 0), 0.035, 0.03, 0.85, 4, WOOD_DARK)
	k.cylinder(at + Vector3(w / 2, 0, 0), 0.035, 0.03, 0.85, 4, WOOD_DARK)
	k.box(at + Vector3(0, 0.82, 0), Vector3(w + 0.1, 0.04, 0.04), WOOD)
	var n := maxi(2, int(w * 3))
	for i in n:
		var x := -w / 2 + 0.15 + (w - 0.3) * i / float(n - 1)
		k.box(at + Vector3(x, 0.6, 0), Vector3(0.16, 0.38, 0.02), cloth.lightened(0.08 * (i % 2)))


static func _log_pile(k: Kit, at: Vector3, w: float) -> void:
	for row in 2:
		for i in 3 - row:
			k.cylinder(at + Vector3((i - (2 - row) / 2.0) * 0.13, 0.07 + row * 0.12, -w / 2), 0.065, 0.065, w, 6, WOOD.lightened(0.05 * i), Vector3.ZERO, Vector3(0, 0, 1))


static func _basket(k: Kit, at: Vector3, fill: Color) -> void:
	k.cylinder(at, 0.1, 0.13, 0.18, 7, THATCH_DARK)
	k.dome(at + Vector3(0, 0.16, 0), 0.12, 0.06, fill, 7, 2)


static func _bush(k: Kit, at: Vector3, r: float, fruit: Color) -> void:
	k.blob(at + Vector3(0, r * 0.8, 0), Vector3(r, r * 0.85, r), LEAF_DARK)
	for i in 5:
		var a := TAU * i / 5.0
		k.blob(at + Vector3(cos(a) * r * 0.75, r * (0.7 + 0.3 * (i % 2)), sin(a) * r * 0.75), Vector3.ONE * 0.05, fruit, 1)


static func _fence(k: Kit, at: Vector3, length: float, rot: float) -> void:
	var dir := Vector3(1, 0, 0).rotated(Vector3.UP, rot)
	var n := maxi(2, int(length / 0.4))
	for i in n:
		var p := at + dir * (-length / 2 + length * i / float(n - 1))
		k.cylinder(p, 0.03, 0.03, 0.32, 4, WOOD_DARK)
	k.box(at + Vector3(0, 0.25, 0), Vector3(length, 0.03, 0.03), WOOD, rot)
	k.box(at + Vector3(0, 0.14, 0), Vector3(length, 0.03, 0.03), WOOD, rot)


static func _animal(k: Kit, at: Vector3, rot: float, wool: Color) -> void:
	var fwd := Vector3(1, 0, 0).rotated(Vector3.UP, rot)
	k.blob(at + Vector3(0, 0.22, 0), Vector3(0.22, 0.14, 0.14), wool, 2, rot)
	k.blob(at + fwd * 0.22 + Vector3(0, 0.3, 0), Vector3(0.08, 0.08, 0.07), wool.darkened(0.45), 1, rot)
	for o in [Vector3(0.12, 0, 0.07), Vector3(0.12, 0, -0.07), Vector3(-0.12, 0, 0.07), Vector3(-0.12, 0, -0.07)]:
		k.cylinder(at + o.rotated(Vector3.UP, rot), 0.022, 0.02, 0.16, 4, wool.darkened(0.5))


# ---------------------------------------------------------------- nature

static func _nature(k: Kit, kind: String) -> void:
	match kind:
		"conifer":
			k.cylinder(Vector3.ZERO, 0.07, 0.05, 0.45, 5, WOOD_DARK)
			k.cylinder(Vector3(0, 0.3, 0), 0.42, 0.0, 0.8, 7, PINE)
			k.cylinder(Vector3(0, 0.65, 0), 0.32, 0.0, 0.7, 7, PINE.lightened(0.06))
			k.cylinder(Vector3(0, 0.98, 0), 0.22, 0.0, 0.58, 7, PINE.lightened(0.12))
		"broadleaf":
			k.cylinder(Vector3.ZERO, 0.08, 0.06, 0.6, 5, WOOD)
			k.blob(Vector3(0, 0.95, 0), Vector3(0.48, 0.42, 0.48), LEAF, 2)
			k.blob(Vector3(0.22, 0.78, 0.15), Vector3(0.3, 0.27, 0.3), LEAF.lightened(0.08), 1)
			k.blob(Vector3(-0.2, 0.8, -0.12), Vector3(0.3, 0.27, 0.3), LEAF_DARK, 1)
		"bush":
			_bush(k, Vector3.ZERO, 0.26, BERRY)
		"hazel":
			_bush(k, Vector3.ZERO, 0.3, Color("a8743a"))
		"rock":
			k.rock(Vector3.ZERO, Vector3(0.38, 0.28, 0.3), STONE)
			k.rock(Vector3(0.25, 0, 0.12), Vector3(0.18, 0.14, 0.16), STONE_DARK)
		"deposit_flint", "deposit_copper", "deposit_tin":
			var vein: Color = {"deposit_flint": Color("3b4452"), "deposit_copper": Color("3f9a82"), "deposit_tin": Color("c6ccd2")}[kind]
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.rock(Vector3(cos(a) * 0.45, 0, sin(a) * 0.45), Vector3(0.35, 0.3 + (i % 2) * 0.15, 0.3), STONE_DARK.lerp(STONE, 0.3 * (i % 3)))
				k.rock(Vector3(cos(a) * 0.4, 0.22, sin(a) * 0.4), Vector3(0.12, 0.1, 0.12), vein)
			k.rock(Vector3.ZERO, Vector3(0.4, 0.5, 0.4), STONE)
			k.rock(Vector3(0.05, 0.4, 0.05), Vector3(0.18, 0.15, 0.18), vein)


# ---------------------------------------------------------------- people

const TIER_CLOTH := {
	"gatherers": Color("a87a4a"), "hunters": Color("7a5a3a"), "settlers": Color("b8955c"),
	"artisans": Color("8a4a3a"), "farmers": Color("c8b48a"), "porter": Color("6a5a4a"), "scout": Color("3a6a8a"),
}

static func _person(k: Kit, who: String) -> void:
	var cloth: Color = TIER_CLOTH.get(who, Color("8a6a4a"))
	k.cylinder(Vector3.ZERO, 0.09, 0.05, 0.32, 6, cloth)
	k.blob(Vector3(0, 0.38, 0), Vector3(0.065, 0.07, 0.065), Color("c48a64"), 1)
	k.blob(Vector3(0, 0.42, -0.01), Vector3(0.068, 0.04, 0.068), Color("3a2a1e"), 1)
	if who == "porter":
		k.cylinder(Vector3(0, 0.18, -0.09), 0.08, 0.1, 0.24, 6, THATCH_DARK)
	if who == "scout":
		k.cylinder(Vector3(0.09, 0.0, 0.0), 0.012, 0.012, 0.55, 4, WOOD_DARK)


# ---------------------------------------------------------------- mesh kit

## Collects flat-shaded triangles with painted (slightly jittered) colours.
class Kit:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var rng := RandomNumberGenerator.new()

	func _init(seed_value: int) -> void:
		rng.seed = seed_value

	func _paint(c: Color) -> Color:
		var j := rng.randf_range(-0.05, 0.05)
		return Color(clampf(c.r + j, 0, 1), clampf(c.g + j * 0.9, 0, 1), clampf(c.b + j * 0.8, 0, 1))

	## Each primitive sets `center`; triangle normals are oriented away from it.
	var center := Vector3.ZERO

	func tri(a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
		var n := (b - a).cross(c - a)
		if n.length_squared() < 1e-12:
			return
		n = n.normalized()
		if n.dot((a + b + c) / 3.0 - center) < 0.0:
			n = -n
		_emit(a, b, c, n, _paint(col))

	## Godot treats clockwise triangles (seen from the front) as front faces.
	func _emit(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color) -> void:
		if (b - a).cross(c - a).dot(n) > 0.0:
			verts.append_array([a, c, b])
		else:
			verts.append_array([a, b, c])
		normals.append_array([n, n, n])
		colors.append_array([col, col, col])

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, two_sided := false) -> void:
		if two_sided:
			var n := (b - a).cross(c - a).normalized()
			var p := _paint(col)
			var q := col.darkened(0.15)
			_emit(a, b, c, n, p)
			_emit(a, c, d, n, p)
			_emit(a, b, c, -n, q)
			_emit(a, c, d, -n, q)
			return
		tri(a, b, c, col)
		tri(a, c, d, col)

	## Box centred at `c` (y is the centre height), optionally rotated around y.
	func box(c: Vector3, size: Vector3, col: Color, rot := 0.0) -> void:
		center = c
		var h := size / 2.0
		var p := []
		for v in [Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1), Vector3(-1, -1, 1), Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(-1, 1, 1)]:
			p.append(c + (v * h).rotated(Vector3.UP, rot))
		quad(p[4], p[5], p[6], p[7], col.lightened(0.04)) # top
		quad(p[3], p[2], p[1], p[0], col.darkened(0.2)) # bottom
		quad(p[0], p[1], p[5], p[4], col)
		quad(p[1], p[2], p[6], p[5], col)
		quad(p[2], p[3], p[7], p[6], col)
		quad(p[3], p[0], p[4], p[7], col)

	## Frustum from `base` upwards along `axis` (default up). r_top = 0 makes a cone.
	func cylinder(base: Vector3, r_bot: float, r_top: float, h: float, segs: int, col: Color, lean := Vector3.ZERO, axis := Vector3.UP, rot := 0.0) -> void:
		var up := axis.normalized()
		var side := up.cross(Vector3(0.3, 0.1, 1).normalized() if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		if up == Vector3.UP:
			side = Vector3.RIGHT
		var fwd := side.cross(up).normalized()
		var top := base + up * h + lean
		center = base + (up * h + lean) * (0.5 if r_top > 0.001 else 0.25)
		var bot_ring := []
		var top_ring := []
		for i in segs:
			var a := TAU * i / segs + rot
			var o := side * cos(a) + fwd * sin(a)
			bot_ring.append(base + o * r_bot)
			top_ring.append(top + o * r_top)
		for i in segs:
			var j := (i + 1) % segs
			if r_top <= 0.001:
				tri(bot_ring[i], bot_ring[j], top, col)
			else:
				quad(bot_ring[i], bot_ring[j], top_ring[j], top_ring[i], col)
				tri(top, top_ring[i], top_ring[j], col.lightened(0.05))

	## Upper half-sphere (a dome) on the ground.
	func dome(base: Vector3, r: float, h: float, col: Color, segs := 8, rings := 3) -> void:
		_ellipsoid(base, Vector3(r, h, r), col, segs, rings, true)

	## Lumpy ellipsoid ("blob") for foliage, heads and animals.
	func blob(c: Vector3, radii: Vector3, col: Color, detail := 2, rot := 0.0) -> void:
		_ellipsoid(c, radii, col, 5 + detail * 2, 2 + detail, false, 0.12, rot)

	## Irregular rock sitting on the ground.
	func rock(base: Vector3, size: Vector3, col: Color) -> void:
		_ellipsoid(base + Vector3(0, size.y * 0.35, 0), Vector3(size.x, size.y * 0.75, size.z), col, 6, 3, false, 0.25, rng.randf() * TAU)

	func _ellipsoid(c: Vector3, radii: Vector3, col: Color, segs: int, rings: int, half: bool, wobble := 0.0, rot := 0.0) -> void:
		center = c
		var pts := []
		var lat_from := 0 if half else -rings
		for li in range(lat_from, rings + 1):
			var row := []
			var lat := PI / 2.0 * li / rings
			for i in segs:
				var a := TAU * i / segs + rot
				var wob := 1.0 + rng.randf_range(-wobble, wobble) if absi(li) != rings else 1.0
				var v := Vector3(cos(lat) * cos(a) * wob, sin(lat), cos(lat) * sin(a) * wob)
				row.append(c + Vector3(v.x * radii.x, v.y * radii.y, v.z * radii.z))
			pts.append(row)
		for li in pts.size() - 1:
			for i in segs:
				var j := (i + 1) % segs
				var shade := col.darkened(0.12 * (1.0 - float(li) / pts.size()))
				quad(pts[li][i], pts[li][j], pts[li + 1][j], pts[li + 1][i], shade)

	## Flat disc (ground patch).
	func disc(c: Vector3, r: float, h: float, col: Color, segs := 10) -> void:
		if r <= 0.0:
			return
		var top := c + Vector3(0, h, 0)
		center = c - Vector3(0, 1, 0)
		for i in segs:
			var a0 := TAU * i / segs
			var a1 := TAU * (i + 1) / segs
			var p0 := c + Vector3(cos(a0) * r, h, sin(a0) * r)
			var p1 := c + Vector3(cos(a1) * r, h, sin(a1) * r)
			tri(top, p1, p0, col)

	## Gabled roof (a prism) whose eaves sit at `c.y`, ridge along x.
	func gable(c: Vector3, w: float, d: float, h: float, col: Color) -> void:
		var a := c + Vector3(-w / 2, 0, -d / 2)
		var b := c + Vector3(w / 2, 0, -d / 2)
		var e := c + Vector3(w / 2, 0, d / 2)
		var f := c + Vector3(-w / 2, 0, d / 2)
		center = c + Vector3(0, h * 0.3, 0)
		var r0 := c + Vector3(-w / 2 + 0.05, h, 0)
		var r1 := c + Vector3(w / 2 - 0.05, h, 0)
		quad(a, r0, r1, b, col.darkened(0.06), true)
		quad(f, e, r1, r0, col, true)
		tri(a, f, r0, col.darkened(0.2))
		tri(b, r1, e, col.darkened(0.2))

	func ring_stones(c: Vector3, r: float, n: int, col: Color) -> void:
		for i in n:
			var a := TAU * i / n
			rock(c + Vector3(cos(a) * r, 0, sin(a) * r), Vector3.ONE * 0.09, col)

	func commit(mat: Material) -> ArrayMesh:
		var m := ArrayMesh.new()
		if verts.is_empty():
			return m
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		m.surface_set_material(0, mat)
		return m
