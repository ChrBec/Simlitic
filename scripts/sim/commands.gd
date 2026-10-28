class_name Commands
## Every player action is a command dictionary. The UI never mutates the world directly; this keeps the
## simulation deterministic and lets lockstep multiplayer replay the same command stream on every peer.
##
## {type: "build", building, x, y} | {type: "path", tiles: [Vector2i]} | {type: "demolish", x, y}
## {type: "pause", id, paused} | {type: "allow_upgrade", tier, allowed} | {type: "explore", pass, from}
## {type: "create_route", a, b} | {type: "route_cargo", id, dir: "ab"|"ba", goods} | {type: "delete_route", id}
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
		"allow_upgrade":
			w.upgrade_allowed[c.tier] = c.allowed
			return {"ok": true}
		"explore":
			return _explore(w, c)
		"create_route":
			if c.a == c.b:
				return _fail("Zwei verschiedene Täler wählen", "Choose two different valleys")
			if w.valleys[c.a].owner != World.PLAYER or w.valleys[c.b].owner != World.PLAYER:
				return _fail("Beide Täler müssen dir gehören", "Both valleys must be yours")
			if w.shells < Logistics.ROUTE_COST:
				return _fail("Nicht genug Muscheln", "Not enough shells")
			var path := Logistics.find_path(w, c.a, c.b)
			if path.size() < 2:
				return _fail("Kein bekannter Weg zwischen den Tälern", "No known path between the valleys")
			w.shells -= Logistics.ROUTE_COST
			w.routes.append({"id": w.next_id, "a": c.a, "b": c.b, "cargo_ab": [], "cargo_ba": [], "path": path, "pos": 0.0, "dir": 1, "load": {}, "wait": 2.0})
			w.next_id += 1
			return {"ok": true}
		"route_cargo":
			for r in w.routes:
				if r.id == c.id:
					var goods := []
					for g in c.goods:
						if Content.GOOD.has(g) and goods.size() < 4:
							goods.append(g)
					r["cargo_" + c.dir] = goods
					return {"ok": true}
			return _fail("Unbekannte Route", "Unknown route")
		"delete_route":
			w.routes = w.routes.filter(func(r): return r.id != c.id)
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


static func _build(w: World, c: Dictionary) -> Dictionary:
	var check := w.check_placement(c.building, c.x, c.y)
	if not check.ok:
		return check
	var def: Dictionary = Content.BUILDING[c.building]
	var from: Dictionary = w.valleys[check.pay_from]
	w.pay(def.cost, from.storage)
	var founding: bool = c.building == "storage" and w.valleys[check.valley].owner != World.PLAYER
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
