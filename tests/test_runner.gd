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
	expect(w.valleys.size() == 7, "seven valleys")
	expect(w.passes.size() > 5, "passes exist")
	var home := w.home_valley()
	expect(home.owner == World.PLAYER, "home is owned")
	expect(w.storage_of(home.idx) != null, "home storage yard")
	for v in w.valleys:
		var n := 0
		for i in w.valley.size():
			if w.valley[i] == v.idx and w.terrain[i] == World.GRASS:
				n += 1
		expect(n > 150, "valley %s has room (%d tiles)" % [v.def, n])
	expect("flint" in w.deposit.values(), "flint deposit placed")
	expect("tin" in w.deposit.values(), "tin deposit placed")


func test_deterministic() -> void:
	var a := World.create(99)
	var b := World.create(99)
	expect(a.terrain == b.terrain and a.nature == b.nature, "same seed, same map")
	Bot.run_minutes(a, 1)
	Bot.run_minutes(b, 1)
	expect(a.checksum() == b.checksum(), "same seed, same simulation")


func test_village_grows_and_unlocks_hunters() -> void:
	var w := World.create(42)
	var home: int = w.home_valley().idx
	Bot.lay_roads(w, home)
	for i in 4:
		expect(Bot.build_near(w, home, "tent"), "tent %d" % i)
	expect(Bot.build_near(w, home, "fireplace"), "fireplace")
	expect(Bot.build_near(w, home, "berrygatherer", 4), "berry gatherer")
	expect(Bot.build_near(w, home, "woodcutter", 4), "woodcutter")
	Bot.run_minutes(w, 2)
	for i in 8:
		Bot.build_near(w, home, "tent")
	Bot.build_near(w, home, "berrygatherer", 4)
	Bot.build_near(w, home, "fireplace")
	Bot.run_minutes(w, 6)
	var pop := w.player_population()
	expect(pop.gatherers >= 40, "40+ gatherers (got %d)" % pop.gatherers)
	expect(w.tier_unlocked("hunters"), "hunters unlocked")
	expect(w.shells > 0, "still solvent (%d)" % w.shells)
	expect(w.valleys[home].storage.get("wood", 0) > 10, "woodcutter produces")
	# upgrades once hides arrive
	expect(Bot.build_near(w, home, "trapper", 4), "trapper")
	Bot.run_minutes(w, 3)
	expect(w.player_population().hunters > 0, "a tent became a bark hut")


func test_rejects_foreign_valley() -> void:
	var w := World.create(7)
	for v in w.valleys:
		if v.owner != World.PLAYER:
			var r := Commands.apply(w, {"type": "build", "building": "tent", "x": roundi(v.cx), "y": roundi(v.cy)})
			expect(not r.ok, "cannot build in %s" % v.def)


func test_explore_settle_and_route() -> void:
	var w := World.create(5, "normal")
	w.shells = 50000
	var home := w.home_valley()
	w.unlocked_tiers.append("hunters")
	home.storage.meat = 10.0
	home.storage.wood = 80.0
	Bot.lay_roads(w, home.idx)
	expect(Bot.build_near(w, home.idx, "scout"), "scout camp")
	var pass_idx := -1
	for p in w.passes:
		if p.a == home.idx or p.b == home.idx:
			pass_idx = p.idx
			break
	expect(Commands.apply(w, {"type": "explore", "pass": pass_idx, "from": home.idx}).ok, "expedition starts")
	Bot.run_minutes(w, 1)
	var p: Dictionary = w.passes[pass_idx]
	var other: Dictionary = w.valleys[p.b if p.a == home.idx else p.a]
	expect(other.discovered, "valley discovered")
	var founded := false
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if not founded:
					founded = Commands.apply(w, {"type": "build", "building": "storage", "x": roundi(other.cx) + dx, "y": roundi(other.cy) + dy}).ok
	expect(founded and other.owner == World.PLAYER, "second valley founded")
	expect(Commands.apply(w, {"type": "create_route", "a": other.idx, "b": home.idx}).ok, "route created")
	other.storage.wood = 40.0
	Commands.apply(w, {"type": "route_cargo", "id": w.routes[0].id, "dir": "ab", "goods": ["wood"]})
	var before: float = home.storage.get("wood", 0.0)
	Bot.run_minutes(w, 2)
	expect(home.storage.get("wood", 0.0) > before, "porters delivered wood")


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
