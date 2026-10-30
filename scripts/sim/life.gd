class_name Life
## The living valley: immigration, seasons, firewood, spoilage, wildlife, regrowing forests,
## festivals, spirits, customs, treasures and prestige.

const IMMIGRATION := 1.0 / 12.0 # people per second and valley at a medium mood
const FIREWOOD := 0.03 # wood per resident and minute in winter
const GAME_USE := 0.006 # wildlife lost per unit of meat or hides
const FISH_USE := 0.008
const REGROW := 0.045 / 60.0 # wildlife recovery per second, scaled by what is missing
const WOOD_PER_TREE := 5
const TREE_YEARS := 2.0
const CUSTOM_COST := 15
## Share of a good that spoils per season (winter: a third of it).
const SPOIL := {
	"berries": 0.30, "meat": 0.25, "fish": 0.30, "milk": 0.50, "porridge": 0.20, "bread": 0.20,
	"nuts": 0.05, "wildgrain": 0.05, "emmer": 0.05, "barley": 0.05, "flour": 0.05, "cheese": 0.08,
}


## All modifiers acting on a valley: its treasures, the tribe's customs and spirit, its festival and events.
static func mods(w: World, v_idx: int) -> Dictionary:
	var m := {}
	var v: Dictionary = w.valleys[v_idx]
	for id in v.get("niches", []):
		if id != "" and Content.ITEM.has(id):
			_add(m, Content.ITEM[id].effect)
	for id in w.customs:
		_add(m, Content.CUSTOM[id].effect)
	if w.spirit != null:
		_add(m, Content.SPIRIT[w.spirit.id].effect)
	if v.get("festival") != null:
		_add(m, Content.FESTIVAL[v.festival.id].effect)
	for e in w.events:
		if e.valley == v_idx and e.state == "active":
			_add(m, Events.effect(e))
	if w.cold != null and w.cold.state == "active":
		_add(m, {"firewood": 1.0})
	return m


static func _add(m: Dictionary, eff: Dictionary) -> void:
	for k in eff:
		m[k] = m.get(k, 0.0) + float(eff[k])


static func tick(w: World) -> void:
	var dt := World.TICK
	for v in w.valleys:
		if v.owner != World.PLAYER:
			continue
		var m: Dictionary = v.get("mods", {})
		_immigrate(w, v, m, dt)
		if w.is_winter():
			_firewood(w, v, m, dt)
		else:
			v.freezing = false
		var spring := 2.0 if w.season() == 0 else 1.0
		v.game = minf(1.0, v.game + REGROW * (1.0 - v.game) * spring * (1.0 + m.get("regrow", 0.0)) * dt)
		v.fish = minf(1.0, v.fish + REGROW * 1.2 * (1.0 - v.fish) * dt)
		if v.festival != null and w.time >= v.festival.until:
			v.festival = null
	if w.tick % 10 == 0:
		for v in w.valleys:
			if v.owner == World.PLAYER:
				_spoil(w, v, v.get("mods", {}), dt * 10.0)
				_valley_mood(w, v)
		_prestige(w, dt * 10.0)
	if w.tick % 50 == 0:
		_regrow_forest(w)
	if w.spirit != null and w.time >= w.spirit.until:
		w.notify({"de": "Der Segen des %s ist verklungen. Zur nächsten Wintersonnwende kannst du neu wählen." % Content.SPIRIT[w.spirit.id].name.de,
			"en": "The blessing of the %s has faded. Choose again at the next winter solstice." % Content.SPIRIT[w.spirit.id].name.en}, "info")
		w.spirit = null


## Newcomers arrive one by one – faster when people are happy and in spring, not at all when they are unhappy.
static func _immigrate(w: World, v: Dictionary, m: Dictionary, dt: float) -> void:
	var mood: float = v.mood
	var k := 0.0
	if mood >= 70.0:
		k = 1.5
	elif mood >= 30.0:
		k = lerpf(0.6, 1.0, (mood - 30.0) / 40.0)
	var rate := IMMIGRATION * float(w.diff.imm) * k * maxf(0.0, 1.0 + m.get("imm", 0.0)) * (1.2 if w.season() == 0 else 1.0)
	v.imm = minf(1.5, v.imm + rate * dt)
	if v.imm < 1.0:
		return
	var best = null
	var room := 0.05
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == v.idx and b.has("tier") and b.connected:
			var free: float = b.get("target", 0.0) - b.residents
			if free > room:
				room = free
				best = b
	if best == null:
		return
	var n := minf(1.0, room)
	best.residents += n
	v.imm -= n


## Every resident burns firewood in winter; without it they freeze.
static func _firewood(w: World, v: Dictionary, m: Dictionary, dt: float) -> void:
	var people := 0.0
	for t in v.population:
		people += v.population[t]
	var need: float = people * FIREWOOD * (1.0 + m.get("firewood", 0.0)) * dt / 60.0
	var have: float = v.storage.get("wood", 0.0)
	v.storage.wood = maxf(0.0, have - need)
	v.freezing = need > 0.0 and have < need


## Food spoils over the seasons; storage pits, smokehouses and granaries protect it.
static func _spoil(w: World, v: Dictionary, m: Dictionary, dt: float) -> void:
	var protect := {}
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == v.idx and b.connected:
			for g in Content.BUILDING[b.type].get("store", {}).get("protect", []):
				protect[g] = true
	if v.storage.get("pottery", 0.0) >= 1.0:
		protect.porridge = true
		protect.bread = true
	var k := float(w.diff.spoil) * maxf(0.0, 1.0 + m.get("spoil", 0.0)) * (1.0 / 3.0 if w.is_winter() else 1.0)
	var rates := {}
	for g in SPOIL:
		var have: float = v.storage.get(g, 0.0)
		if have <= 0.0:
			continue
		var share: float = SPOIL[g] * k * (0.5 if protect.has(g) else 1.0)
		var lost := have * share * dt / World.SEASON_LENGTH
		v.storage[g] = have - lost
		rates[g] = lost * 60.0 / dt
	v.spoil = rates


static func _valley_mood(w: World, v: Dictionary) -> void:
	var sum := 0.0
	var n := 0.0
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == v.idx and b.has("tier"):
			sum += b.mood * b.residents
			n += b.residents
	v.mood = sum / n if n > 0.0 else 50.0


## Happy people spread the tribe's fame.
static func _prestige(w: World, dt: float) -> void:
	var happy := 0.0
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.has("tier") and b.mood > 70.0:
			happy += b.residents
	w.prestige_pts += happy * 0.006 * dt / 60.0


## A woodcutter fells one tree in its reach; a stump remains and grows back after about two years.
static func cut_tree(w: World, b: Dictionary) -> void:
	var def: Dictionary = Content.BUILDING[b.type]
	var r := int(def.get("requires", {}).get("nature", {}).get("radius", 4))
	var s: Array = def.size
	var cands := []
	for yy in range(b.y - r, b.y + int(s[1]) + r):
		for xx in range(b.x - r, b.x + int(s[0]) + r):
			if w.inside(xx, yy):
				var i := w.idx(xx, yy)
				if w.nature[i] == World.N_TREE and w.bmap[i] == 0 and not w.road[i]:
					cands.append(i)
	if cands.is_empty():
		return
	var i: int = cands[w.rng.randi_range(0, cands.size() - 1)]
	w.nature[i] = World.N_STUMP
	w.regrow[i] = w.time + World.YEAR * (TREE_YEARS * (0.8 + w.rng.randf() * 0.4))
	w.touched.append(i)
	w.dirty += 1


static func _regrow_forest(w: World) -> void:
	var back := []
	for i in w.regrow:
		if w.time >= w.regrow[i]:
			back.append(i)
	for i in back:
		w.regrow.erase(i)
		if w.nature[i] == World.N_STUMP and w.bmap[i] == 0 and not w.road[i]:
			w.nature[i] = World.N_TREE
			w.touched.append(i)
	if not back.is_empty():
		w.dirty += 1


## Called on the first tick of every season.
static func season_changed(w: World, s: int) -> void:
	match s:
		World.WINTER:
			w.notify({"de": "Der Winter kommt: Sammler und Felder ruhen, jedes Haus verbrennt Holz, Gletscherpässe sind gesperrt.", "en": "Winter arrives: gatherers and fields rest, every home burns wood, glacier passes close."}, "warn")
			if w.cold != null and w.cold.state == "pending":
				w.cold.state = "active"
				w.cold.pop = w.total_population()
				Story.say(w, "ilun" if Story.here(w, "ilun") else "ama", {"de": "Die Große Kälte ist da. Haltet die Feuer am Brennen – jedes Haus braucht jetzt doppelt so viel Holz!", "en": "The Great Cold is here. Keep the fires burning – every home now needs twice the wood!"}, "warn")
		0:
			w.notify({"de": "Frühling! Das Wild bekommt Junge, Gletscherpässe tauen auf, Neugeborene lassen das Dorf wachsen.", "en": "Spring! The game has young, glacier passes thaw, newborns make the village grow."}, "info")
			if w.cold != null and w.cold.state == "active":
				if w.total_population() >= int(w.cold.pop * 0.8):
					w.flags.cold_survived = true
					w.cold = null
					Story.say(w, "ama", {"de": "Wir haben die Große Kälte überstanden. Die Ahnen sind stolz auf uns.", "en": "We survived the Great Cold. The ancestors are proud of us."}, "good")
				else:
					w.cold.state = "pending"
					Story.say(w, "ama", {"de": "Zu viele sind gegangen. Nächsten Winter kommt die Kälte wieder – sammelt mehr Holz!", "en": "Too many have left. Next winter the cold returns – gather more wood!"}, "warn")
		2:
			if w.total_population() > 0:
				Story.say(w, "sela" if Story.here(w, "sela") else "ama", {"de": "Der Herbst ist da – jetzt tragen Sträucher und Halme am meisten. Füllt die Vorräte, bevor der Schnee kommt!", "en": "Autumn is here – bushes and stalks bear the most now. Fill the stores before the snow!"}, "info")
	Story.on_season(w, s)


# ---------------------------------------------------------------- festivals, spirits, customs, treasures

## Why a festival cannot be held right now ("" if it can).
static func festival_block(w: World, v_idx: int, fid: String) -> Dictionary:
	var f: Dictionary = Content.FESTIVAL[fid]
	var v: Dictionary = w.valleys[v_idx]
	if not fid in w.festivals_unlocked:
		return {"de": "Dieses Fest kennt dein Stamm noch nicht", "en": "Your tribe doesn't know this feast yet"}
	if w.hearth_of(v_idx) == null:
		return {"de": "Feste brauchen ein Talherz", "en": "Festivals need a Valley Heart"}
	if v.festival != null:
		return {"de": "Es wird schon gefeiert", "en": "A festival is already under way"}
	if int(f.season) >= 0 and w.season() != int(f.season):
		return {"de": "Nur im %s" % ["Frühling", "Sommer", "Herbst", "Winter"][int(f.season)], "en": "Only in %s" % ["spring", "summer", "autumn", "winter"][int(f.season)]}
	var last: float = v.fest_last.get(fid, -1e9)
	if w.time - last < World.YEAR:
		return {"de": "Erst wieder in %d s" % ceili(World.YEAR - (w.time - last)), "en": "Again in %d s" % ceili(World.YEAR - (w.time - last))}
	if not w.can_afford(festival_cost(w, v_idx, fid), v.storage):
		return {"de": "Nicht genug Vorräte", "en": "Not enough supplies"}
	return {}


static func festival_cost(w: World, v_idx: int, fid: String) -> Dictionary:
	var k := maxf(0.2, 1.0 + w.valleys[v_idx].get("mods", {}).get("fest_cost", 0.0))
	var out := {}
	var cost: Dictionary = Content.FESTIVAL[fid].cost
	for g in cost:
		out[g] = ceilf(float(cost[g]) * k)
	return out


static func hold_festival(w: World, v_idx: int, fid: String) -> void:
	var f: Dictionary = Content.FESTIVAL[fid]
	var v: Dictionary = w.valleys[v_idx]
	w.pay(festival_cost(w, v_idx, fid), v.storage)
	v.festival = {"id": fid, "until": w.time + World.SEASON_LENGTH}
	v.fest_last[fid] = w.time
	w.prestige_pts += float(f.prestige) + v.get("mods", {}).get("fest_prestige", 0.0)
	w.stats.festivals[fid] = w.stats.festivals.get(fid, 0) + 1
	if f.get("spirit", false):
		w.flags.choose_spirit = true
	w.notify({"de": "%s! Das ganze Tal versammelt sich am Talherz." % f.name.de, "en": "%s! The whole valley gathers at the Valley Heart." % f.name.en}, "good")
