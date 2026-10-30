class_name Economy
## Core economic systems: path connectivity, workforce, production, needs, mood and residents.


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


## Season multipliers per production group: spring, summer, autumn, winter.
const SEASON := {
	"gather": [0.8, 1.0, 1.5, 0.0], "field": [0.5, 1.0, 1.5, 0.0], "pasture": [1.0, 1.0, 1.0, 0.5],
	"hunt": [0.9, 1.0, 1.25, 0.6], "fish": [1.0, 1.0, 1.0, 0.6], "stone": [1.0, 1.0, 1.0, 0.5],
}
const READY_NEEDS := 0.7 # basic needs a house must reach before it may be upgraded
const LEAVE_TIME := 8.0 # seconds per resident who moves out of an overcrowded or unhappy house


static func tick(w: World) -> void:
	var dt := World.TICK
	if w.tick % 5 == 0:
		update_connectivity(w)
	if w.coverage_tick < 0 or w.tick - w.coverage_tick >= 10:
		w.coverage = service_coverage(w)
		w.coverage_tick = w.tick
		_surroundings(w)

	# workforce, population and modifiers per valley
	var tier_pop := w.player_population()
	for v in w.valleys:
		v.workforce = {}
		v.population = {}
		for t in Content.tiers:
			v.workforce[t.id] = {"have": 0.0, "need": 0}
			v.population[t.id] = 0.0
		if v.owner == World.PLAYER:
			v.mods = Life.mods(w, v.idx)
			v.food_short = ""
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
		var m: Dictionary = v.get("mods", {})
		upk += float(def.upkeep) * (0.25 if b.paused else 1.0) * (1.0 + m.get("upkeep", 0.0))
		if def.category == "production":
			_produce(w, b, def, v, dt)
		elif b.has("tier"):
			inc += _live(w, b, v, dt, tier_pop)

	w.income = inc
	for c in w.caravans:
		upk += float(Content.CARAVAN[c.type].upkeep)
	w.upkeep = upk
	w.shells += (w.income - w.upkeep) * dt / 60.0


## Beauty and noise around every house (decorations, the Valley Heart, tanneries, kilns …).
static func _surroundings(w: World) -> void:
	var sources := []
	for b in w.buildings.values():
		if b.owner != World.PLAYER:
			continue
		var def: Dictionary = Content.BUILDING[b.type]
		if def.has("beauty") or def.has("noise"):
			sources.append([b, def])
	for h in w.buildings.values():
		if not h.has("tier") or h.owner != World.PLAYER:
			continue
		var beauty := 0.0
		var noise := 0.0
		var hc := _center(h)
		for s in sources:
			var b: Dictionary = s[0]
			if b.valley != h.valley:
				continue
			var d := hc.distance_to(_center(b))
			if s[1].has("beauty") and d <= float(s[1].beauty.radius):
				beauty += float(s[1].beauty.value)
			if s[1].has("noise") and d <= float(s[1].noise.radius):
				noise += float(s[1].noise.value)
		h.beauty = minf(15.0, beauty)
		h.noise = minf(15.0, noise)


## Production groups that are affected by a flood (they stand by the water).
static func _flooded(w: World, b: Dictionary) -> bool:
	for e in w.events:
		if e.kind == "flood" and e.state == "active" and e.valley == b.valley and b.get("riverside", false):
			return true
	return false


static func _produce(w: World, b: Dictionary, def: Dictionary, v: Dictionary, dt: float) -> void:
	if b.paused:
		b.status = "paused"
		b.productivity = 0.0
		return
	if not b.connected:
		b.status = "noRoad"
		b.productivity = 0.0
		return
	if b.get("burning", false):
		b.status = "fire"
		b.productivity = 0.0
		return
	if _flooded(w, b):
		b.status = "flood"
		b.productivity = 0.0
		return
	var m: Dictionary = v.get("mods", {})
	var wf: Dictionary = v.workforce[def.workforce.tier]
	var wf_ratio := 1.0 if wf.need <= 0 else minf(1.0, wf.have / wf.need)
	var nat_factor := 1.0
	var req: Dictionary = def.get("requires", {})
	if req.has("nature"):
		if b.nature < 0 or (w.tick + b.id) % 20 == 0:
			var kind := World.N_TREE if req.nature.kind == "tree" else World.N_BUSH
			b.nature = minf(1.0, float(w.nature_around(b, kind, int(req.nature.radius))) / float(req.nature.min))
		nat_factor = b.nature
	var group: String = def.get("group", "")
	var season_factor: float = SEASON[group][w.season()] if SEASON.has(group) else 1.0
	if group == "hunt" and w.season() == 0 and m.get("spring_hunt", 0.0) < 0.0:
		season_factor = 0.0
	var wild := 1.0
	if group == "hunt":
		wild = clampf(v.game / 0.5, 0.2, 1.0)
	elif group == "fish":
		wild = clampf(v.fish / 0.5, 0.2, 1.0)
	var bonus := maxf(0.1, 1.0 + m.get(group, 0.0) + m.get("all", 0.0))
	var prod := wf_ratio * nat_factor * season_factor * wild * bonus
	b.productivity = prod
	if not b.working:
		var cap := w.storage_cap(b.valley)
		for g in def.get("outputs", {}):
			if v.storage.get(g, 0.0) >= cap:
				b.status = "full"
				return
		if season_factor <= 0.0:
			b.status = "winter"
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
	if wf_ratio < 0.99:
		b.status = "noWorkers"
	elif nat_factor < 0.99:
		b.status = "noNature"
	elif wild < 0.99:
		b.status = "noGame" if group == "hunt" else "noFish"
	elif season_factor <= 0.0:
		b.status = "winter"
	elif season_factor < 1.0:
		b.status = "season"
	else:
		b.status = "ok"
	b.progress += dt * prod / float(def.cycle)
	if b.progress >= 1.0:
		var cap := w.storage_cap(b.valley)
		for g in def.get("outputs", {}):
			var n: float = def.outputs[g]
			v.storage[g] = minf(cap, v.storage.get(g, 0.0) + n)
			w.stats.produced[g] = w.stats.produced.get(g, 0.0) + n
		var size_k: float = float(Content.valley_def(v.def).get("size", 1.0))
		if group == "hunt":
			v.game = maxf(0.0, v.game - Life.GAME_USE / size_k)
		elif group == "fish":
			v.fish = maxf(0.0, v.fish - Life.FISH_USE / size_k)
		elif group == "wood":
			b.cut = b.get("cut", 0) + 1
			if b.cut >= Life.WOOD_PER_TREE:
				b.cut = 0
				Life.cut_tree(w, b)
		b.working = false
		b.progress = 0.0


## Is a need already part of the tier's wishes? New wishes appear at population marks (Anno-style).
static func need_active(need: Dictionary, tier_pop: Dictionary, tier: String) -> bool:
	return int(tier_pop.get(tier, 0)) >= int(need.get("at", 0))


## Consumes goods for a house, updates satisfaction, mood and residents; returns income per minute.
static func _live(w: World, b: Dictionary, v: Dictionary, dt: float, tier_pop: Dictionary) -> float:
	var tier: Dictionary = Content.TIER[b.tier]
	var covered: Dictionary = w.coverage.get(b.id, {})
	var m: Dictionary = v.get("mods", {})
	var target := float(tier.baseResidents)
	var res: float = b.residents
	var inc := 0.0
	var lux := 0.0
	var lux_n := 0
	var hungry := false
	var basic_ok := true
	for need in tier.needs:
		if not need_active(need, tier_pop, b.tier):
			continue
		var ratio := 0.0
		if need.kind == "service" or need.kind == "service-luxury":
			ratio = 1.0 if b.connected and covered.has(need.id) else 0.0
		elif b.connected and Content.GOOD.has(need.id):
			var demand: float = res * float(need.get("consumption", 0.0)) * (1.0 + m.get("food_use", 0.0)) * dt / 60.0
			var have: float = v.storage.get(need.id, 0.0)
			var take := minf(have, demand)
			v.storage[need.id] = have - take
			ratio = take / demand if demand > 0.0 else (1.0 if have > 0.0 else 0.0)
		var prev: float = b.needs.get(need.id, 0.0)
		var sat := prev + (ratio - prev) * 0.02 # smoothed over ~5 s
		b.needs[need.id] = sat
		if need.has("residents"):
			target += float(need.residents) * clampf((sat - 0.2) / 0.7, 0.0, 1.0)
		if need.kind == "basic" or need.kind == "service":
			if sat < READY_NEEDS:
				basic_ok = false
			if need.kind == "basic" and sat < 0.5:
				hungry = true
				v.food_short = need.id
		else:
			lux += sat
			lux_n += 1
		inc += float(need.income) * res * sat
	b.target = target
	b.hungry = hungry
	# mood: luxuries, beauty, festivals and treasures lift it; hunger, cold, noise, sickness and wolves press it down
	var mood: float = 50.0 + (30.0 * lux / lux_n if lux_n > 0 else 0.0) + b.get("beauty", 0.0) - b.get("noise", 0.0) + m.get("mood", 0.0)
	if hungry:
		mood -= 20.0
	if v.get("freezing", false):
		mood -= 20.0 * maxf(0.0, 1.0 + m.get("freeze", 0.0))
	b.mood = clampf(b.mood + (clampf(mood, 0.0, 100.0) - b.mood) * 0.01, 0.0, 100.0)
	# people move out of houses that cannot hold them, or when they are deeply unhappy
	if b.grace > 0.0:
		b.grace -= dt
	elif res > target + 0.01 or b.mood < 15.0:
		var lost := minf(res - 1.0, dt / LEAVE_TIME)
		if lost > 0.0:
			b.residents = res - lost
			w.stats.lost += lost
	var nt = Content.next_tier(b.tier)
	b.ready = nt != null and w.tier_unlocked(nt.id) and basic_ok and b.mood >= 30.0 and b.residents >= target - 0.6
	var mood_k := 0.5 if b.mood < 30.0 else (1.25 if b.mood > 70.0 else 1.0)
	return inc * mood_k * (1.0 + m.get("income", 0.0))


## Production and consumption per minute for every good (Anno's balance view).
static func good_balance(w: World, only_valley := -1) -> Dictionary:
	var out := {}
	var pop := w.player_population()
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
				if need.has("consumption") and need_active(need, pop, b.tier):
					_add(out, need.id, "cons", b.residents * float(need.consumption))
	return out


static func _add(out: Dictionary, g: String, k: String, n: float) -> void:
	if not out.has(g):
		out[g] = {"prod": 0.0, "cons": 0.0}
	out[g][k] += n
