extends Node
## Headless test suite: godot --headless --path . res://tests/test_runner.tscn

var failures := 0
var passed := 0


func _ready() -> void:
	for m in get_method_list():
		if m.name.begins_with("test_"):
			var before := failures
			call(m.name)
			if failures == before:
				passed += 1
				print("  ✓ ", m.name)
			else:
				print("  ✗ ", m.name)
	print("%d passed, %d failed" % [passed, failures])
	get_tree().quit(1 if failures > 0 else 0)


func expect(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAILED: " + msg)
		print("    FAILED: ", msg)


func test_map_generation() -> void:
	var w := World.create(1234)
	expect(w.valleys.size() == Content.valleys.size(), "all valleys placed")
	expect(w.passes.size() == Content.passes.size(), "all passes carved")
	for p in w.passes:
		expect(p.tiles.size() > 3, "pass %d crosses mountains" % p.idx)
	expect(w.passes.size() > 5, "passes exist")
	var home := w.home_valley()
	expect(home.owner == World.PLAYER, "home is owned")
	expect(w.storage_of(home.idx) != null, "home storage yard")
	for v in w.valleys:
		var n := 0
		for i in w.valley.size():
			if w.valley[i] == v.idx and w.terrain[i] == World.GRASS:
				n += 1
		expect(n > 350, "valley %s has room (%d tiles)" % [v.def, n])
	expect("flint" in w.deposit.values(), "flint deposit placed")
	expect("tin" in w.deposit.values(), "tin deposit placed")


func test_deterministic() -> void:
	var a := World.create(99)
	var b := World.create(99)
	expect(a.terrain == b.terrain and a.nature == b.nature, "same seed, same map")
	Bot.run_minutes(a, 1)
	Bot.run_minutes(b, 1)
	expect(a.checksum() == b.checksum(), "same seed, same simulation")


func test_village_grows_and_settles_down() -> void:
	var w := World.create(42)
	var home: int = w.home_valley().idx
	Bot.lay_roads(w, home)
	for i in 6:
		expect(Bot.build_near(w, home, "tent"), "tent %d" % i)
	expect(Bot.build_near(w, home, "fireplace"), "fireplace")
	expect(Bot.build_near(w, home, "berrygatherer", 4), "berry gatherer")
	expect(Bot.build_near(w, home, "woodcutter", 4), "woodcutter")
	expect(Bot.build_near(w, home, "hunter", 4), "hunter")
	Bot.run_minutes(w, 2)
	for i in 12:
		Bot.build_near(w, home, "tent")
	Bot.build_near(w, home, "berrygatherer", 4)
	Bot.build_near(w, home, "hunter", 4)
	Bot.build_near(w, home, "fireplace")
	Bot.run_minutes(w, 6)
	var pop := w.player_population()
	expect(pop.foragers >= 60, "60+ foragers (got %d)" % pop.foragers)
	expect(w.tier_unlocked("sedentary"), "sedentary unlocked")
	expect(w.shells > 0, "still solvent (%d)" % w.shells)
	expect(w.valleys[home].storage.get("wood", 0) > 10, "woodcutter produces")
	# upgrades once hides arrive
	expect(Bot.build_near(w, home, "trapper", 4), "trapper")
	Bot.run_minutes(w, 3)
	expect(w.player_population().sedentary > 0, "a tent became a pit house")


func test_rejects_foreign_valley() -> void:
	var w := World.create(7)
	for v in w.valleys:
		if v.owner != World.PLAYER:
			var r := Commands.apply(w, {"type": "build", "building": "tent", "x": roundi(v.cx), "y": roundi(v.cy)})
			expect(not r.ok, "cannot build in %s" % v.def)


func _found(w: World, v: Dictionary) -> bool:
	for r in 10:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if Commands.apply(w, {"type": "build", "building": "storage", "x": roundi(v.cx) + dx, "y": roundi(v.cy) + dy}).ok:
					return true
	return false


func _valley(w: World, id: String) -> Dictionary:
	for v in w.valleys:
		if v.def == id:
			return v
	return {}


func _pass_between(w: World, a: int, b: int) -> Dictionary:
	for p in w.passes:
		if (p.a == a and p.b == b) or (p.a == b and p.b == a):
			return p
	return {}


func test_explore_settle_and_caravan() -> void:
	var w := World.create(5, "normal")
	w.shells = 50000
	var home := w.home_valley()
	w.unlocked_tiers.append("sedentary")
	home.storage.meat = 10.0
	home.storage.wood = 80.0
	home.storage.hides = 10.0
	Bot.lay_roads(w, home.idx)
	expect(Bot.build_near(w, home.idx, "scout"), "scout camp")
	var flint := _valley(w, "flint")
	var p := _pass_between(w, home.idx, flint.idx)
	expect(Commands.apply(w, {"type": "explore", "pass": p.idx, "from": home.idx}).ok, "expedition starts")
	Bot.run_minutes(w, 1)
	expect(flint.discovered, "valley discovered")
	expect(_found(w, flint) and flint.owner == World.PLAYER, "flint gorge founded over the open trail")
	# a scree pass blocks founding until a stairway is cut
	var flax := _valley(w, "flax")
	var scree := _pass_between(w, home.idx, flax.idx)
	expect(scree.obstacle == "scree", "home–flax is a scree slope")
	home.storage.meat = 10.0
	expect(Commands.apply(w, {"type": "explore", "pass": scree.idx, "from": home.idx}).ok, "second expedition")
	Bot.run_minutes(w, 1)
	expect(not _found(w, flax), "cannot found across an uncleared obstacle")
	home.storage.tools = 10.0
	expect(Commands.apply(w, {"type": "clear_pass", "pass": scree.idx}).ok, "stairway project starts")
	Bot.run_minutes(w, 1)
	expect(scree.cleared, "stairway finished")
	expect(_found(w, flax), "flax valley founded after clearing")
	# caravan between home and the flint gorge
	expect(Bot.build_near_pass(w, home.idx, "caravanpost"), "caravan camp at a pass")
	home.storage.wood = 60.0
	home.storage.hides = 10.0
	var r := Commands.apply(w, {"type": "buy_caravan", "valley": home.idx, "caravan": "porters"})
	expect(r.ok, "porter team hired (%s)" % r.get("reason", {}).get("en", ""))
	if not r.ok:
		return
	flint.storage.wood = 40.0
	Commands.apply(w, {"type": "caravan_stops", "id": r.id, "stops": [{"v": flint.idx, "load": ["wood"], "unload": []}, {"v": home.idx, "load": [], "unload": ["wood"]}]})
	var before: float = home.storage.get("wood", 0.0)
	Bot.run_minutes(w, 3)
	expect(home.storage.get("wood", 0.0) > before, "porters delivered wood")
	expect(not Commands.apply(w, {"type": "buy_caravan", "valley": home.idx, "caravan": "oxcart"}).ok, "ox carts need the chieftains")


func test_glacier_closes_in_winter() -> void:
	var w := World.create(3)
	var g := {}
	for p in w.passes:
		if p.obstacle == "glacier":
			g = p
	g.discovered = true
	g.cleared = true
	w.time = 0.0
	expect(Logistics.pass_open(w, g), "open in spring")
	w.time = World.SEASON_LENGTH * 3 + 1
	expect(not Logistics.pass_open(w, g), "closed in winter")
	expect(not Logistics.pass_open(w, g, true), "never for carts")


func test_content_is_consistent() -> void:
	var producible := {}
	for b in Content.buildings:
		for g in b.get("outputs", {}):
			producible[g] = true
	for b in Content.buildings:
		for g in b.get("inputs", {}):
			expect(producible.has(g), "%s input %s is produced somewhere" % [b.id, g])
		var req: Dictionary = b.get("requires", {})
		if req.has("fertility"):
			expect(Content.FERTILITY.has(req.fertility), "%s fertility %s exists" % [b.id, req.fertility])
			expect(Content.valleys.any(func(v): return req.fertility in v.fertilities), "some valley has %s" % req.fertility)
		if req.has("deposit"):
			expect(Content.valleys.any(func(v): return req.deposit in v.deposits), "some valley has deposit %s" % req.deposit)
		expect(Content.TIER.has(b.unlockTier), "%s tier exists" % b.id)
		if b.has("workforce"):
			expect(Content.tier_index(b.workforce.tier) <= Content.tier_index(b.unlockTier), "%s workers exist when it unlocks" % b.id)
	for t in Content.tiers:
		expect(Content.BUILDING.has(t.house), "house %s exists" % t.house)
		for n in t.needs:
			expect(producible.has(n.id) or Content.is_service(n.id), "%s need %s can be met" % [t.id, n.id])
		for g in t.get("upgradeCost", {}):
			expect(producible.has(g), "upgrade cost %s is producible" % g)
	for o in Content.obstacles:
		for g in o.get("cost", {}):
			expect(g == "shells" or producible.has(g), "obstacle cost %s producible" % g)
	for c in Content.caravans:
		for g in c.cost:
			expect(g == "shells" or producible.has(g), "caravan cost %s producible" % g)
	for b in Content.buildings:
		for g in b.cost:
			expect(g == "shells" or producible.has(g), "%s cost %s producible" % [b.id, g])
	for g in Content.goods:
		expect(producible.has(g.id), "good %s is produced" % g.id)


func test_save_roundtrip() -> void:
	var w := World.create(11)
	var home: int = w.home_valley().idx
	Bot.lay_roads(w, home)
	for i in 4:
		Bot.build_near(w, home, "tent")
	Bot.run_minutes(w, 1)
	var bytes := var_to_bytes(w.to_dict())
	var copy := World.from_dict(bytes_to_var(bytes))
	for i in 300:
		w.step()
		copy.step()
	expect(copy.checksum() == w.checksum(), "save/load stays in sync")


func test_models_and_3d_picking() -> void:
	for def in Content.buildings:
		if def.style != "path":
			var m := Models.mesh("buildings/" + def.id)
			expect(m.get_surface_count() > 0, "model for " + def.id)
	var w := World.create(5)
	var g := Game.new()
	add_child(g)
	g.start(w, false)
	var home := w.home_valley()
	var misses := 0
	for k in 25:
		var t := Vector2i(home.cx - 5 + k % 5 * 2, home.cy - 5 + k / 5 * 2)
		var sp: Vector2 = g.view.tile_to_screen(t.x + 0.5, t.y + 0.5)
		if g.view.screen_to_tile(sp) != t:
			misses += 1
	expect(misses == 0, "mouse picking hits the tile under the cursor (%d misses)" % misses)
	g.free()


func test_model_override_from_mod_folder() -> void:
	# export a model as .glb into the mod folder and check the game picks it up instead of the placeholder
	DirAccess.make_dir_recursive_absolute("user://mods/models/people")
	var path := "user://mods/models/people/porter.glb"
	var mi := MeshInstance3D.new()
	mi.name = "Porter"
	var k := Models.Kit.new(1)
	k.box(Vector3(0, 0.5, 0), Vector3.ONE, Color.RED)
	mi.mesh = k.commit(Models.material())
	var root := Node3D.new()
	root.add_child(mi)
	mi.owner = root
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	doc.append_from_scene(root, state)
	expect(doc.write_to_filesystem(state, path) == OK, "write test glb")
	root.free()
	Models._mesh_cache.erase("people/porter")
	var m := Models.mesh("people/porter")
	expect(m != null and m.get_aabb().size.y > 0.9, "mod .glb replaces the placeholder model")
	DirAccess.remove_absolute(path)
	Models._mesh_cache.erase("people/porter")
