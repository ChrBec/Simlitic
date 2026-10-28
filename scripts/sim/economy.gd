class_name Economy
## Core economic systems: path connectivity, workforce, production, needs, population, upgrades.


## Marks every building that reaches a storage yard of its own valley over paths.
static func update_connectivity(w: World) -> void:
	var reached := PackedByteArray()
	reached.resize(w.size * w.size)
	var queue: Array[int] = []
	for st in w.buildings.values():
		if st.type != "storage":
			continue
		for p in w.perimeter(st.type, st.x, st.y):
			_push(w, reached, queue, p.x, p.y)
	while not queue.is_empty():
		var i: int = queue.pop_back()
		var x := i % w.size
		var y := i / w.size
		_push(w, reached, queue, x + 1, y)
		_push(w, reached, queue, x - 1, y)
		_push(w, reached, queue, x, y + 1)
		_push(w, reached, queue, x, y - 1)
	for b in w.buildings.values():
		if b.type == "storage":
			b.connected = true
			continue
		var ok := false
		for p in w.perimeter(b.type, b.x, b.y):
			if not w.inside(p.x, p.y):
				continue
			var i := w.idx(p.x, p.y)
			if reached[i]:
				ok = true
				break
			var other: int = w.bmap[i]
			if other != 0 and w.buildings[other].type == "storage" and w.buildings[other].owner == b.owner:
				ok = true
				break
		b.connected = ok


static func _push(w: World, reached: PackedByteArray, queue: Array[int], x: int, y: int) -> void:
	if not w.inside(x, y):
		return
	var i := w.idx(x, y)
	if w.road[i] and not reached[i]:
		reached[i] = 1
		queue.append(i)


static func _center(b: Dictionary) -> Vector2:
	var s: Array = Content.BUILDING[b.type].size
	return Vector2(b.x + s[0] / 2.0, b.y + s[1] / 2.0)


## Service coverage per house: house id -> {service id: true}.
static func service_coverage(w: World) -> Dictionary:
	var out := {}
	var services := []
	for b in w.buildings.values():
		if b.owner == World.PLAYER and Content.BUILDING[b.type].has("service") and b.connected and not b.paused:
			services.append(b)
	for h in w.buildings.values():
		if not h.has("tier") or h.owner != World.PLAYER:
			continue
		var set := {}
		var hc := _center(h)
		for sv in services:
			if sv.valley != h.valley:
				continue
			var svc: Dictionary = Content.BUILDING[sv.type].service
			if hc.distance_to(_center(sv)) <= float(svc.radius):
				set[svc.id] = true
		out[h.id] = set
	return out


const SEASONAL_STYLES := ["field", "pasture"]


static func tick(w: World) -> void:
	var dt := World.TICK
	if w.tick % 5 == 0:
		update_connectivity(w)
	if w.coverage_tick < 0 or w.tick - w.coverage_tick >= 10:
		w.coverage = service_coverage(w)
		w.coverage_tick = w.tick

	# workforce & population per valley
	for v in w.valleys:
		v.workforce = {}
		v.population = {}
		for t in Content.tiers:
			v.workforce[t.id] = {"have": 0.0, "need": 0}
			v.population[t.id] = 0.0
	for b in w.buildings.values():
		if b.owner != World.PLAYER:
			continue
		var v: Dictionary = w.valleys[b.valley]
		if b.has("tier"):
			v.population[b.tier] += b.residents
			if b.connected:
				v.workforce[b.tier].have += b.residents
		var def: Dictionary = Content.BUILDING[b.type]
		if def.has("workforce") and not b.paused:
			v.workforce[def.workforce.tier].need += int(def.workforce.amount)

	var inc := 0.0
	var upk := 0.0
	for b in w.buildings.values():
		if b.owner != World.PLAYER:
			continue
		var def: Dictionary = Content.BUILDING[b.type]
		var v: Dictionary = w.valleys[b.valley]
		upk += float(def.upkeep) * (0.25 if b.paused else 1.0)
		if def.category == "production":
			_produce(w, b, def, v, dt)
		elif b.has("tier"):
			inc += _live(w, b, v, dt)

	w.income = inc
	for c in w.caravans:
		upk += float(Content.CARAVAN[c.type].upkeep)
	w.upkeep = upk
	w.shells += (w.income - w.upkeep) * dt / 60.0
	if w.tick % 20 == 0:
		_upgrades(w)
	if w.tick % 10 == 0:
		_unlock_tiers(w)


static func _produce(w: World, b: Dictionary, def: Dictionary, v: Dictionary, dt: float) -> void:
	if b.paused:
		b.status = "paused"
		b.productivity = 0.0
		return
	if not b.connected:
		b.status = "noRoad"
		b.productivity = 0.0
		return
	var wf: Dictionary = v.workforce[def.workforce.tier]
	var wf_ratio := 1.0 if wf.need <= 0 else minf(1.0, wf.have / wf.need)
	var nat_factor := 1.0
	var req: Dictionary = def.get("requires", {})
	if req.has("nature"):
		if b.nature < 0 or (w.tick + b.id) % 20 == 0:
			var kind := World.N_TREE if req.nature.kind == "tree" else World.N_BUSH
			b.nature = minf(1.0, float(w.nature_around(b, kind, int(req.nature.radius))) / float(req.nature.min))
		nat_factor = b.nature
	# fields and pastures rest in winter – stock up in autumn
	var season_factor := 0.3 if w.is_winter() and def.style in SEASONAL_STYLES else 1.0
	var prod := wf_ratio * nat_factor * season_factor
	b.productivity = prod
	if not b.working:
		var cap := w.storage_cap(b.valley)
		for g in def.get("outputs", {}):
			if v.storage.get(g, 0.0) >= cap:
				b.status = "full"
				return
		var inputs: Dictionary = def.get("inputs", {})
		if not inputs.is_empty():
			if not w.can_afford(inputs, v.storage):
				b.status = "noInput"
				b.productivity = 0.0
				return
			w.pay(inputs, v.storage)
		b.working = true
		b.progress = 0.0
	b.status = "noWorkers" if wf_ratio < 0.99 else ("noNature" if nat_factor < 0.99 else ("winter" if season_factor < 1.0 else "ok"))
	b.progress += dt * prod / float(def.cycle)
	if b.progress >= 1.0:
		var cap := w.storage_cap(b.valley)
		for g in def.get("outputs", {}):
			v.storage[g] = minf(cap, v.storage.get(g, 0.0) + def.outputs[g])
		b.working = false
		b.progress = 0.0


## Consumes goods for a house, updates satisfaction and residents; returns income per minute.
static func _live(w: World, b: Dictionary, v: Dictionary, dt: float) -> float:
	var tier: Dictionary = Content.TIER[b.tier]
	var covered: Dictionary = w.coverage.get(b.id, {})
	var target := float(tier.baseResidents)
	var res: float = b.residents
	var inc := 0.0
	for need in tier.needs:
		var ratio := 0.0
		if need.kind == "service" or need.kind == "service-luxury":
			ratio = 1.0 if b.connected and covered.has(need.id) else 0.0
		elif b.connected and Content.GOOD.has(need.id):
			var demand := res * float(need.get("consumption", 0.0)) * dt / 60.0
			var have: float = v.storage.get(need.id, 0.0)
			var take := minf(have, demand)
			v.storage[need.id] = have - take
			ratio = take / demand if demand > 0.0 else (1.0 if have > 0.0 else 0.0)
		var prev: float = b.needs.get(need.id, 0.0)
		var sat := prev + (ratio - prev) * 0.02 # smoothed over ~5 s
		b.needs[need.id] = sat
		if need.has("residents"):
			target += float(need.residents) * clampf((sat - 0.2) / 0.7, 0.0, 1.0)
		inc += float(need.income) * res * sat
	var step := dt / 4.0 # about one resident every four seconds
	b.residents = minf(target, res + step) if res < target else maxf(target, res - step)
	return inc


## Upgrades at most one house per valley every two seconds when needs are met and materials are stocked.
static func _upgrades(w: World) -> void:
	var done := {}
	for b in w.buildings.values():
		if not b.has("tier") or b.owner != World.PLAYER or done.has(b.valley) or not b.connected:
			continue
		var tier: Dictionary = Content.TIER[b.tier]
		var nt = Content.next_tier(b.tier)
		if nt == null or not w.tier_unlocked(nt.id) or not w.upgrade_allowed[b.tier]:
			continue
		var met := true
		for n in tier.needs:
			if (n.kind == "basic" or n.kind == "service") and b.needs.get(n.id, 0.0) < 0.85:
				met = false
				break
		if not met:
			continue
		var v: Dictionary = w.valleys[b.valley]
		if not w.can_afford(nt.upgradeCost, v.storage):
			continue
		w.pay(nt.upgradeCost, v.storage)
		b.type = nt.house
		b.tier = nt.id
		b.needs = {}
		done[b.valley] = true
		w.dirty += 1


static func _unlock_tiers(w: World) -> void:
	var pop := w.player_population()
	for t in Content.tiers:
		if t.unlock == null or w.tier_unlocked(t.id):
			continue
		if pop[t.unlock.tier] >= int(t.unlock.population):
			w.unlocked_tiers.append(t.id)
			w.notify({"de": "Eine neue Zeit beginnt: %s (%s). %s" % [t.name.de, t.age.de, t.intro.de], "en": "A new age begins: %s (%s). %s" % [t.name.en, t.age.en, t.intro.en]}, "tier")


## Production and consumption per minute for every good (Anno's balance view).
static func good_balance(w: World, only_valley := -1) -> Dictionary:
	var out := {}
	for b in w.buildings.values():
		if b.owner != World.PLAYER or (only_valley >= 0 and b.valley != only_valley):
			continue
		var def: Dictionary = Content.BUILDING[b.type]
		if def.category == "production":
			var rate: float = 60.0 / float(def.cycle) * b.productivity
			for g in def.get("outputs", {}):
				_add(out, g, "prod", def.outputs[g] * rate)
			for g in def.get("inputs", {}):
				_add(out, g, "cons", def.inputs[g] * rate)
		if b.has("tier"):
			for need in Content.TIER[b.tier].needs:
				if need.has("consumption"):
					_add(out, need.id, "cons", b.residents * float(need.consumption))
	return out


static func _add(out: Dictionary, g: String, k: String, n: float) -> void:
	if not out.has(g):
		out[g] = {"prod": 0.0, "cons": 0.0}
	out[g][k] += n
