class_name Logistics
## Everything between valleys: scouts, porter routes, the wandering trader and rival tribes.

const EXPEDITION_COST := {"shells": 150, "meat": 5}
const EXPEDITION_TIME := 45.0
const ROUTE_COST := 200
const PORTER_CAPACITY := 20.0
const PORTER_SPEED := 2.2 # tiles per second
const GIFT_COST := 150
const RIVAL_PLAN := ["tent", "fireplace", "tent", "woodcutter", "tent", "berrygatherer", "tent", "tent", "hunter", "tent",
	"shaman", "tent", "tent", "fisher", "tent", "claypit", "tent", "potter", "tent", "tent"]


## BFS over walkable tiles (valley ground and discovered passes) between two storage yards.
static func find_path(w: World, a: int, b: int) -> Array:
	var sa = w.storage_of(a)
	var sb = w.storage_of(b)
	if sa == null or sb == null:
		return []
	var start := w.idx(sa.x + 1, sa.y + 1)
	var goal := w.idx(sb.x + 1, sb.y + 1)
	var prev := PackedInt32Array()
	prev.resize(w.size * w.size)
	prev.fill(-1)
	prev[start] = start
	var q: Array[int] = [start]
	var head := 0
	while head < q.size():
		var i: int = q[head]
		head += 1
		if i == goal:
			break
		var x := i % w.size
		var y := i / w.size
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if not w.inside(nx, ny):
				continue
			var j := w.idx(nx, ny)
			if prev[j] != -1:
				continue
			var t := w.terrain[j]
			if t == World.GRASS or (t == World.PASS and w.passes[w.pass_of[j]].discovered):
				prev[j] = i
				q.append(j)
	if prev[goal] == -1:
		return []
	var path := []
	var i := goal
	while i != start:
		path.append(i)
		i = prev[i]
	path.append(start)
	path.reverse()
	return path


static func tick(w: World) -> void:
	var dt := World.TICK
	_scouts(w, dt)
	for r in w.routes:
		_move_route(w, r, dt)
	_trader(w, dt)
	for r in w.rivals:
		r.build_timer -= dt
		if r.build_timer > 0.0:
			continue
		r.build_timer = 18.0 + w.rng.randf() * 14.0
		_rival_build(w, r.id, r.valley)
		var n := 0
		for b in w.buildings.values():
			if b.owner == r.id and b.has("tier"):
				n += 1
		r.population = n * 7


static func _scouts(w: World, dt: float) -> void:
	var ex = w.expedition
	if ex == null:
		return
	ex.time_left -= dt
	if ex.time_left > 0.0:
		return
	w.expedition = null
	var p: Dictionary = w.passes[ex.pass]
	p.discovered = true
	var other: int = p.b if p.a == ex.from else p.a
	var v: Dictionary = w.valleys[other]
	var was_new: bool = not v.discovered
	v.discovered = true
	w.dirty += 1
	var name: Dictionary = Content.valley_def(v.def).name
	w.notify({"de": "Die Kundschafter sind zurück: Der Pfad führt nach %s." % name.de, "en": "The scouts have returned: the path leads to %s." % name.en}, "good")
	if was_new and v.owner != null and v.owner != World.PLAYER:
		for r in w.rivals:
			if r.id == v.owner and not r.contacted:
				r.contacted = true
				var def: Dictionary = Content.RIVAL[r.id]
				w.notify({"de": "%s: „%s“" % [def.name.de, def.greeting.de], "en": "%s: \"%s\"" % [def.name.en, def.greeting.en]}, "warn")


static func _move_route(w: World, r: Dictionary, dt: float) -> void:
	if r.path.size() < 2:
		r.path = find_path(w, r.a, r.b)
		r.pos = 0.0
		r.dir = 1
		if r.path.size() < 2:
			return
	if r.wait > 0.0:
		r.wait -= dt
		return
	r.pos += r.dir * PORTER_SPEED * dt
	var last: float = r.path.size() - 1
	if r.dir == 1 and r.pos >= last:
		r.pos = last
		_arrive(w, r, r.b, r.cargo_ba)
		r.dir = -1
	elif r.dir == -1 and r.pos <= 0.0:
		r.pos = 0.0
		_arrive(w, r, r.a, r.cargo_ab)
		r.dir = 1


## Unload everything carried, then load the goods meant for the way back.
static func _arrive(w: World, r: Dictionary, v: int, to_load: Array) -> void:
	var st: Dictionary = w.valleys[v].storage
	var cap := w.storage_cap(v)
	for g in r.load.keys():
		var room := maxf(0.0, cap - st.get(g, 0.0))
		var put := minf(room, r.load[g])
		st[g] = st.get(g, 0.0) + put
		r.load[g] -= put
		if r.load[g] <= 0.001:
			r.load.erase(g)
	if not to_load.is_empty():
		var per := PORTER_CAPACITY / to_load.size()
		for g in to_load:
			var take := minf(per - r.load.get(g, 0.0), floorf(st.get(g, 0.0)))
			if take <= 0.0:
				continue
			st[g] -= take
			r.load[g] = r.load.get(g, 0.0) + take
	r.wait = 3.0


static func _trader(w: World, dt: float) -> void:
	var tr := w.trader
	tr.timer -= dt
	if tr.timer > 0.0:
		return
	tr.present = not tr.present
	if tr.present:
		tr.timer = 150.0
		tr.prices = {}
		var pool := []
		for g in Content.goods:
			if tradeable(w, g.id):
				pool.append(g)
		for i in 7:
			if pool.is_empty():
				break
			var g: Dictionary = pool.pop_at(w.rng.randi_range(0, pool.size() - 1))
			tr.prices[g.id] = snappedf(float(g.value) * (0.85 + w.rng.randf() * 0.3), 0.1)
		w.notify({"de": "Ein Händler vom Fluss ist an deinem Lagerplatz eingetroffen.", "en": "A river trader has arrived at your storage yard."}, "info")
	else:
		tr.timer = 210.0
		w.notify({"de": "Der Händler zieht weiter.", "en": "The trader moves on."}, "info")


## Goods the trader deals in: anything produced or needed by an unlocked tier.
static func tradeable(w: World, good: String) -> bool:
	for t in Content.tiers:
		if w.tier_unlocked(t.id):
			for n in t.needs:
				if n.id == good:
					return true
	for b in Content.buildings:
		if w.tier_unlocked(b.unlockTier) and b.has("outputs") and b.outputs.has(good):
			return true
	return false


static func buy_price(w: World, good: String) -> int:
	return ceili(float(w.trader.prices.get(good, Content.GOOD[good].value)) * 1.4)


static func sell_price(w: World, good: String) -> int:
	return floori(float(w.trader.prices.get(good, Content.GOOD[good].value)) * 0.75)


static func rival_buy_price(good: String, relation: float) -> int:
	return ceili(float(Content.GOOD[good].value) * (1.6 - relation / 200.0))


static func rival_sell_price(good: String, relation: float) -> int:
	return floori(float(Content.GOOD[good].value) * (0.7 + relation / 250.0))


## Rivals grow visibly: they follow a simple plan and lay a path to each new building.
static func _rival_build(w: World, owner: String, v: int) -> void:
	var mine := []
	var st = null
	for b in w.buildings.values():
		if b.owner == owner:
			mine.append(b)
			if b.type == "storage":
				st = b
	var step := mine.size() - 1
	if st == null or step >= RIVAL_PLAN.size() * 2:
		return
	var type: String = RIVAL_PLAN[step] if step < RIVAL_PLAN.size() else "tent"
	var def: Dictionary = Content.BUILDING[type]
	var vd: Dictionary = w.valleys[v]
	var ang := w.rng.randf() * TAU
	var dist := 5.0 + minf(10.0, step * 0.7) * w.rng.randf()
	var spot := w.find_free_spot(v, int(def.size[0]) + 1, int(def.size[1]) + 1, vd.cx + cos(ang) * dist, vd.cy + sin(ang) * dist)
	if spot == Vector2i(-1, -1):
		return
	var b := w.place_building(type, spot.x, spot.y, owner)
	if def.category == "residence":
		# rivals advance through the tiers along with the player, a little behind
		var ti := clampi(step / 12, 0, w.unlocked_tiers.size() - 1)
		var tier: Dictionary = Content.tiers[ti]
		b.type = tier.house
		b.tier = tier.id
		b.residents = float(tier.baseResidents) + 4.0
	var x: int = spot.x + int(def.size[0])
	var y: int = spot.y
	var tx: int = st.x + 1
	var ty: int = st.y + 1
	for i in 30:
		if x == tx and y == ty:
			break
		if w.inside(x, y):
			var t := w.idx(x, y)
			if w.terrain[t] == World.GRASS and w.bmap[t] == 0 and w.valley[t] == v:
				w.road[t] = 1
		if absi(tx - x) > absi(ty - y):
			x += signi(tx - x)
		else:
			y += signi(ty - y)
	w.dirty += 1
