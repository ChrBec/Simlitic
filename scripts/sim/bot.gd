class_name Bot
## A tiny scripted player: used by tests, balancing runs and the living main-menu backdrop.


## Lays a cross of paths with side streets around the valley's storage yard.
static func lay_roads(w: World, v: int, arm := 14) -> void:
	var st = w.storage_of(v)
	var cx: int = st.x + 1
	var cy: int = st.y + 1
	var tiles := []
	for d in range(2, arm + 1):
		tiles.append_array([Vector2i(cx + d, cy), Vector2i(cx - d, cy), Vector2i(cx, cy + d), Vector2i(cx, cy - d)])
	for off in ([-6, 6] if arm < 16 else [-12, -6, 6, 12]):
		for d in range(-arm, arm + 1):
			tiles.append_array([Vector2i(cx + off, cy + d), Vector2i(cx + d, cy + off)])
	Commands.apply(w, {"type": "path", "tiles": tiles})


## Places a building at the closest valid spot that touches a path.
static func build_near(w: World, v: int, type: String, min_dist := 0.0) -> bool:
	var st = w.storage_of(v)
	var cands := []
	for y in range(st.y - 20, st.y + 21):
		for x in range(st.x - 20, st.x + 21):
			var d := Vector2(x - st.x, y - st.y).length()
			if d >= min_dist:
				cands.append([d, x, y])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var req: Dictionary = Content.BUILDING[type].get("requires", {})
	var reach := _reached_roads(w)
	var best = null
	var best_score := -1e9
	var looked := 0
	for c in cands:
		var x: int = c[1]
		var y: int = c[2]
		if not w.check_placement(type, x, y).ok:
			continue
		var touches := false
		for p in w.perimeter(type, x, y):
			if w.inside(p.x, p.y) and reach[w.idx(p.x, p.y)]:
				touches = true
				break
		if not touches:
			continue
		if not req.has("nature"):
			return Commands.apply(w, {"type": "build", "building": type, "x": x, "y": y}).ok
		# gatherers and woodcutters: among the nearer spots, take the one with the richest surroundings
		var probe := {"type": type, "x": x, "y": y}
		var kind := World.N_TREE if req.nature.kind == "tree" else World.N_BUSH
		var n := w.nature_around(probe, kind, int(req.nature.radius))
		if n >= int(req.nature.min) and n - float(c[0]) * 0.5 > best_score:
			best_score = n - float(c[0]) * 0.5
			best = Vector2i(x, y)
		looked += 1
		if looked > 60:
			break
	if best != null:
		return Commands.apply(w, {"type": "build", "building": type, "x": best.x, "y": best.y}).ok
	return false


## Road tiles that lead to a storage yard (a building touching one of them is connected).
static func _reached_roads(w: World) -> PackedByteArray:
	var reached := PackedByteArray()
	reached.resize(w.size * w.size)
	var queue: Array[int] = []
	for st in w.buildings.values():
		if st.type == "storage" and st.owner == World.PLAYER:
			for p in w.perimeter(st.type, st.x, st.y):
				Economy._push(w, reached, queue, p.x, p.y)
	while not queue.is_empty():
		var i: int = queue.pop_back()
		var x := i % w.size
		var y := i / w.size
		Economy._push(w, reached, queue, x + 1, y)
		Economy._push(w, reached, queue, x - 1, y)
		Economy._push(w, reached, queue, x, y + 1)
		Economy._push(w, reached, queue, x, y - 1)
	return reached


static func run_minutes(w: World, minutes: float) -> void:
	for i in int(minutes * 600):
		w.step()


## Places a building at the mouth of a pass leaving valley `v` (caravan camps must stand there).
static func build_near_pass(w: World, v: int, type: String) -> bool:
	for p in w.passes:
		if p.a != v and p.b != v:
			continue
		for t in p.tiles:
			var x: int = t % w.size
			var y: int = t / w.size
			for r in range(1, 7):
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if w.inside(x + dx, y + dy) and w.valley[w.idx(x + dx, y + dy)] == v and w.check_placement(type, x + dx, y + dy).ok:
							return Commands.apply(w, {"type": "build", "building": type, "x": x + dx, "y": y + dy}).ok
	return false


# ---------------------------------------------------------------- a quest-following player

## Plays the story like a steady, not very clever human: accepts every task, follows its goals,
## keeps the active needs supplied, builds homes when they are full and upgrades homes that are
## ready. Used by tests and tools/balance to check pacing. `log` collects milestones.
static func play(w: World, minutes: float, log := [], think_every := 8.0) -> void:
	var home: int = w.home_valley().idx
	var st = w.storage_of(home)
	if st != null and not w.road[w.idx(st.x + 3, st.y + 1)]:
		lay_roads(w, home, 18)
	var think := int(think_every / World.TICK)
	var tiers := w.unlocked_tiers.size()
	for i in int(minutes * 600):
		if w.tick % think == 0:
			_think(w, home)
		w.step()
		if w.unlocked_tiers.size() != tiers:
			tiers = w.unlocked_tiers.size()
			log.append({"t": w.time, "tier": w.unlocked_tiers[-1]})
		if w.won:
			log.append({"t": w.time, "won": true})
			return


static var _reserve := {} # goods the current tasks ask to stock up: don't spend them on buildings


static func _think(w: World, home: int) -> void:
	_reserve = {}
	for q in Story.active_quests(w):
		for g in q.goals:
			if g.type in ["stock", "deliver"]:
				_reserve[g.good] = maxf(_reserve.get(g.good, 0.0), float(g.n))
	# tasks: accept every offer, take the first reward when there is a choice, click every find
	for c in Content.characters:
		var qid := Story.offered(w, c.id)
		if qid == "":
			continue
		if w.quests[qid].state == "offered":
			Commands.apply(w, {"type": "accept_quest", "id": qid})
		elif w.quests[qid].state == "choose":
			Commands.apply(w, {"type": "quest_choice", "id": qid, "choice": 0})
	for f in w.finds:
		if not f.found:
			Commands.apply(w, {"type": "find", "id": f.id})
	for item in w.items.duplicate():
		for slot in World.NICHES:
			if w.valleys[home].niches[slot] == "":
				Commands.apply(w, {"type": "place_item", "item": item, "valley": home, "slot": slot})
				break
	for q in Story.active_quests(w):
		var s: Dictionary = w.quests[q.id]
		for gi in q.goals.size():
			var p := Story.progress(w, q, gi, s)
			if p[0] < p[1]:
				_pursue(w, home, q.goals[gi])
	_keep_up(w, home)


## Builds `type` near the storage yard; when building materials are missing, sees to their producers.
static func _try_build(w: World, home: int, type: String, dist := -1.0) -> bool:
	if not w.is_unlocked(type):
		return false
	var cost: Dictionary = Content.BUILDING[type].cost
	var st: Dictionary = w.valleys[home].storage
	for g in cost:
		if g == "shells":
			if w.shells < float(cost[g]) + 50.0:
				return false
		elif st.get(g, 0.0) - _reserve.get(g, 0.0) < float(cost[g]):
			if st.get(g, 0.0) < float(cost[g]):
				_ensure_producer(w, home, g)
			return false
	return build_near(w, home, type, _dist(type) if dist < 0.0 else dist)


## One step towards a quest goal.
static func _pursue(w: World, home: int, g: Dictionary) -> void:
	match g.type:
		"build":
			_try_build(w, home, g.building)
		"stock", "deliver", "produce", "winter_food":
			var good: String = g.get("good", "berries")
			if g.type == "winter_food":
				good = "berries" if w.count("nutgatherer", false, home) > 0 or not w.is_unlocked("nutgatherer") else "nuts"
			_ensure_producer(w, home, good, 2 if g.type == "winter_food" else 1)
		"served":
			var homes := w.buildings.values().filter(func(b): return b.owner == World.PLAYER and b.has("tier")).size()
			if homes < int(g.n) + 1:
				_try_build(w, home, "tent")
			else:
				for h in w.buildings.values():
					if h.owner == World.PLAYER and h.has("tier") and not w.coverage.get(h.id, {}).has(g.service):
						if w.can_afford(Content.BUILDING[g.service].cost, w.valleys[home].storage):
							_build_close(w, g.service, h)
						break
		"festival":
			Commands.apply(w, {"type": "festival", "valley": home, "festival": g.festival})
		"custom":
			for c in Content.customs:
				if Commands.apply(w, {"type": "custom", "custom": c.id, "on": true}).ok:
					break
		"explore", "valleys", "contact":
			if w.count("scout", false, home) == 0:
				_try_build(w, home, "scout", 0)
			for p in w.passes:
				if not p.discovered and (w.valleys[p.a].owner == World.PLAYER or w.valleys[p.b].owner == World.PLAYER):
					var from: int = p.a if w.valleys[p.a].owner == World.PLAYER else p.b
					if Commands.apply(w, {"type": "explore", "pass": p.idx, "from": from}).ok:
						break
			if g.type == "valleys":
				_found_one(w)
		"caravan":
			if w.count("caravanpost", false, home) == 0:
				build_near_pass(w, home, "caravanpost")
			Commands.apply(w, {"type": "buy_caravan", "valley": home, "caravan": "porters"})


static func _dist(type: String) -> float:
	return 5.0 if Content.BUILDING[type].category == "production" else 0.0


## Makes sure something in the valley produces `good` (and, one level down, its inputs).
static func _ensure_producer(w: World, home: int, good: String, want := 1) -> void:
	for def in Content.buildings:
		if not def.get("outputs", {}).has(good) or not w.is_unlocked(def.id):
			continue
		if w.count(def.id, false, home) >= want:
			return
		for inp in def.get("inputs", {}):
			var has_input := false
			for d2 in Content.buildings:
				if d2.get("outputs", {}).has(inp) and w.count(d2.id, false, home) > 0:
					has_input = true
			if not has_input:
				_ensure_producer(w, home, inp)
		_try_build(w, home, def.id, 5)
		return


static func _found_one(w: World) -> void:
	for v in w.valleys:
		if v.discovered and v.owner == null:
			for r in 8:
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if Commands.apply(w, {"type": "build", "building": "storage", "x": roundi(v.cx) + dx, "y": roundi(v.cy) + dy}).ok:
							lay_roads(w, v.idx, 8)
							return


## Everyday housekeeping: food and needs, homes, firewood, storage, upgrades.
static func _keep_up(w: World, home: int) -> void:
	var v: Dictionary = w.valleys[home]
	var pop := w.player_population()
	var houses := w.buildings.values().filter(func(b): return b.owner == World.PLAYER and b.has("tier") and b.valley == home)
	# needs that are active and short: build a producer or a service close to the homes
	var bal := _nominal_balance(w, home)
	for t in Content.tiers:
		if pop.get(t.id, 0) <= 0:
			continue
		for need in t.needs:
			if not Economy.need_active(need, pop, t.id):
				continue
			if Content.is_service(need.id):
				for h in houses:
					if h.tier == t.id and not w.coverage.get(h.id, {}).has(need.id) and w.is_unlocked(need.id):
						if w.can_afford(Content.BUILDING[need.id].cost, w.valleys[home].storage):
							_build_close(w, need.id, h)
						break
			else:
				if bal.get(need.id, 0.0) < 0.3:
					_more_producers(w, home, need.id)
	# wood for building and winter fires
	if v.storage.get("wood", 0.0) < 25.0 and w.count("woodcutter", false, home) < 2 + houses.size() / 6:
		_try_build(w, home, "woodcutter", 5)
	# homes: a new one when every home is (nearly) full and immigration has nowhere to go
	var free := 0.0
	for h in houses:
		free += maxf(0.0, h.get("target", 1.0) - h.residents)
	if (free < 1.0 or houses.size() < 6) and houses.size() < 70 and v.storage.get("wood", 0.0) >= 8.0:
		_try_build(w, home, "tent")
	# storage when goods pile up at the cap
	var cap := w.storage_cap(home)
	for g in v.storage:
		if v.storage[g] >= cap - 1 and g != "wood":
			if not (w.count("storagepit", false, home) < 6 and _try_build(w, home, "storagepit", 3)) and w.count("storage", false, home) < 3:
				_try_build(w, home, "storage", 6)
			break
	# upgrades
	var n := 0
	for h in houses:
		if h.get("ready", false) and n < 4:
			if Commands.apply(w, {"type": "upgrade", "id": h.id}).ok:
				n += 1
	# a festival whenever one is possible and the mood could use it
	if v.mood < 60.0:
		for f in w.festivals_unlocked:
			if Commands.apply(w, {"type": "festival", "valley": home, "festival": f}).ok:
				break


## Production and consumption per minute as if every workshop ran at full speed (the season-free view).
static func _nominal_balance(w: World, home: int) -> Dictionary:
	var out := {}
	var pop := w.player_population()
	for b in w.buildings.values():
		if b.owner != World.PLAYER or b.valley != home:
			continue
		var def: Dictionary = Content.BUILDING[b.type]
		if def.category == "production":
			for g in def.get("outputs", {}):
				out[g] = out.get(g, 0.0) + def.outputs[g] * 60.0 / float(def.cycle) * 0.85
			for g in def.get("inputs", {}):
				out[g] = out.get(g, 0.0) - def.inputs[g] * 60.0 / float(def.cycle) * 0.85
		if b.has("tier"):
			for need in Content.TIER[b.tier].needs:
				if need.has("consumption") and Economy.need_active(need, pop, b.tier):
					out[need.id] = out.get(need.id, 0.0) - maxf(b.residents, b.get("target", 1.0)) * float(need.consumption)
	return out


static func _more_producers(w: World, home: int, good: String) -> void:
	for def in Content.buildings:
		if def.get("outputs", {}).has(good) and w.is_unlocked(def.id):
			var n := w.count(def.id, false, home)
			if n < 8:
				_ensure_producer(w, home, good, n + 1)
			return


## Places a service building close to a home that lacks it.
static func _build_close(w: World, type: String, near: Dictionary) -> bool:
	var reach := _reached_roads(w)
	var cands := []
	for y in range(near.y - 8, near.y + 9):
		for x in range(near.x - 8, near.x + 9):
			cands.append([Vector2(x - near.x, y - near.y).length(), x, y])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	for c in cands:
		var x: int = c[1]
		var y: int = c[2]
		if not w.check_placement(type, x, y).ok:
			continue
		for p in w.perimeter(type, x, y):
			if w.inside(p.x, p.y) and reach[w.idx(p.x, p.y)]:
				return Commands.apply(w, {"type": "build", "building": type, "x": x, "y": y}).ok
	return false
