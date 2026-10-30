class_name Models
## Stylised low-poly 3D models, built in code from simple primitives with painted vertex colours.
## Every model can be replaced by a file: res://assets/models/<id>.glb (or .tscn/.res), e.g.
## assets/models/buildings/tent.glb, assets/models/nature/conifer.glb, assets/models/people/foragers.glb.
## Mods can drop the same paths into user://mods/models/. Units: 1 tile = 1 metre-ish unit,
## models stand on y = 0 and are centred on their footprint.

static var _mesh_cache := {}
static var _material: ShaderMaterial


## Shared material for every procedural model: vertex colours with gouache-like banded light,
## season tints for foliage (vertex alpha < 1 marks leaves) and snow on upward faces in winter.
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://scripts/view/shaders/paint.gdshader")
	return _material


## Season look for every model: 0 spring, 1 summer, 2 autumn, 3 winter (fractions blend).
static func set_season(spring: float, autumn: float, winter: float) -> void:
	var m := material()
	m.set_shader_parameter("spring", spring)
	m.set_shader_parameter("autumn", autumn)
	m.set_shader_parameter("winter", winter)


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
		"chars":
			_character(k, parts[1])
		"find":
			_find(k, parts[1])
		"caravan":
			_caravan(k, parts[1])
		"pass":
			_pass_feature(k, parts[1])
		"misc":
			match parts[1]:
				"warning":
					# floating exclamation mark over buildings that lack something
					k.box(Vector3(0, 0.42, 0), Vector3(0.16, 0.5, 0.16), Color("e8a13a"))
					k.box(Vector3(0, 0.08, 0), Vector3(0.17, 0.17, 0.17), Color("e8a13a"))
				"quest":
					# golden exclamation mark over a character with a task
					k.box(Vector3(0, 0.45, 0), Vector3(0.14, 0.5, 0.1), Color("f2c14a"))
					k.box(Vector3(0, 0.08, 0), Vector3(0.15, 0.15, 0.1), Color("f2c14a"))
				"choose":
					# a character waiting for your choice: two little arrows
					k.cylinder(Vector3(-0.12, 0, 0), 0.12, 0.0, 0.3, 4, Color("f2c14a"))
					k.cylinder(Vector3(0.12, 0, 0), 0.12, 0.0, 0.3, 4, Color("f2c14a"))
				"ready":
					# green arrow over homes whose residents are ready for the next age
					k.cylinder(Vector3(0, 0.22, 0), 0.2, 0.0, 0.26, 4, Color("8fc45a"))
					k.box(Vector3(0, 0.11, 0), Vector3(0.12, 0.22, 0.12), Color("8fc45a"))
	return k.commit(material())


# ---------------------------------------------------------------- palette

const THATCH := Color("c49a52")
const THATCH_DARK := Color("9c7638")
const WOOD := Color("8a5e38")
const WOOD_DARK := Color("5a3a28")
const HIDE := Color("d6aa7c") # cream hides, patched with rust and tan (see the Talherz design)
const HIDE_DARK := Color("a8794a")
const RUST := Color("9e4a2c")
const STONE := Color("9c93ab") # lilac-grey rock
const STONE_DARK := Color("6f6782")
const CLAY := Color("d08a52")
const CLAY_LIGHT := Color("e0b47c")
const EARTH := Color("c48a4a") # warm ochre ground
const LEAF := Color("6f912f") # olive
const LEAF_DARK := Color("4d6d26")
const PINE := Color("2a4a36")
const BERRY := Color("b03a4a")
const LAVENDER := Color("a58fc4")
const OCHRE := Color("e0a040")
const PAINT := Color("9a3a26") # red ochre for spirals and handprints


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
			k.disc(Vector3.ZERO, s * 0.46, 0.02, EARTH.lightened(0.08), 12)
			_hide_dome(k, Vector3(-0.12, 0, -0.1), 0.78, 0.95)
			_hide_dome(k, Vector3(0.62, 0, 0.58), 0.34, 0.42, false)
			k.ring_stones(Vector3(0.6, 0, -0.55), 0.18, 7, STONE)
			_rack(k, Vector3(-0.55, 0, 0.72), 0.5, RUST.lightened(0.15))
		"hut":
			# Natufian pit house: a ring of field stones, a low dome of reeds and hides, crossed poles
			k.disc(Vector3.ZERO, s * 0.46, 0.02, EARTH.lightened(0.05), 12)
			for i in 14:
				var a := TAU * i / 14.0
				k.rock(Vector3(cos(a) * 0.8, 0, sin(a) * 0.8), Vector3(0.2, 0.26, 0.2), STONE.lerp(STONE_DARK, r.randf() * 0.4))
			_hide_dome(k, Vector3(0, 0.12, 0), 0.8, 0.95, true, THATCH)
			_log_pile(k, Vector3(0.78, 0, 0.62), 0.42)
			k.cylinder(Vector3(-0.72, 0, 0.62), 0.09, 0.11, 0.2, 7, CLAY)
		"mudhouse":
			# round clay house with painted spirals and a tall thatch cone
			k.disc(Vector3.ZERO, s * 0.47, 0.02, EARTH.lightened(0.05), 12)
			k.cylinder(Vector3.ZERO, 0.74, 0.72, 0.66, 12, CLAY_LIGHT)
			k.cylinder(Vector3(0, 0.3, 0), 0.745, 0.735, 0.1, 12, PAINT)
			k.cylinder(Vector3(0, 0.6, 0), 0.98, 0.0, 1.05, 12, THATCH)
			k.cylinder(Vector3(0, 1.45, 0), 0.06, 0.03, 0.35, 4, WOOD_DARK)
			k.box(Vector3(0, 0.27, 0.73), Vector3(0.3, 0.54, 0.06), WOOD_DARK.darkened(0.35))
			_spiral(k, Vector3(0.43, 0.42, 0.615), 0.1, PAINT, 0.6)
			_spiral(k, Vector3(-0.43, 0.42, 0.615), 0.1, PAINT, -0.6)
			k.cylinder(Vector3(0.8, 0, -0.5), 0.12, 0.14, 0.3, 8, CLAY)
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
		"hearth":
			# the Talherz: the valley's first fire, ringed by carved posts and seats
			k.disc(Vector3.ZERO, s * 0.48, 0.03, EARTH.lightened(0.12), 18)
			k.disc(Vector3.ZERO, 0.75, 0.05, EARTH.darkened(0.12), 14)
			for i in 12:
				var a := TAU * i / 12.0
				k.rock(Vector3(cos(a) * 0.62, 0, sin(a) * 0.62), Vector3(0.2, 0.22 + (i % 3) * 0.05, 0.2), STONE.lerp(STONE_DARK, r.randf() * 0.35))
			for i in 4:
				var a := TAU * i / 4.0 + 0.3
				k.cylinder(Vector3(cos(a) * 0.12, 0.05, sin(a) * 0.12), 0.06, 0.04, 0.5, 5, WOOD_DARK, Vector3(-cos(a) * 0.15, 0, -sin(a) * 0.15))
			for i in 4:
				var a := TAU * i / 4.0 + PI / 4.0
				var p := Vector3(cos(a) * 1.25, 0, sin(a) * 1.25)
				var y := 0.0
				for c in [WOOD, PAINT, OCHRE, WOOD.lightened(0.1), HIDE]:
					k.cylinder(p + Vector3(0, y, 0), 0.11, 0.1, 0.3, 6, c)
					y += 0.3
				k.cylinder(p + Vector3(0, y, 0), 0.1, 0.0, 0.18, 6, PAINT)
			for i in 4:
				var a := TAU * i / 4.0
				k.cylinder(Vector3(cos(a) * 1.05, 0.11, sin(a) * 1.05), 0.11, 0.11, 0.6, 6, WOOD, Vector3.ZERO, Vector3(0, 0, 1).rotated(Vector3.UP, a))
			for p in [Vector3(1.2, 0, 0.0), Vector3(-1.2, 0, 0.3), Vector3(0.2, 0, -1.25)]:
				_flowers(k, p, 0.2)
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
		"storepit":
			# pits lined with clay and closed by woven lids
			k.disc(Vector3.ZERO, s * 0.47, 0.03, EARTH.darkened(0.05), 12)
			for p in [Vector3(-0.45, 0, -0.35), Vector3(0.4, 0, -0.4), Vector3(-0.35, 0, 0.45), Vector3(0.45, 0, 0.4)]:
				k.cylinder(p, 0.32, 0.3, 0.06, 9, CLAY.darkened(0.15))
				k.cylinder(p + Vector3(0, 0.06, 0), 0.27, 0.22, 0.05, 9, THATCH)
				k.cylinder(p + Vector3(0, 0.11, 0), 0.05, 0.04, 0.06, 5, WOOD_DARK)
			_basket(k, Vector3(0.0, 0, 0.0), BERRY)
			_lean_to(k, Vector3(0.0, 0, -0.75), 0.9, 0.6, HIDE_DARK)
		"smoke":
			_hide_dome(k, Vector3(-0.3, 0, -0.3), 0.6, 0.75, false, HIDE.darkened(0.25))
			_rack(k, Vector3(0.45, 0, 0.1), 0.9, RUST)
			_rack(k, Vector3(0.0, 0, 0.7), 0.8, Color("c27a48"))
			k.ring_stones(Vector3(0.55, 0, -0.55), 0.16, 6, STONE)
		"granary":
			# a clay-and-wicker bin raised on stilts against mice and damp
			for p in [Vector3(-0.35, 0, -0.35), Vector3(0.35, 0, -0.35), Vector3(-0.35, 0, 0.35), Vector3(0.35, 0, 0.35)]:
				k.cylinder(p, 0.05, 0.05, 0.45, 5, WOOD_DARK)
				k.cylinder(p + Vector3(0, 0.42, 0), 0.1, 0.1, 0.04, 6, STONE)
			k.box(Vector3(0, 0.48, 0), Vector3(0.95, 0.06, 0.95), WOOD)
			k.cylinder(Vector3(0, 0.5, 0), 0.5, 0.56, 0.6, 10, CLAY_LIGHT)
			k.cylinder(Vector3(0, 0.75, 0), 0.565, 0.565, 0.06, 10, PAINT)
			k.cylinder(Vector3(0, 1.08, 0), 0.68, 0.0, 0.62, 10, THATCH)
			k.cylinder(Vector3(0.75, 0, 0.3), 0.04, 0.04, 0.75, 4, WOOD_DARK, Vector3(-0.25, 0, -0.1))
		"flowers":
			k.disc(Vector3.ZERO, 0.45, 0.02, Color("7d8f3c"), 8)
			_flowers(k, Vector3(-0.15, 0, -0.1), 0.28)
			_flowers(k, Vector3(0.2, 0, 0.18), 0.22)
		"menhir":
			k.disc(Vector3.ZERO, 0.4, 0.02, EARTH.lightened(0.1), 8)
			k.box(Vector3(0, 0.62, 0), Vector3(0.36, 1.24, 0.24), STONE)
			k.rock(Vector3(0, 1.1, 0), Vector3(0.2, 0.2, 0.13), STONE)
			_spiral(k, Vector3(0, 0.8, 0.125), 0.12, PAINT, 0.0)
			k.box(Vector3(0, 0.38, 0.125), Vector3(0.3, 0.05, 0.02), OCHRE)
			_flowers(k, Vector3(0.28, 0, 0.2), 0.1)
		"post":
			k.disc(Vector3.ZERO, 0.38, 0.02, EARTH.lightened(0.1), 8)
			var y := 0.0
			for c in [WOOD, PAINT, HIDE, OCHRE, WOOD.lightened(0.1)]:
				k.cylinder(Vector3(0, y, 0), 0.12, 0.11, 0.28, 6, c)
				y += 0.28
			k.box(Vector3(0, y - 0.1, 0), Vector3(0.6, 0.06, 0.08), HIDE)
			k.cylinder(Vector3(0, y, 0), 0.1, 0.0, 0.2, 6, PAINT)
		"stones":
			k.disc(Vector3.ZERO, s * 0.46, 0.02, EARTH.darkened(0.08), 10)
			for i in 9:
				var a := r.randf() * TAU
				var d := 0.25 + r.randf() * 0.55
				k.rock(Vector3(cos(a) * d, 0, sin(a) * d), Vector3.ONE * (0.15 + r.randf() * 0.18), STONE.lerp(STONE_DARK, r.randf() * 0.5))
			_lean_to(k, Vector3(-0.4, 0, -0.5), 0.8, 0.75, HIDE_DARK)
			_basket(k, Vector3(0.55, 0, 0.55), STONE)
		"mound":
			# ancestors' mound: a grassy barrow with a stone entrance
			k.disc(Vector3.ZERO, s * 0.47, 0.02, Color("7d8f3c"), 12)
			k.dome(Vector3(0, 0, -0.1), 0.85, 0.6, Color("7f9445"), 10, 3)
			k.box(Vector3(0, 0.18, 0.66), Vector3(0.34, 0.36, 0.14), Color("2a221e"))
			k.box(Vector3(0, 0.4, 0.7), Vector3(0.5, 0.1, 0.18), STONE)
			for xx in [-0.22, 0.22]:
				k.box(Vector3(xx, 0.18, 0.7), Vector3(0.1, 0.36, 0.16), STONE_DARK)
			for i in 8:
				var a := TAU * i / 8.0
				k.rock(Vector3(cos(a) * 0.9, 0, sin(a) * 0.9 - 0.1), Vector3.ONE * 0.12, STONE)
		"tpillars":
			# a ring of T-shaped pillars with carved animals, like Göbekli Tepe
			k.disc(Vector3.ZERO, s * 0.47, 0.03, EARTH.lightened(0.15), 16)
			k.disc(Vector3.ZERO, 1.05, 0.05, STONE.lightened(0.15), 16)
			for i in 8:
				var a := TAU * i / 8.0
				var p := Vector3(cos(a) * 1.05, 0, sin(a) * 1.05)
				k.box(p + Vector3(0, 0.45, 0), Vector3(0.14, 0.9, 0.24), STONE, -a)
				k.box(p + Vector3(0, 0.95, 0), Vector3(0.22, 0.14, 0.42), STONE.lightened(0.05), -a)
			k.box(Vector3(-0.22, 0.65, 0), Vector3(0.18, 1.3, 0.32), STONE.lightened(0.08))
			k.box(Vector3(-0.22, 1.35, 0), Vector3(0.26, 0.18, 0.55), STONE.lightened(0.1))
			k.box(Vector3(0.22, 0.65, 0), Vector3(0.18, 1.3, 0.32), STONE.lightened(0.08))
			k.box(Vector3(0.22, 1.35, 0), Vector3(0.26, 0.18, 0.55), STONE.lightened(0.1))
			k.box(Vector3(-0.12, 0.7, 0.0), Vector3(0.02, 0.22, 0.16), PAINT)
			k.box(Vector3(0.12, 0.7, 0.0), Vector3(0.02, 0.22, 0.16), PAINT)
		"dolmen":
			k.disc(Vector3.ZERO, s * 0.47, 0.03, Color("7d8f3c"), 16)
			for p in [Vector3(-0.45, 0, -0.3), Vector3(0.45, 0, -0.3), Vector3(0.0, 0, 0.4)]:
				k.box(p + Vector3(0, 0.45, 0), Vector3(0.28, 0.9, 0.22), STONE.lerp(STONE_DARK, r.randf() * 0.3), r.randf() * 0.4)
			k.rock(Vector3(0, 0.85, 0), Vector3(0.95, 0.3, 0.75), STONE.lightened(0.05))
			for i in 12:
				var a := TAU * i / 12.0
				k.box(Vector3(cos(a) * 1.25, 0.3, sin(a) * 1.25), Vector3(0.18, 0.6 + r.randf() * 0.2, 0.14), STONE.lerp(STONE_DARK, r.randf() * 0.4), -a)
		"quern":
			_shelter(k, Vector3(-0.25, 0, -0.25), 1.2, 1.0, 0.95, THATCH_DARK)
			k.rock(Vector3(0.45, 0, 0.45), Vector3(0.4, 0.18, 0.26), STONE)
			k.rock(Vector3(0.45, 0.15, 0.45), Vector3(0.15, 0.08, 0.1), STONE_DARK)
			for i in 3:
				_basket(k, Vector3(-0.6 + i * 0.3, 0, 0.7), [THATCH, OCHRE, HIDE][i])
			k.disc(Vector3(0.45, 0, 0.45), 0.5, 0.01, HIDE_DARK, 8)
		"loom":
			_shelter(k, Vector3(0, 0, -0.2), 1.4, 1.1, 1.15, THATCH)
			# warp-weighted loom: a frame, coloured warp threads and clay weights
			k.cylinder(Vector3(-0.45, 0, 0.0), 0.04, 0.04, 1.1, 4, WOOD_DARK, Vector3(0, 0, -0.15))
			k.cylinder(Vector3(0.45, 0, 0.0), 0.04, 0.04, 1.1, 4, WOOD_DARK, Vector3(0, 0, -0.15))
			k.box(Vector3(0, 1.05, -0.14), Vector3(1.0, 0.05, 0.05), WOOD)
			k.quad(Vector3(-0.4, 1.02, -0.14), Vector3(0.4, 1.02, -0.14), Vector3(0.4, 0.35, -0.05), Vector3(-0.4, 0.35, -0.05), accent, true)
			for i in 6:
				k.blob(Vector3(-0.35 + i * 0.14, 0.28, -0.04), Vector3.ONE * 0.04, CLAY, 1)
			k.box(Vector3(0.6, 0.12, 0.6), Vector3(0.3, 0.24, 0.3), accent.lightened(0.15))
		"caravan":
			_shelter(k, Vector3(-0.3, 0, -0.3), 1.3, 1.1, 1.0, HIDE_DARK)
			for i in 3:
				k.box(Vector3(-0.7 + i * 0.35, 0.14, 0.55), Vector3(0.28, 0.28, 0.24), [THATCH, HIDE, accent][i], r.randf() * 0.5)
			k.cylinder(Vector3(0.8, 0, 0.2), 0.04, 0.04, 0.8, 4, WOOD_DARK)
			k.cylinder(Vector3(0.8, 0, -0.6), 0.04, 0.04, 0.8, 4, WOOD_DARK)
			k.box(Vector3(0.8, 0.72, -0.2), Vector3(0.04, 0.04, 0.85), WOOD)
			k.blob(Vector3(0.55, 0.3, -0.25), Vector3(0.22, 0.13, 0.12), Color("8a8070"), 2, PI / 2.0)
			k.blob(Vector3(0.55, 0.4, 0.02), Vector3(0.08, 0.08, 0.1), Color("7a7060"), 1)
		_:
			k.box(Vector3(0, 0.4, 0), Vector3(s * 0.6, 0.8, s * 0.6), accent)


## A dome of sewn hides: cream with rust and tan patches, a dark door and crossed poles on top.
static func _hide_dome(k: Kit, at: Vector3, radius: float, h: float, poles := true, base := HIDE) -> void:
	k.patch_dome(at, radius, h, base, [RUST, HIDE_DARK, base.lightened(0.15), Color("8a5a3a")], 0.3, 11, 5)
	# a short entrance porch facing +z with a dark opening
	k.box(at + Vector3(0, h * 0.25, radius * 0.92), Vector3(radius * 0.52, h * 0.5, 0.3), base.darkened(0.1))
	k.box(at + Vector3(0, h * 0.21, radius * 0.92 + 0.151), Vector3(radius * 0.34, h * 0.4, 0.02), Color("3a2a1e"))
	k.box(at + Vector3(0, h * 0.5, radius * 0.92), Vector3(radius * 0.58, 0.05, 0.32), RUST)
	# a red-ochre handprint beside the door
	var hr := radius * 0.907 + 0.012
	k.box(at + Vector3(sin(1.05) * hr, h * 0.42, cos(1.05) * hr), Vector3(0.1, 0.11, 0.02), PAINT, 1.05)
	if poles:
		for i in 3:
			var a := TAU * i / 3.0 + 0.4
			k.cylinder(at + Vector3(0, h * 0.86, 0), 0.025, 0.018, h * 0.42, 4, WOOD_DARK, Vector3(cos(a) * 0.18, 0, sin(a) * 0.18))


## A small painted spiral, made of short strokes, on a wall facing roughly +z.
static func _spiral(k: Kit, at: Vector3, radius: float, col: Color, turn: float) -> void:
	var prev := at
	for i in 14:
		var t := float(i + 1) / 14.0
		var a := t * TAU * 1.6
		var p := at + Vector3(cos(a) * radius * t, sin(a) * radius * t, 0).rotated(Vector3.UP, turn)
		var mid := (prev + p) / 2.0
		var d := p - prev
		k.box(mid + Vector3(0, 0, 0.01), Vector3(maxf(0.02, absf(d.x) + 0.015), maxf(0.02, absf(d.y) + 0.015), 0.012), col, turn)
		prev = p


## A clump of lavender with a few white and yellow flowers.
static func _flowers(k: Kit, at: Vector3, radius: float) -> void:
	var r := k.rng
	k.blob(at + Vector3(0, radius * 0.35, 0), Vector3(radius, radius * 0.4, radius), LEAF_DARK, 1)
	for i in int(6 + radius * 20):
		var a := r.randf() * TAU
		var d := r.randf() * radius
		var c: Color = [LAVENDER, LAVENDER.darkened(0.15), LAVENDER.lightened(0.1), Color("f2ead2"), Color("e8c84a")][r.randi() % 5]
		k.cylinder(at + Vector3(cos(a) * d, radius * 0.3, sin(a) * d), 0.025, 0.012, 0.12 + r.randf() * 0.1, 4, c)


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
	k.leafy = true
	k.blob(at + Vector3(0, r * 0.8, 0), Vector3(r, r * 0.85, r), LEAF_DARK)
	k.leafy = false
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
			k.leafy = true
			k.blob(Vector3(0, 0.95, 0), Vector3(0.5, 0.45, 0.5), LEAF, 2)
			k.blob(Vector3(0.24, 0.8, 0.15), Vector3(0.32, 0.29, 0.32), LEAF.lightened(0.1), 1)
			k.blob(Vector3(-0.2, 0.82, -0.12), Vector3(0.32, 0.29, 0.32), LEAF_DARK, 1)
			k.blob(Vector3(0.0, 1.22, 0.05), Vector3(0.28, 0.22, 0.28), LEAF.lightened(0.16), 1)
		"bush":
			_bush(k, Vector3.ZERO, 0.26, BERRY)
		"hazel":
			_bush(k, Vector3.ZERO, 0.3, Color("a8743a"))
		"rock":
			k.rock(Vector3.ZERO, Vector3(0.42, 0.34, 0.34), STONE)
			k.rock(Vector3(0.28, 0, 0.14), Vector3(0.2, 0.16, 0.18), STONE_DARK)
		"stump":
			k.cylinder(Vector3.ZERO, 0.11, 0.09, 0.14, 6, WOOD)
			k.disc(Vector3(0, 0.141, 0), 0.085, 0.0, CLAY_LIGHT, 6)
			for i in 3:
				k.blob(Vector3(0.18 - i * 0.15, 0.03, 0.12 - i * 0.1), Vector3(0.06, 0.03, 0.04), WOOD.lightened(0.1), 1)
		"flowers":
			_flowers(k, Vector3.ZERO, 0.22)
		"grass":
			for i in 7:
				var a := TAU * i / 7.0
				k.cylinder(Vector3(cos(a) * 0.08, 0, sin(a) * 0.08), 0.03, 0.0, 0.22 + (i % 3) * 0.06, 3, Color("a3a854").lerp(LEAF, 0.4 * (i % 2)), Vector3(cos(a) * 0.06, 0, sin(a) * 0.06))
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
	"foragers": Color("a87a4a"), "sedentary": Color("7a5a3a"), "farmers": Color("b8955c"),
	"villagers": Color("c8b48a"), "chieftains": Color("8a3a32"), "porter": Color("6a5a4a"), "scout": Color("3a6a8a"),
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


# ---------------------------------------------------------------- characters

## The people who hand out tasks: bigger than villagers, with their own clothes and props.
static func _character(k: Kit, id: String) -> void:
	if id == "dog":
		_dog(k, Vector3.ZERO, 0.0)
		return
	var c: Dictionary = Content.CHARACTER.get(id, {})
	if c.is_empty():
		return
	var cloth := Color(c.cloth)
	var hair := Color(c.hair)
	var skin := Color(c.skin)
	var extra: Array = c.extra
	for xx in [0.045, -0.045]:
		k.cylinder(Vector3(xx, 0, 0), 0.032, 0.03, 0.17, 5, skin.darkened(0.2))
	k.cylinder(Vector3(0, 0.13, 0), 0.125, 0.08, 0.3, 9, cloth)
	k.cylinder(Vector3(0, 0.12, 0), 0.127, 0.12, 0.04, 9, cloth.darkened(0.3))
	k.cylinder(Vector3(0, 0.25, 0), 0.105, 0.1, 0.03, 9, Color("5a3a28"))
	if "cloak" in extra:
		k.cylinder(Vector3(0, 0.3, -0.01), 0.15, 0.085, 0.15, 9, cloth.darkened(0.25).lerp(HIDE_DARK, 0.3))
	for side in [1.0, -1.0]:
		k.cylinder(Vector3(0.1 * side, 0.41, 0), 0.03, 0.026, 0.2, 5, cloth.darkened(0.08), Vector3(0.04 * side, 0, 0.04), Vector3.DOWN)
		k.blob(Vector3(0.14 * side, 0.2, 0.04), Vector3.ONE * 0.03, skin, 1)
	k.blob(Vector3(0, 0.51, 0), Vector3(0.078, 0.088, 0.078), skin, 1)
	k.blob(Vector3(0, 0.555, -0.018), Vector3(0.084, 0.058, 0.084), hair, 1)
	k.box(Vector3(0, 0.47, -0.05), Vector3(0.13, 0.14, 0.06), hair)
	k.box(Vector3(0.026, 0.515, 0.084), Vector3(0.018, 0.018, 0.012), Color("2a1e18"))
	k.box(Vector3(-0.026, 0.515, 0.084), Vector3(0.018, 0.018, 0.012), Color("2a1e18"))
	for e in extra:
		match e:
			"staff":
				k.cylinder(Vector3(0.16, 0, 0.05), 0.016, 0.013, 0.78, 4, WOOD)
				k.blob(Vector3(0.16, 0.8, 0.05), Vector3.ONE * 0.035, PAINT, 1)
			"spear":
				k.cylinder(Vector3(-0.16, 0, 0.05), 0.012, 0.012, 0.86, 4, WOOD_DARK)
				k.cylinder(Vector3(-0.16, 0.86, 0.05), 0.026, 0.0, 0.11, 4, Color("3b4452"))
			"dog":
				_dog(k, Vector3(0.3, 0, 0.18), -0.5)
			"basket":
				k.cylinder(Vector3(0, 0.25, -0.14), 0.07, 0.09, 0.17, 7, THATCH_DARK)
				k.blob(Vector3(0, 0.42, -0.14), Vector3(0.08, 0.035, 0.08), BERRY, 1)
			"feather":
				k.quad(Vector3(0.03, 0.57, -0.05), Vector3(0.06, 0.57, -0.05), Vector3(0.1, 0.74, -0.08), Vector3(0.08, 0.75, -0.08), Color("f2ead2"), true)
			"axe":
				k.cylinder(Vector3(0.15, 0.08, 0.06), 0.014, 0.014, 0.34, 4, WOOD, Vector3(0.04, 0, 0.0))
				k.box(Vector3(0.2, 0.4, 0.06), Vector3(0.1, 0.06, 0.03), Color("3b4452"))
			"antlers":
				for side in [1.0, -1.0]:
					k.cylinder(Vector3(0.04 * side, 0.58, 0), 0.014, 0.008, 0.16, 4, Color("e0d2b0"), Vector3(0.1 * side, 0, 0))
					k.cylinder(Vector3(0.09 * side, 0.65, 0), 0.01, 0.006, 0.09, 4, Color("e0d2b0"), Vector3(0.02 * side, 0, 0.04))
			"pack":
				k.box(Vector3(0, 0.33, -0.13), Vector3(0.19, 0.24, 0.1), THATCH)
				k.cylinder(Vector3(-0.11, 0.48, -0.13), 0.045, 0.045, 0.22, 6, RUST, Vector3.ZERO, Vector3.RIGHT)
			"shells":
				for i in 7:
					var a := PI * (0.15 + 0.7 * i / 6.0)
					k.blob(Vector3(cos(a) * 0.08, 0.42 - sin(a) * 0.02, sin(a) * 0.07), Vector3.ONE * 0.017, Color("f4ecd8"), 1)
			"goat":
				_animal(k, Vector3(-0.32, 0, 0.12), 0.4, Color("e8e0d0"))
			"pot":
				k.cylinder(Vector3(0, 0.2, 0.13), 0.05, 0.075, 0.08, 8, CLAY)
				k.cylinder(Vector3(0, 0.28, 0.13), 0.075, 0.045, 0.07, 8, CLAY)
				k.cylinder(Vector3(0, 0.275, 0.13), 0.077, 0.077, 0.015, 8, PAINT)
			"copper":
				k.blob(Vector3(0.0, 0.42, 0.075), Vector3(0.035, 0.035, 0.012), Color("c87533"), 1)
				k.box(Vector3(-0.1, 0.24, 0.06), Vector3(0.05, 0.08, 0.02), Color("4f9a7a"))


static func _dog(k: Kit, at: Vector3, rot: float) -> void:
	var c := Color("8a6a4a")
	var fwd := Vector3(1, 0, 0).rotated(Vector3.UP, rot)
	k.blob(at + Vector3(0, 0.16, 0), Vector3(0.15, 0.08, 0.075), c, 2, rot)
	k.blob(at + fwd * 0.16 + Vector3(0, 0.24, 0), Vector3(0.06, 0.055, 0.05), c.lightened(0.1), 1, rot)
	k.blob(at + fwd * 0.22 + Vector3(0, 0.22, 0), Vector3(0.035, 0.025, 0.03), c.darkened(0.3), 1, rot)
	k.cylinder(at - fwd * 0.14 + Vector3(0, 0.18, 0), 0.015, 0.008, 0.12, 4, c, -fwd * 0.05 + Vector3(0, 0, 0))
	for o in [Vector3(0.08, 0, 0.045), Vector3(0.08, 0, -0.045), Vector3(-0.08, 0, 0.045), Vector3(-0.08, 0, -0.045)]:
		k.cylinder(at + o.rotated(Vector3.UP, rot), 0.018, 0.015, 0.12, 4, c.darkened(0.2))


## Things to find in the world (quests): Fenn the dog curled up between the trees.
static func _find(k: Kit, what: String) -> void:
	match what:
		"fenn":
			k.blob(Vector3(0, 0.08, 0), Vector3(0.16, 0.08, 0.12), Color("8a6a4a"), 2)
			k.blob(Vector3(0.12, 0.1, 0.06), Vector3(0.06, 0.05, 0.05), Color("9a7a5a"), 1)
			k.blob(Vector3(-0.1, 0.06, -0.08), Vector3(0.08, 0.03, 0.03), Color("7a5a3a"), 1)
		_:
			k.rock(Vector3.ZERO, Vector3.ONE * 0.2, OCHRE)


# ---------------------------------------------------------------- caravans & passes

## Caravan models face +X (direction of travel).
static func _caravan(k: Kit, kind: String) -> void:
	match kind:
		"donkey":
			var c := Color("8a8070")
			k.blob(Vector3(0, 0.3, 0), Vector3(0.24, 0.13, 0.12), c, 2)
			k.blob(Vector3(0.27, 0.4, 0), Vector3(0.1, 0.07, 0.06), c.darkened(0.15), 1)
			k.box(Vector3(0.26, 0.5, 0.03), Vector3(0.03, 0.1, 0.02), c.darkened(0.3))
			k.box(Vector3(0.26, 0.5, -0.03), Vector3(0.03, 0.1, 0.02), c.darkened(0.3))
			for o in [Vector3(0.14, 0, 0.07), Vector3(0.14, 0, -0.07), Vector3(-0.14, 0, 0.07), Vector3(-0.14, 0, -0.07)]:
				k.cylinder(o, 0.025, 0.02, 0.2, 4, c.darkened(0.5))
			k.cylinder(Vector3(0, 0.3, 0.16), 0.08, 0.09, 0.18, 6, THATCH_DARK)
			k.cylinder(Vector3(0, 0.3, -0.16), 0.08, 0.09, 0.18, 6, THATCH_DARK)
		"oxcart":
			var ox := Color("6a4a32")
			for zz in [0.12, -0.12]:
				k.blob(Vector3(0.45, 0.3, zz), Vector3(0.24, 0.15, 0.1), ox, 2)
				k.blob(Vector3(0.7, 0.36, zz), Vector3(0.08, 0.08, 0.07), ox.darkened(0.2), 1)
				for o in [Vector3(0.6, 0, zz), Vector3(0.3, 0, zz)]:
					k.cylinder(o, 0.03, 0.025, 0.2, 4, ox.darkened(0.5))
			k.box(Vector3(0.2, 0.35, 0), Vector3(0.6, 0.03, 0.03), WOOD_DARK)
			k.box(Vector3(-0.25, 0.32, 0), Vector3(0.6, 0.06, 0.4), WOOD)
			k.box(Vector3(-0.25, 0.42, 0), Vector3(0.5, 0.18, 0.34), THATCH)
			for zz in [0.24, -0.24]:
				k.cylinder(Vector3(-0.25, 0.17, zz), 0.17, 0.17, 0.05, 10, WOOD_DARK, Vector3.ZERO, Vector3(1, 0, 0))


## Obstacles on a pass (before) and the works that overcome them (after).
static func _pass_feature(k: Kit, kind: String) -> void:
	var r := k.rng
	match kind:
		"scree":
			for i in 14:
				var a := r.randf() * TAU
				var d := r.randf() * 1.2
				k.rock(Vector3(cos(a) * d, 0, sin(a) * d), Vector3.ONE * (0.15 + r.randf() * 0.3), STONE.lerp(STONE_DARK, r.randf()))
		"scree_fixed":
			for i in 5:
				k.box(Vector3(-0.8 + i * 0.4, 0.06 + i * 0.05, 0), Vector3(0.38, 0.12 + i * 0.1, 0.9), STONE.lerp(STONE_DARK, 0.2 * (i % 2)))
			for zz in [0.55, -0.55]:
				for i in 3:
					k.cylinder(Vector3(-0.6 + i * 0.6, 0, zz), 0.03, 0.03, 0.6, 4, WOOD_DARK)
		"river":
			k.box(Vector3(0, 0.05, 0), Vector3(0.9, 0.06, 2.6), Color("4d86a0"))
			for i in 6:
				k.rock(Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-1.2, 1.2)), Vector3.ONE * (0.12 + r.randf() * 0.12), STONE_DARK)
			k.box(Vector3(0, 0.09, 0), Vector3(0.3, 0.02, 2.4), Color("dfe9ec"))
		"river_fixed":
			k.box(Vector3(0, 0.05, 0), Vector3(0.9, 0.06, 2.6), Color("4d86a0"))
			for i in 5:
				k.cylinder(Vector3(-0.32 + i * 0.16, 0.12, 0.0), 0.07, 0.07, 0.8, 6, WOOD, Vector3.ZERO, Vector3(0, 0, 1))
			for zz in [1.3, -1.3]:
				k.cylinder(Vector3(0.5, 0, zz), 0.04, 0.04, 0.9, 4, WOOD_DARK)
			k.box(Vector3(0.5, 0.8, 0), Vector3(0.015, 0.015, 2.6), Color("c9b48a"))
		"gorge":
			k.box(Vector3(0, 0.01, 0), Vector3(0.8, 0.04, 2.6), Color("1e1a18"))
			for i in 8:
				k.rock(Vector3(r.randf_range(-0.9, 0.9), 0, r.randf_range(-1.3, 1.3)), Vector3.ONE * (0.12 + r.randf() * 0.2), STONE_DARK)
		"gorge_fixed":
			k.box(Vector3(0, 0.01, 0), Vector3(0.8, 0.04, 2.6), Color("1e1a18"))
			for i in 9:
				k.box(Vector3(-0.8 + i * 0.2, 0.32 - sin(PI * i / 8.0) * 0.12, 0), Vector3(0.16, 0.03, 0.5), WOOD.lightened(0.08 * (i % 2)))
			for xx in [-0.95, 0.95]:
				for zz in [0.3, -0.3]:
					k.cylinder(Vector3(xx, 0, zz), 0.04, 0.035, 0.75, 4, WOOD_DARK)
			for zz in [0.28, -0.28]:
				k.box(Vector3(0, 0.6, zz), Vector3(1.9, 0.015, 0.015), Color("c9b48a"))
		"glacier":
			for i in 9:
				var a := r.randf() * TAU
				var d := r.randf() * 1.1
				k.rock(Vector3(cos(a) * d, 0, sin(a) * d), Vector3(0.3, 0.25 + r.randf() * 0.3, 0.3), Color("dfeaf2").lerp(Color("a8c4d8"), r.randf()))
		"glacier_fixed":
			for p in [Vector3(-0.8, 0, 0.3), Vector3(0.0, 0, -0.3), Vector3(0.8, 0, 0.25)]:
				var y := 0.0
				for i in 4:
					var sz := 0.24 - i * 0.04
					k.rock(p + Vector3(0, y, 0), Vector3(sz, sz * 0.7, sz), STONE.lerp(STONE_DARK, 0.3 * (i % 2)))
					y += sz * 0.9
		"plank":
			for i in 10:
				k.box(Vector3(-1.0 + i * 0.22, 0.04, 0), Vector3(0.18, 0.05, 0.75), WOOD.lightened(0.06 * (i % 3)))


# ---------------------------------------------------------------- mesh kit

## Collects flat-shaded triangles with painted (slightly jittered) colours.
class Kit:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var rng := RandomNumberGenerator.new()
	var leafy := false # marks foliage (vertex alpha 0.5) so the shader can colour it by season

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
		col.a = 0.5 if leafy else 1.0
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

	## A dome sewn from patches: each facet is the base colour or, by `chance`, one of `patches`.
	func patch_dome(base: Vector3, r: float, h: float, col: Color, patches: Array, chance: float, segs := 10, rings := 4) -> void:
		center = base
		var pts := []
		for li in rings + 1:
			var row := []
			var lat := PI / 2.0 * li / rings
			for i in segs:
				var a := TAU * i / segs
				var wob := 1.0 + rng.randf_range(-0.04, 0.04) if li != rings else 1.0
				row.append(base + Vector3(cos(lat) * cos(a) * r * wob, sin(lat) * h, cos(lat) * sin(a) * r * wob))
			pts.append(row)
		for li in rings:
			for i in segs:
				var j := (i + 1) % segs
				var c := col
				if li < rings - 1 and rng.randf() < chance:
					c = patches[rng.randi() % patches.size()]
				quad(pts[li][i], pts[li][j], pts[li + 1][j], pts[li + 1][i], c.darkened(0.06 * (1.0 - float(li) / rings)))
		# stitched seams along the meridians
		for i in range(0, segs, 3):
			for li in rings - 1:
				var p: Vector3 = (pts[li][i] + pts[li + 1][i]) / 2.0
				var nrm: Vector3 = (p - base).normalized()
				box(p + nrm * 0.01, Vector3(0.025, 0.025, 0.025), Color("5a3a28"))
		center = base

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
