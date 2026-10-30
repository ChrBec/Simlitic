class_name Commands
## Every player action is a command dictionary. The UI never mutates the world directly; this keeps the
## simulation deterministic and lets lockstep multiplayer replay the same command stream on every peer.
##
## {type: "build", building, x, y} | {type: "path", tiles: [Vector2i]} | {type: "demolish", x, y}
## {type: "pause", id, paused} | {type: "explore", pass, from}
## {type: "upgrade", id} | {type: "upgrade_all", tier, valley} | {type: "lock_upgrade", id, locked}
## {type: "accept_quest", id} | {type: "quest_choice", id, choice} | {type: "find", id}
## {type: "festival", valley, festival} | {type: "spirit", spirit} | {type: "custom", custom, on}
## {type: "place_item", item, valley, slot} | {type: "remove_item", valley, slot} | {type: "resolve_event", id}
## {type: "clear_pass", pass} | {type: "plank_pass", pass}
## {type: "buy_caravan", valley, caravan} | {type: "caravan_stops", id, stops: [{v, load, unload}]} | {type: "delete_caravan", id}
## {type: "trade", partner: "trader"|rival id, good, amount (>0 buy, <0 sell)} | {type: "gift", rival}


static func _fail(de: String, en: String) -> Dictionary:
	return {"ok": false, "reason": {"de": de, "en": en}}


static func apply(w: World, c: Dictionary) -> Dictionary:
	match c.type:
		"build":
			return _build(w, c)
		"path":
			var built := 0
			var cost: float = Content.BUILDING.path.cost.shells
			for p in c.tiles:
				if not w.inside(p.x, p.y):
					continue
				var i := w.idx(p.x, p.y)
				if w.terrain[i] != World.GRASS or w.bmap[i] != 0 or w.road[i] or w.valley[i] < 0:
					continue
				if w.valleys[w.valley[i]].owner != World.PLAYER:
					continue
				if w.shells < cost:
					break
				w.shells -= cost
				w.road[i] = 1
				w.nature[i] = World.N_NONE
				w.touched.append(i)
				built += 1
			if built == 0:
				return _fail("Hier kann kein Pfad entstehen", "No path can be laid here")
			w.dirty += 1
			return {"ok": true}
		"demolish":
			return _demolish(w, c.x, c.y)
		"pause":
			if not w.buildings.has(c.id) or w.buildings[c.id].owner != World.PLAYER:
				return _fail("Unbekannt", "Unknown")
			w.buildings[c.id].paused = c.paused
			return {"ok": true}
		"upgrade":
			return upgrade(w, int(c.id))
		"upgrade_all":
			var n := 0
			var last := {}
			var ids := w.buildings.keys()
			ids.sort()
			for id in ids:
				var b: Dictionary = w.buildings[id]
				if b.get("tier", "") == c.tier and (int(c.get("valley", -1)) < 0 or b.valley == int(c.valley)) and b.ready and not b.locked:
					last = upgrade(w, id)
					if last.ok:
						n += 1
			if n == 0:
				return last if not last.is_empty() else _fail("Kein Haus ist bereit", "No home is ready")
			return {"ok": true, "count": n}
		"lock_upgrade":
			if not w.buildings.has(c.id) or not w.buildings[c.id].has("tier"):
				return _fail("Unbekannt", "Unknown")
			w.buildings[c.id].locked = c.locked
			return {"ok": true}
		"accept_quest":
			return Story.accept(w, c.id)
		"quest_choice":
			if w.quests.get(c.id, {}).get("state", "") != "choose":
				return _fail("Noch nicht so weit", "Not yet")
			Story.finish(w, c.id, int(c.choice))
			return {"ok": true}
		"find":
			return Story.find(w, c.id)
		"festival":
			var v := int(c.valley)
			if v < 0 or v >= w.valleys.size() or w.valleys[v].owner != World.PLAYER:
				return _fail("Nur in eigenen Tälern", "Only in your own valleys")
			var block := Life.festival_block(w, v, c.festival)
			if not block.is_empty():
				return {"ok": false, "reason": block}
			Life.hold_festival(w, v, c.festival)
			return {"ok": true}
		"spirit":
			if not w.flags.get("choose_spirit", false) or not Content.SPIRIT.has(c.spirit):
				return _fail("Erst zur Wintersonnwende", "Only at the winter solstice")
			w.spirit = {"id": c.spirit, "until": w.time + World.YEAR}
			w.flags.choose_spirit = false
			var sp: Dictionary = Content.SPIRIT[c.spirit]
			w.notify({"de": "Der %s wacht ein Jahr lang über deinen Stamm: %s" % [sp.name.de, sp.desc.de], "en": "The %s watches over your tribe for a year: %s" % [sp.name.en, sp.desc.en]}, "good")
			return {"ok": true}
		"custom":
			return _custom(w, c)
		"place_item":
			var v := int(c.valley)
			var slot := int(c.slot)
			if v < 0 or v >= w.valleys.size() or w.valleys[v].owner != World.PLAYER or w.hearth_of(v) == null:
				return _fail("Kostbarkeiten ruhen im Talherz", "Treasures rest in a Valley Heart")
			if slot < 0 or slot >= World.NICHES or not c.item in w.items:
				return _fail("Unbekannt", "Unknown")
			var niches: Array = w.valleys[v].niches
			if niches[slot] != "":
				w.items.append(niches[slot])
			niches[slot] = c.item
			w.items.erase(c.item)
			return {"ok": true}
		"remove_item":
			var v := int(c.valley)
			var niches: Array = w.valleys[v].niches
			if niches[int(c.slot)] == "":
				return _fail("Die Nische ist leer", "The niche is empty")
			w.items.append(niches[int(c.slot)])
			niches[int(c.slot)] = ""
			return {"ok": true}
		"resolve_event":
			return Events.resolve(w, int(c.id))
		"explore":
			return _explore(w, c)
		"clear_pass", "plank_pass":
			return _pass_project(w, c)
		"buy_caravan":
			return _buy_caravan(w, c)
		"caravan_stops":
			var car = w.caravan(c.id)
			if car == null:
				return _fail("Unbekannte Karawane", "Unknown caravan")
			var stops := []
			for st in c.stops:
				var v := int(st.v)
				if v < 0 or v >= w.valleys.size() or w.valleys[v].owner != World.PLAYER:
					return _fail("Halte nur in eigenen Tälern", "Stops must be your own valleys")
				var load := []
				var unload := []
				for g in st.get("load", []):
					if Content.GOOD.has(g) and not g in load and load.size() < int(Content.CARAVAN[car.type].slots):
						load.append(g)
				for g in st.get("unload", []):
					if Content.GOOD.has(g) and not g in unload:
						unload.append(g)
				stops.append({"v": v, "load": load, "unload": unload})
			if stops.size() > 6:
				return _fail("Höchstens 6 Halte", "At most 6 stops")
			car.stops = stops
			car.leg = 0 if stops.is_empty() else clampi(car.leg, 0, stops.size() - 1)
			car.path = []
			return {"ok": true}
		"delete_caravan":
			var car = w.caravan(c.id)
			if car == null:
				return _fail("Unbekannte Karawane", "Unknown caravan")
			w.caravans.erase(car)
			return {"ok": true}
		"trade":
			return _trade(w, c)
		"gift":
			for r in w.rivals:
				if r.id == c.rival and r.contacted:
					if w.shells < Logistics.GIFT_COST:
						return _fail("Nicht genug Muscheln", "Not enough shells")
					w.shells -= Logistics.GIFT_COST
					r.relation = minf(100.0, r.relation + 8.0)
					return {"ok": true}
			return _fail("Kein Kontakt", "No contact")
	return _fail("Unbekannter Befehl", "Unknown command")


## Upgrades one home to the next age: its residents must be content and the materials in storage.
static func upgrade(w: World, id: int) -> Dictionary:
	if not w.buildings.has(id):
		return _fail("Unbekannt", "Unknown")
	var b: Dictionary = w.buildings[id]
	if b.owner != World.PLAYER or not b.has("tier"):
		return _fail("Kein Wohnhaus", "Not a home")
	var nt = Content.next_tier(b.tier)
	if nt == null:
		return _fail("Höchste Stufe erreicht", "Highest age reached")
	if not w.tier_unlocked(nt.id):
		return _fail("%s sind noch nicht freigeschaltet – Ama kennt den Weg" % nt.name.de, "%s are not unlocked yet – Ama knows the way" % nt.name.en)
	if b.locked:
		return _fail("Aufwertung für dieses Haus gesperrt", "Upgrading is locked for this home")
	if not b.ready:
		return _fail("Die Bewohner sind noch nicht so weit (Grundbedürfnisse ≥ 70 %, Stimmung ≥ 30, Haus voll)", "The residents aren't ready yet (basic needs ≥ 70%, mood ≥ 30, home full)")
	var st: Dictionary = w.valleys[b.valley].storage
	if not w.can_afford(nt.upgradeCost, st):
		return _fail("Es fehlt Baumaterial im Lager", "Building materials are missing in storage")
	w.pay(nt.upgradeCost, st)
	var keep := {}
	for n in nt.needs:
		if b.needs.has(n.id):
			keep[n.id] = b.needs[n.id]
	b.type = nt.house
	b.tier = nt.id
	b.needs = keep
	b.grace = 60.0 # nobody moves out while the new wishes are being met
	b.ready = false
	w.stats.upgrades += 1
	w.dirty += 1
	return {"ok": true}


static func _custom(w: World, c: Dictionary) -> Dictionary:
	if not Content.CUSTOM.has(c.custom):
		return _fail("Unbekannt", "Unknown")
	if not c.on:
		w.customs.erase(c.custom)
		return {"ok": true}
	if w.custom_slots <= 0:
		return _fail("Bräuche kennt dein Stamm noch nicht – Ama erzählt davon", "Your tribe has no customs yet – Ama will tell you")
	if c.custom in w.customs:
		return _fail("Schon angenommen", "Already adopted")
	if w.customs.size() >= w.custom_slots:
		return _fail("Alle Plätze für Bräuche sind belegt", "All custom slots are taken")
	if w.prestige_pts < Life.CUSTOM_COST:
		return _fail("Ein Brauch kostet %d Ansehen" % Life.CUSTOM_COST, "A custom costs %d prestige" % Life.CUSTOM_COST)
	w.prestige_pts -= Life.CUSTOM_COST
	w.customs.append(c.custom)
	return {"ok": true}


static func _build(w: World, c: Dictionary) -> Dictionary:
	var check := w.check_placement(c.building, c.x, c.y)
	if not check.ok:
		return check
	var def: Dictionary = Content.BUILDING[c.building]
	var from: Dictionary = w.valleys[check.pay_from]
	w.pay(def.cost, from.storage)
	var founding: bool = c.building == "storage" and w.valleys[check.valley].owner != World.PLAYER
	if founding:
		w.prestige_pts -= w.found_cost()
	w.place_building(c.building, c.x, c.y, World.PLAYER)
	if founding:
		# the founding party carries the building wood across the pass and leaves it as a first stock
		var v: Dictionary = w.valleys[check.valley]
		v.storage.wood = v.storage.get("wood", 0.0) + float(def.cost.get("wood", 0))
		var name: Dictionary = Content.valley_def(v.def).name
		w.notify({"de": "%s ist jetzt Teil deines Stammesgebiets." % name.de, "en": "%s is now part of your tribal land." % name.en}, "good")
	return {"ok": true}


static func _demolish(w: World, x: int, y: int) -> Dictionary:
	if not w.inside(x, y):
		return _fail("Nichts zum Abreißen", "Nothing to demolish")
	var i := w.idx(x, y)
	if w.bmap[i] != 0:
		var b: Dictionary = w.buildings[w.bmap[i]]
		if b.owner != World.PLAYER:
			return _fail("Nicht dein Gebäude", "Not your building")
		if b.type == "storage":
			return _fail("Lagerplätze bleiben bestehen", "Storage yards cannot be removed")
		var st: Dictionary = w.valleys[b.valley].storage
		var cost: Dictionary = Content.BUILDING[b.type].cost
		for g in cost:
			if g == "shells":
				w.shells += floorf(cost[g] * 0.5)
			else:
				st[g] = minf(w.storage_cap(b.valley), st.get(g, 0.0) + floorf(cost[g] * 0.5))
		w.remove_building(b.id)
		return {"ok": true}
	if w.road[i] and w.valley[i] >= 0 and w.valleys[w.valley[i]].owner == World.PLAYER:
		w.road[i] = 0
		w.touched.append(i)
		w.dirty += 1
		return {"ok": true}
	return _fail("Nichts zum Abreißen", "Nothing to demolish")


static func _explore(w: World, c: Dictionary) -> Dictionary:
	if w.expedition != null:
		return _fail("Die Kundschafter sind schon unterwegs", "Scouts are already out")
	if c.pass < 0 or c.pass >= w.passes.size():
		return _fail("Kein Pfad von hier", "No path from here")
	var p: Dictionary = w.passes[c.pass]
	var v: Dictionary = w.valleys[c.from]
	if p.a != c.from and p.b != c.from:
		return _fail("Kein Pfad von hier", "No path from here")
	if p.discovered:
		return _fail("Schon erkundet", "Already explored")
	if v.owner != World.PLAYER:
		return _fail("Nur aus eigenen Tälern", "Only from your own valleys")
	var has_scout := false
	for b in w.buildings.values():
		if b.type == "scout" and b.valley == c.from and b.owner == World.PLAYER:
			has_scout = true
	if not has_scout:
		return _fail("Benötigt ein Kundschafterlager in diesem Tal", "Needs a scout camp in this valley")
	if not w.can_afford(Logistics.EXPEDITION_COST, v.storage):
		return _fail("Benötigt 150 Muscheln und 5 Fleisch als Proviant", "Needs 150 shells and 5 meat as provisions")
	w.pay(Logistics.EXPEDITION_COST, v.storage)
	w.expedition = {"pass": c.pass, "from": c.from, "time_left": Logistics.EXPEDITION_TIME, "total": Logistics.EXPEDITION_TIME}
	w.notify({"de": "Die Kundschafter brechen in die Berge auf.", "en": "The scouts set out into the mountains."}, "info")
	return {"ok": true}


static func _trade(w: World, c: Dictionary) -> Dictionary:
	var home := w.home_valley()
	var st: Dictionary = home.storage
	var qty := absf(c.amount)
	var price := 0
	if c.partner == "trader":
		if not w.trader.present:
			return _fail("Kein Händler da", "No trader present")
		if not w.trader.prices.has(c.good):
			return _fail("Das führt der Händler nicht", "The trader does not deal in this")
		price = Logistics.buy_price(w, c.good) if c.amount > 0 else Logistics.sell_price(w, c.good)
	else:
		var r = null
		for x in w.rivals:
			if x.id == c.partner:
				r = x
		if r == null or not r.contacted:
			return _fail("Kein Kontakt", "No contact")
		var def: Dictionary = Content.RIVAL[c.partner]
		if r.relation < 25.0:
			return _fail("%s verweigert den Handel" % def.name.de, "%s refuses to trade" % def.name.en)
		if c.amount > 0 and not c.good in def.sells:
			return _fail("Wird nicht angeboten", "Not offered")
		if c.amount < 0 and not c.good in def.buys:
			return _fail("Wird nicht gekauft", "Not wanted")
		price = Logistics.rival_buy_price(c.good, r.relation) if c.amount > 0 else Logistics.rival_sell_price(c.good, r.relation)
		r.relation = minf(100.0, r.relation + 0.5)
	if c.amount > 0:
		if w.storage_cap(home.idx) - st.get(c.good, 0.0) < qty:
			return _fail("Kein Platz im Lager", "No room in storage")
		if w.shells < price * qty:
			return _fail("Nicht genug Muscheln", "Not enough shells")
		w.shells -= price * qty
		st[c.good] = st.get(c.good, 0.0) + qty
	else:
		if st.get(c.good, 0.0) < qty:
			return _fail("Nicht genug im Lager", "Not enough in storage")
		st[c.good] -= qty
		w.shells += price * qty
	return {"ok": true}


static func _pass_project(w: World, c: Dictionary) -> Dictionary:
	if c.pass < 0 or c.pass >= w.passes.size():
		return _fail("Unbekannter Pass", "Unknown pass")
	var p: Dictionary = w.passes[c.pass]
	if not p.discovered:
		return _fail("Erst erkunden", "Explore it first")
	if p.project != null:
		return _fail("Daran wird schon gearbeitet", "Work is already under way")
	var from := -1
	for v in [p.a, p.b]:
		if w.valleys[v].owner == World.PLAYER:
			from = v
			break
	if from < 0:
		return _fail("Ein angrenzendes Tal muss dir gehören", "You must own a valley at one end")
	var ob: Dictionary = Content.OBSTACLE[p.obstacle]
	var cost: Dictionary
	var tier: String
	var time: float
	if c.type == "clear_pass":
		if p.cleared:
			return _fail("Der Pass ist schon offen", "The pass is already open")
		cost = ob.cost
		tier = ob.unlockTier
		time = float(ob.time)
	else:
		if not p.cleared:
			return _fail("Erst das Hindernis überwinden", "Overcome the obstacle first")
		if p.plank:
			return _fail("Hier liegt schon ein Bohlenweg", "There already is a plank road")
		if ob.get("no_wagons", false):
			return _fail("Über das Eis kommt kein Wagen", "No cart can cross the ice")
		cost = Logistics.PLANK_COST
		tier = Logistics.PLANK_TIER
		time = Logistics.PLANK_TIME
	if not w.tier_unlocked(tier):
		var tn: Dictionary = Content.TIER[tier].name
		return _fail("Benötigt Stufe " + tn.de, "Requires " + tn.en)
	if not w.can_afford(cost, w.valleys[from].storage):
		return _fail("Nicht genug Rohstoffe im angrenzenden Tal", "Not enough resources in the adjacent valley")
	w.pay(cost, w.valleys[from].storage)
	p.project = {"kind": "plank" if c.type == "plank_pass" else "clear", "left": time, "total": time}
	return {"ok": true}


static func _buy_caravan(w: World, c: Dictionary) -> Dictionary:
	if not Content.CARAVAN.has(c.caravan):
		return _fail("Unbekannt", "Unknown")
	var def: Dictionary = Content.CARAVAN[c.caravan]
	if not w.tier_unlocked(def.unlockTier):
		var tn: Dictionary = Content.TIER[def.unlockTier].name
		return _fail("Benötigt Stufe " + tn.de, "Requires " + tn.en)
	var v := int(c.valley)
	if v < 0 or v >= w.valleys.size() or w.valleys[v].owner != World.PLAYER:
		return _fail("Nur in eigenen Tälern", "Only in your own valleys")
	var has_post := false
	for b in w.buildings.values():
		if b.type == "caravanpost" and b.valley == v and b.owner == World.PLAYER:
			has_post = true
	if not has_post:
		return _fail("Benötigt einen Rastplatz in diesem Tal", "Needs a caravan camp in this valley")
	if not w.can_afford(def.cost, w.valleys[v].storage):
		return _fail("Nicht genug Rohstoffe", "Not enough resources")
	w.pay(def.cost, w.valleys[v].storage)
	w.caravans.append({"id": w.next_id, "type": c.caravan, "at": v, "stops": [], "leg": 0, "path": [], "path_ver": -1,
		"pos": 0.0, "cargo": {}, "wait": 0.0, "status": "idle", "delivered": 0.0})
	w.next_id += 1
	return {"ok": true, "id": w.next_id - 1}
