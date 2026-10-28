class_name Logistics
## Everything between valleys: scouts, pass projects, caravans (the "ships" of the mountains),
## the wandering trader and rival tribes.

const EXPEDITION_COST := {"shells": 150, "meat": 5}
const EXPEDITION_TIME := 45.0
const GIFT_COST := 150
## Upgrading a cleared pass to a plank road lets wheeled carts cross it.
const PLANK_COST := {"shells": 800, "planks": 15, "coppertools": 4}
const PLANK_TIME := 60.0
const PLANK_TIER := "chieftains"
const STOP_WAIT := 4.0
const RIVAL_PLAN := ["tent", "fireplace", "tent", "woodcutter", "tent", "berrygatherer", "tent", "tent", "hunter", "tent",
	"shaman", "tent", "tent", "fisher", "tent", "graingatherer", "tent", "grinder", "tent", "tent", "claypit", "tent", "potter"]


## Can a caravan (or a founding party) use this pass right now?
static func pass_open(w: World, p: Dictionary, wagon := false, ignore_season := false) -> bool:
	if not p.discovered or not p.cleared:
		return false
	var ob: Dictionary = Content.OBSTACLE.get(p.obstacle, {})
	if wagon and (not p.plank or ob.get("no_wagons", false)):
		return false
	if not ignore_season and ob.get("winter_closed", false) and w.is_winter():
		return false
	return true


## Valley-level reachability over usable passes.
static func valley_route(w: World, from: int, to: int, wagon := false, ignore_season := false) -> Array:
	var prev := {from: from}
	var q := [from]
	while not q.is_empty():
		var v: int = q.pop_front()
		if v == to:
			break
		for p in w.passes:
			if p.a != v and p.b != v:
				continue
			var o: int = p.b if p.a == v else p.a
			if prev.has(o) or not pass_open(w, p, wagon, ignore_season):
				continue
			prev[o] = v
			q.append(o)
	if not prev.has(to):
		return []
	var out := [to]
	while out[0] != from:
		out.push_front(prev[out[0]])
	return out


## Tile path between two storage yards over valley ground and usable passes (BFS).
static func find_path(w: World, a: int, b: int, wagon := false) -> Array:
	var sa = w.storage_of(a)
	var sb = w.storage_of(b)
	if sa == null or sb == null:
		return []
	var start := w.idx(sa.x + 1, sa.y + 1)
	var goal := w.idx(sb.x + 1, sb.y + 1)
	var open_pass := []
	for p in w.passes:
		open_pass.append(pass_open(w, p, wagon))
	var prev := PackedInt32Array()
	prev.resize(w.size * w.size)
	prev.fill(-1)
	prev[start] = start
	var q := PackedInt32Array([start])
	var head := 0
	var n := w.size
	while head < q.size():
		var i: int = q[head]
		head += 1
		if i == goal:
			break
		var x := i % n
		for j in [i + 1 if x < n - 1 else -1, i - 1 if x > 0 else -1, i + n, i - n]:
			if j < 0 or j >= n * n or prev[j] != -1:
				continue
			var t := w.terrain[j]
			if t == World.GRASS or (t == World.PASS and open_pass[w.pass_of[j]]):
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
	_projects(w, dt)
	for c in w.caravans:
		_move_caravan(w, c, dt)
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


static func _projects(w: World, dt: float) -> void:
	for p in w.passes:
		if p.project == null:
			continue
		p.project.left -= dt
		if p.project.left > 0.0:
			continue
		var kind: String = p.project.kind
		p.project = null
		if kind == "plank":
			p.plank = true
		else:
			p.cleared = true
		w.pass_ver += 1
		w.dirty += 1
		var na: Dictionary = Content.valley_def(w.valleys[p.a].def).name
		var nb: Dictionary = Content.valley_def(w.valleys[p.b].def).name
		if kind == "plank":
			w.notify({"de": "Der Bohlenweg zwischen %s und %s ist fertig – jetzt rollen Karren." % [na.de, nb.de], "en": "The plank road between %s and %s is done – carts can roll." % [na.en, nb.en]}, "good")
		else:
			w.notify({"de": "Der Pass zwischen %s und %s ist jetzt für Karawanen offen." % [na.de, nb.de], "en": "The pass between %s and %s is now open to caravans." % [na.en, nb.en]}, "good")


# ---------------------------------------------------------------- caravans

static func caravan_def(c: Dictionary) -> Dictionary:
	return Content.CARAVAN[c.type]


static func cargo_total(c: Dictionary) -> float:
	var n := 0.0
	for g in c.cargo:
		n += c.cargo[g]
	return n


static func _move_caravan(w: World, c: Dictionary, dt: float) -> void:
	if c.stops.size() < 2:
		c.status = "idle"
		return
	if c.wait > 0.0:
		c.wait -= dt
		return
	var target: int = c.stops[c.leg].v
	if c.path.size() < 2 or c.path_ver != w.pass_ver:
		var here: int = c.at
		if here == target:
			_arrive(w, c)
			return
		var def := caravan_def(c)
		c.path = find_path(w, here, target, def.get("wagon", false))
		c.path_ver = w.pass_ver
		c.pos = 0.0
		if c.path.size() < 2:
			c.status = "winter" if w.is_winter() and not valley_route(w, here, target, def.get("wagon", false), true).is_empty() else "blocked"
			c.wait = 3.0
			c.path_ver = -1
			return
	c.status = "moving"
	c.pos += float(caravan_def(c).speed) * dt
	if c.pos >= c.path.size() - 1:
		c.at = target
		c.path = []
		_arrive(w, c)


## At a stop: unload what this stop wants, then fill free slots with what it gives.
static func _arrive(w: World, c: Dictionary) -> void:
	var stop: Dictionary = c.stops[c.leg]
	var v: Dictionary = w.valleys[stop.v]
	c.leg = (c.leg + 1) % c.stops.size()
	c.wait = STOP_WAIT
	c.pos = 0.0
	if v.owner != World.PLAYER:
		return
	var st: Dictionary = v.storage
	var cap := w.storage_cap(stop.v)
	for g in stop.unload:
		if not c.cargo.has(g):
			continue
		var put := minf(c.cargo[g], maxf(0.0, cap - st.get(g, 0.0)))
		st[g] = st.get(g, 0.0) + put
		c.cargo[g] -= put
		c.delivered += put
		if c.cargo[g] <= 0.001:
			c.cargo.erase(g)
	var def := caravan_def(c)
	for g in stop.load:
		if not c.cargo.has(g) and c.cargo.size() >= int(def.slots):
			continue
		var take := minf(float(def.capacity) - c.cargo.get(g, 0.0), floorf(st.get(g, 0.0)))
		if take <= 0.0:
			continue
		st[g] -= take
		c.cargo[g] = c.cargo.get(g, 0.0) + take


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
	w.pass_ver += 1
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
				w.touched.append(t)
		if absi(tx - x) > absi(ty - y):
			x += signi(tx - x)
		else:
			y += signi(ty - y)
	w.dirty += 1
