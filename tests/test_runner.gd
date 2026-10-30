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
	Bot.play(a, 4)
	Bot.play(b, 4)
	expect(a.checksum() == b.checksum(), "same seed, same simulation (story included)")
	# crises and luck from the third year on: still in lockstep
	for w in [a, b]:
		w.time = World.YEAR * 3.0 - 2.0
	for i in int(World.YEAR * 1.2 / World.TICK):
		a.step()
		b.step()
	expect(a.checksum() == b.checksum(), "events stay deterministic")


func test_story_opens_the_game_step_by_step() -> void:
	var w := World.create(42)
	var home: int = w.home_valley().idx
	expect(Story.here(w, "ama"), "Ama is there from the start")
	expect(Story.offered(w, "ama") == "ama_heart", "Ama offers the first task")
	expect(not w.is_unlocked("tent") and not w.is_unlocked("hearth"), "nothing to build but paths before the first task")
	expect(Commands.apply(w, {"type": "accept_quest", "id": "ama_heart"}).ok, "accept the first task")
	expect(w.is_unlocked("hearth"), "accepting unlocks the valley heart")
	Bot.lay_roads(w, home)
	expect(Bot.build_near(w, home, "hearth", 3), "hearth built")
	expect(not Commands.apply(w, {"type": "build", "building": "hearth", "x": 0, "y": 0}).ok, "only one valley heart")
	for i in 20:
		w.step()
	expect(w.quests.ama_heart.state == "done", "first task done")
	expect(w.is_unlocked("tent"), "reward: hide domes")
	expect(Story.offered(w, "ama") == "ama_roof", "the next task follows")
	expect(not Story.here(w, "borr"), "Borr is still away")


func test_pacing_no_second_age_in_ten_minutes() -> void:
	var w := World.create(42)
	var log := []
	Bot.play(w, 12, log)
	var pop := w.player_population()
	expect(pop.foragers >= 40, "the village grows (%d foragers)" % pop.foragers)
	expect(not w.tier_unlocked("sedentary"), "no second age after 12 minutes (the concept: ~30)")
	expect(log.is_empty(), "no age change logged")
	expect(Story.here(w, "borr") and Story.here(w, "sela"), "Borr and Sela have arrived")
	expect(w.quests.get("ama_warmth", {}).get("state", "") == "done", "early tasks done")
	var houses := w.buildings.values().filter(func(b): return b.owner == World.PLAYER and b.has("tier"))
	expect(houses.all(func(b): return b.tier == "foragers"), "no home upgraded itself")


func test_manual_upgrade() -> void:
	var w := World.create(8, "sandbox")
	var home: int = w.home_valley().idx
	var v: Dictionary = w.valleys[home]
	Bot.lay_roads(w, home)
	for i in 3:
		expect(Bot.build_near(w, home, "tent"), "tent %d" % i)
	expect(Bot.build_near(w, home, "fireplace"), "fireplace")
	expect(Bot.build_near(w, home, "berrygatherer", 4), "berry gatherer")
	v.storage.berries = 60.0
	Bot.run_minutes(w, 2)
	var tents := w.buildings.values().filter(func(b): return b.type == "tent" and b.owner == World.PLAYER)
	expect(tents.size() == 3, "homes stay tents until the player acts (%s)" % [w.buildings.values().map(func(b): return b.type)])
	var ready := tents.filter(func(b): return b.ready)
	expect(not ready.is_empty(), "a content home is ready for the next age")
	if ready.is_empty():
		return
	var b: Dictionary = ready[0]
	v.storage.wood = 0.0
	expect(not Commands.apply(w, {"type": "upgrade", "id": b.id}).ok, "upgrading needs building materials")
	v.storage.wood = 10.0
	v.storage.hides = 5.0
	v.storage.stone = 5.0
	expect(Commands.apply(w, {"type": "lock_upgrade", "id": b.id, "locked": true}).ok, "lock")
	expect(not Commands.apply(w, {"type": "upgrade", "id": b.id}).ok, "a locked home is not upgraded")
	Commands.apply(w, {"type": "lock_upgrade", "id": b.id, "locked": false})
	expect(Commands.apply(w, {"type": "upgrade", "id": b.id}).ok, "upgrade")
	expect(b.type == "hut" and b.tier == "sedentary", "the dome became a pit house")
	expect(v.storage.stone == 3.0, "fieldstones were used")


func test_winter_firewood_spoilage_and_wildlife() -> void:
	var w := World.create(9, "sandbox")
	var home: int = w.home_valley().idx
	var v: Dictionary = w.valleys[home]
	Bot.lay_roads(w, home)
	for i in 4:
		Bot.build_near(w, home, "tent")
	v.storage = {"berries": 30.0, "wood": 0.0}
	w.time = World.SEASON_LENGTH * 3.0 + 1.0
	w.last_season = World.WINTER
	for i in 100:
		w.step()
	expect(v.freezing, "no firewood in winter: the homes freeze")
	expect(v.storage.berries < 30.0, "food is eaten or spoils")
	v.storage.wood = 50.0
	for i in 50:
		w.step()
	expect(not v.freezing, "firewood warms the homes")
	expect(v.storage.wood < 50.0, "firewood is burnt")
	# wildlife: hunters thin out the game
	w.time = World.SEASON_LENGTH + 1.0
	w.last_season = 1
	for i in 6:
		Bot.build_near(w, home, "hunter", 4)
	var game: float = v.game
	Bot.run_minutes(w, 3)
	expect(v.game < game, "hunting thins the game (%.2f → %.2f)" % [game, v.game])


func test_festival_and_treasures() -> void:
	var w := World.create(10, "sandbox")
	var home: int = w.home_valley().idx
	var v: Dictionary = w.valleys[home]
	Bot.lay_roads(w, home)
	expect(not Commands.apply(w, {"type": "festival", "valley": home, "festival": "herdfest"}).ok, "festivals need a valley heart")
	expect(Bot.build_near(w, home, "hearth", 3), "valley heart")
	v.storage = {"meat": 40.0, "berries": 40.0, "wood": 40.0}
	expect(Commands.apply(w, {"type": "festival", "valley": home, "festival": "herdfest"}).ok, "herd feast")
	expect(v.storage.meat == 20.0, "the feast costs supplies")
	expect(not Commands.apply(w, {"type": "festival", "valley": home, "festival": "herdfest"}).ok, "once a year")
	expect(w.stats.festivals.get("herdfest", 0) == 1, "counted")
	w.items.append("flute")
	expect(Commands.apply(w, {"type": "place_item", "item": "flute", "valley": home, "slot": 0}).ok, "treasure into a niche")
	expect(Life.mods(w, home).get("mood", 0.0) > 0.0, "the flute and the feast lift the mood")


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
	var w := World.create(5)
	w.shells = 50000
	w.prestige_pts = 100.0
	var home := w.home_valley()
	w.unlocked_tiers.append("sedentary")
	for b in Content.buildings:
		if b.unlockTier in w.unlocked_tiers:
			w.unlocked[b.id] = true
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
	flint.storage.wood = 25.0
	home.storage.wood = 5.0
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
	# the story: every reference resolves and every building can be unlocked somehow
	var unlockable := {}
	for b in Content.buildings:
		var u: Dictionary = b.get("unlock", {})
		if u.get("start", false) or u.has("pop") or u.has("quest"):
			unlockable[b.id] = true
	for c in Content.characters:
		expect(Content.BUILDING.has(c.home), "%s lives at %s" % [c.id, c.home])
	for q in Content.quests:
		expect(Content.CHARACTER.has(q.char), "%s belongs to %s" % [q.id, q.char])
		for a in q.after:
			expect(Content.QUEST.has(a), "%s comes after %s" % [q.id, a])
		for b in q.unlock + q.reward.get("unlock", []):
			expect(Content.BUILDING.has(b), "%s unlocks %s" % [q.id, b])
			unlockable[b] = true
		for i in q.reward.get("items", []):
			expect(Content.ITEM.has(i), "%s gives %s" % [q.id, i])
		for f in q.get("festivals", []):
			expect(Content.FESTIVAL.has(f), "%s teaches %s" % [q.id, f])
		for g in q.goals:
			if g.has("building"):
				expect(Content.BUILDING.has(g.building), "%s goal %s" % [q.id, g.building])
			if g.has("good"):
				expect(Content.GOOD.has(g.good), "%s goal %s" % [q.id, g.good])
	for t in Content.tiers.slice(1):
		unlockable[t.house] = true # reached by upgrading, never built directly
	for b in Content.buildings:
		expect(unlockable.has(b.id), "%s can be unlocked" % b.id)
	for t in Content.tiers.slice(1):
		expect(Content.quests.any(func(q): return q.reward.get("tier", "") == t.id), "a threshold task opens %s" % t.id)


func test_save_roundtrip() -> void:
	var w := World.create(11)
	Bot.play(w, 4)
	expect(w.quests.size() > 2, "some story to save")
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
