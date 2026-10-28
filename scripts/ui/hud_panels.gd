class_name HudPanels
## Content of the right-hand panels: selected building, population, valleys & routes, trade.

const STATUS := {
	"ok": ["Arbeitet", "Working"], "noRoad": ["Kein Pfad zum Lagerplatz!", "No path to the storage yard!"],
	"noWorkers": ["Zu wenige Arbeitskräfte", "Not enough workers"], "noInput": ["Rohstoffe fehlen", "Missing input goods"],
	"full": ["Lager voll", "Storage full"], "paused": ["Pausiert", "Paused"], "noNature": ["Zu wenig Natur im Umkreis", "Not enough nature nearby"],
	"winter": ["Winterruhe – arbeitet langsam", "Winter rest – working slowly"],
}


static func _status(key: String) -> String:
	var s: Array = STATUS.get(key, [key, key])
	return Content.L(s[0], s[1])


static func _wrap(text: String, variation := "") -> Label:
	var l := UI.label(text, variation, true)
	l.custom_minimum_size.x = 320
	return l


static func _status_box(text: String, ok: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("d7e6b8") if ok else Color("f0c0a8")
	sb.border_color = UI.INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(5)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UI.label(text))
	return p


static func building(h: Hud, b: Dictionary) -> void:
	var w := h.game.world
	var def: Dictionary = Content.BUILDING[b.type]
	var v: Dictionary = w.valleys[b.valley]
	h.add(UI.label(Content.tx(def.name), "Title"))
	var sub := Content.tx(Content.valley_def(v.def).name)
	if b.owner != World.PLAYER:
		sub += " · " + Content.tx(Content.RIVAL[b.owner].name)
	h.add(UI.label(sub, "Muted"))
	if b.owner != World.PLAYER:
		h.add(_wrap(Content.tx(def.desc)))
		return
	var demolish := h.act(Content.L("Abreißen", "Demolish"), func():
		h.game.command({"type": "demolish", "x": b.x, "y": b.y}, "demolish")
		h.open_panel(""))
	if def.category == "production":
		var st: String = b.status if b.connected else "noRoad"
		h.add(_status_box(_status(st), st == "ok"))
		var flow := UI.hbox([])
		for g in def.get("inputs", {}):
			flow.add_child(UI.good_icon(g, 30))
		if def.has("inputs"):
			flow.add_child(UI.label("→"))
		for g in def.outputs:
			flow.add_child(UI.good_icon(g, 30))
		flow.add_child(UI.label("  %.1f/min" % (60.0 / def.cycle), "Muted"))
		h.add(flow)
		h.add(UI.hbox([UI.label(Content.L("Produktivität", "Productivity")), UI.bar(b.productivity, b.productivity < 0.5, 120), UI.label("%d%%" % roundi(b.productivity * 100))]))
		var wf: Dictionary = v.workforce[def.workforce.tier]
		h.add(UI.row(UI.label("%s: %d %s" % [Content.L("Arbeiter", "Workers"), int(def.workforce.amount), Content.tx(Content.TIER[def.workforce.tier].name)]),
			UI.label("%s %d/%d" % [Content.L("Tal", "Valley"), floori(wf.have), wf.need], "Muted")))
		if def.get("requires", {}).has("nature"):
			var kind_text := Content.L("Bäume im Umkreis", "Trees nearby") if def.requires.nature.kind == "tree" else Content.L("Sträucher im Umkreis", "Bushes nearby")
			h.add(UI.row(UI.label(kind_text), UI.label("%d%%" % roundi(maxf(0.0, b.nature) * 100))))
		h.add(UI.row(UI.label(Content.L("Unterhalt", "Upkeep")), UI.label("%d/min" % int(def.upkeep))))
		h.add(UI.hbox([h.act(Content.L("Fortsetzen", "Resume") if b.paused else Content.L("Pausieren", "Pause"), func(): h.game.command({"type": "pause", "id": b.id, "paused": not b.paused})), demolish]))
	elif b.has("tier"):
		var tier: Dictionary = Content.TIER[b.tier]
		h.add(UI.row(UI.label(Content.tx(tier.name), "Heading"), UI.label("%d / %d %s" % [roundi(b.residents), Content.max_residents(b.tier), Content.L("Bewohner", "residents")])))
		if not b.connected:
			h.add(_status_box(_status("noRoad"), false))
		for section in [[Content.L("Grundbedürfnisse", "Basic needs"), ["basic", "service"]], [Content.L("Luxus", "Luxury"), ["luxury", "service-luxury"]]]:
			var needs: Array = tier.needs.filter(func(n): return n.kind in section[1])
			if needs.is_empty():
				continue
			h.add(UI.label(section[0], "Heading"))
			for n in needs:
				var sat: float = b.needs.get(n.id, 0.0)
				var ic: Control = UI.good_icon(n.id, 26) if Content.GOOD.has(n.id) else UI.icon(Art.building_icon(Content.service_ids.get(n.id, "fireplace")), 26)
				var name := Content.need_name(n.id)
				if n.has("residents"):
					name += "  +%d" % int(n.residents)
				var lab := UI.label(name)
				lab.custom_minimum_size.x = 170
				h.add(UI.hbox([ic, lab, UI.bar(sat, sat < 0.5, 100)]))
		var nt = Content.next_tier(b.tier)
		if nt != null:
			h.add(UI.label(Content.L("Aufstieg zu ", "Upgrade to ") + Content.tx(nt.name), "Heading"))
			if not w.tier_unlocked(nt.id):
				h.add(_wrap(Content.L("Freigeschaltet bei %d %s.", "Unlocks at %d %s.") % [int(nt.unlock.population), Content.tx(Content.TIER[nt.unlock.tier].name)], "Muted"))
			var mats := UI.hbox([UI.label(Content.L("Baumaterial:", "Materials:"))])
			for g in nt.upgradeCost:
				mats.add_child(UI.good_icon(g, 24))
				mats.add_child(UI.label(str(int(nt.upgradeCost[g]))))
			h.add(mats)
			h.add(_wrap(Content.L("Steigt automatisch auf, wenn alle Grundbedürfnisse erfüllt sind und das Material im Lager liegt.", "Upgrades automatically once all basic needs are met and the materials are in storage."), "Muted"))
			h.add(_upgrade_toggle(h, b.tier))
		h.add(demolish)
	else:
		h.add(_wrap(Content.tx(def.desc)))
		if def.has("service"):
			var served := 0
			for x in w.buildings.values():
				if x.has("tier") and x.valley == b.valley and x.needs.get(def.service.id, 0.0) > 0.5:
					served += 1
			h.add(UI.row(UI.label(Content.L("Reichweite", "Radius")), UI.label(str(int(def.service.radius)))))
			h.add(UI.row(UI.label(Content.L("Versorgte Häuser", "Homes served")), UI.label(str(served))))
			if not b.connected:
				h.add(_status_box(_status("noRoad"), false))
		if b.type == "storage":
			h.add(UI.row(UI.label(Content.L("Kapazität je Gut", "Capacity per good")), UI.label(str(w.storage_cap(b.valley)))))
		if b.type == "scout":
			h.add(h.act(Content.L("Pfade erkunden …", "Explore paths …"), func(): h.open_panel("valleys")))
		if b.type == "caravanpost":
			h.add(h.act(Content.L("Karawanen …", "Caravans …"), func(): h.open_panel("caravans")))
		if def.upkeep > 0:
			h.add(UI.row(UI.label(Content.L("Unterhalt", "Upkeep")), UI.label("%d/min" % int(def.upkeep))))
		if b.type != "storage":
			h.add(demolish)


static func _upgrade_toggle(h: Hud, tier_id: String) -> CheckBox:
	var c := CheckBox.new()
	c.text = Content.L("Aufstieg erlaubt (%s)", "Upgrades allowed (%s)") % Content.tx(Content.TIER[tier_id].name)
	c.button_pressed = h.game.world.upgrade_allowed[tier_id]
	c.toggled.connect(func(on): h.game.command({"type": "allow_upgrade", "tier": tier_id, "allowed": on}))
	return c


static func population(h: Hud) -> void:
	var w := h.game.world
	var pop := w.player_population()
	var bal := Economy.good_balance(w)
	h.add(UI.label(Content.L("Bevölkerung", "Population"), "Title"))
	h.add(_wrap(Content.L("Vom Sammler zum Bauern – die Neolithische Revolution.", "From gatherer to farmer – the Neolithic Revolution."), "Muted"))
	for t in Content.tiers:
		var unlocked := w.tier_unlocked(t.id)
		var homes := 0
		for b in w.buildings.values():
			if b.owner == World.PLAYER and b.get("tier", "") == t.id:
				homes += 1
		var box := UI.vbox([UI.row(UI.label(Content.tx(t.name), "Heading"), UI.label(Content.tx(t.age), "Muted")),
			UI.row(UI.label("%d %s" % [pop[t.id], Content.L("Bewohner", "residents")]), UI.label("%d %s" % [homes, Content.L("Häuser", "homes")]))])
		if not unlocked and t.unlock != null:
			var have: int = pop[t.unlock.tier]
			box.add_child(UI.hbox([UI.label("%d/%d %s" % [have, int(t.unlock.population), Content.tx(Content.TIER[t.unlock.tier].name)], "Muted"), UI.bar(float(have) / t.unlock.population, false, 120)]))
		if unlocked:
			for n in t.needs:
				if not n.has("consumption"):
					continue
				var bb: Dictionary = bal.get(n.id, {"prod": 0.0, "cons": 0.0})
				var diff: float = bb.prod - bb.cons
				var val := UI.label("%+.1f/min" % diff)
				val.add_theme_color_override("font_color", UI.GOOD if diff >= -0.01 else UI.BAD)
				var name := Content.need_name(n.id) + (Content.L(" (Luxus)", " (luxury)") if n.kind == "luxury" else "")
				box.add_child(UI.row(UI.hbox([UI.good_icon(n.id, 22), UI.label(name)]), val))
			if Content.next_tier(t.id) != null:
				box.add_child(_upgrade_toggle(h, t.id))
		var p := UI.panel([box], "Dark")
		p.modulate.a = 1.0 if unlocked else 0.6
		h.add(p)


static func _vname(w: World, v: int) -> String:
	return Content.tx(Content.valley_def(w.valleys[v].def).name)


static func _cost_row(cost: Dictionary) -> HBoxContainer:
	var row := UI.hbox([], 3)
	for g in cost:
		row.add_child(UI.icon(Art.tex("ui/shell"), 20) if g == "shells" else UI.good_icon(g, 20))
		row.add_child(UI.label(str(int(cost[g])), "Muted"))
	return row


static func valleys(h: Hud) -> void:
	var w := h.game.world
	h.add(UI.label(Content.L("Täler & Pässe", "Valleys & Passes"), "Title"))
	h.add(_wrap(Content.L("Jedes Tal ist wie eine Insel: eigene Fruchtbarkeiten, eigenes Lager, eigene Arbeiter. Kundschafter erkunden jeden Pfad – Karawanen brauchen aber offene Pässe.", "Every valley is like an island: its own fertilities, storage and workers. Scouts explore any path – but caravans need open passes."), "Muted"))
	var ex = w.expedition
	if ex != null:
		h.add(UI.hbox([UI.label(Content.L("Kundschafter unterwegs …", "Scouts on their way …")), UI.bar(1.0 - ex.time_left / ex.total, false, 140)]))
	for v in w.valleys:
		if not v.discovered:
			continue
		var pop := 0.0
		for k in v.population:
			pop += v.population[k]
		var status := ""
		if v.owner == World.PLAYER:
			status = "%s · %d %s" % [Content.L("Dein Tal", "Your valley"), roundi(pop), Content.L("Bewohner", "residents")]
		elif v.owner != null:
			status = Content.tx(Content.RIVAL[v.owner].name)
		else:
			var reach := w.valleys.any(func(o): return o.owner == World.PLAYER and not Logistics.valley_route(w, o.idx, v.idx, false, true).is_empty())
			status = Content.L("Unbesiedelt – baue hier einen Lagerplatz", "Unsettled – build a storage yard here") if reach else Content.L("Unbesiedelt – noch führt kein offener Pass hierher", "Unsettled – no open pass leads here yet")
		var box := UI.vbox([UI.row(UI.label(_vname(w, v.idx), "Heading"), h.act(Content.L("Zeigen", "Show"), func(): h.game.view.center_on(v.cx, v.cy))), _wrap(status, "Muted")])
		var chips := []
		for f in v.fertilities:
			chips.append(Content.tx(Content.FERTILITY[f].name))
		box.add_child(_wrap(", ".join(chips), "Muted"))
		if v.owner == World.PLAYER:
			var has_scout := false
			for b in w.buildings.values():
				if b.type == "scout" and b.valley == v.idx and b.owner == World.PLAYER:
					has_scout = true
			var unexplored := false
			for p in w.passes:
				if p.a != v.idx and p.b != v.idx:
					continue
				var other: int = p.b if p.a == v.idx else p.a
				if not p.discovered:
					unexplored = true
					var target := _vname(w, other) if w.valleys[other].discovered else Content.L("Unbekannter Pfad", "Unknown path")
					box.add_child(UI.row(UI.label("⛰ %s (%d %s)" % [target, p.core.size(), Content.L("Felder", "tiles")]),
						h.act(Content.L("Erkunden", "Explore"), func(): h.game.command({"type": "explore", "pass": p.idx, "from": v.idx}), "Small", not has_scout or ex != null)))
				else:
					box.add_child(_pass_row(h, p, other))
			if unexplored and not has_scout:
				box.add_child(_wrap(Content.L("Baue ein Kundschafterlager, um Pfade zu erkunden (Proviant: 5 Fleisch, 150 Muscheln).", "Build a scout camp to explore paths (provisions: 5 meat, 150 shells)."), "Muted"))
		h.add(UI.panel([box], "Dark"))
	var unknown := w.valleys.filter(func(v): return not v.discovered).size()
	if unknown > 0:
		h.add(_wrap(Content.L("%d Täler liegen noch im Nebel der Berge.", "%d valleys still lie hidden in the mountains.") % unknown, "Muted"))


## One discovered pass: its obstacle, the project that overcomes it, and the plank road upgrade.
static func _pass_row(h: Hud, p: Dictionary, other: int) -> Control:
	var w := h.game.world
	var ob: Dictionary = Content.OBSTACLE[p.obstacle]
	var box := UI.vbox([], 2)
	var state := ""
	if p.obstacle == "none":
		state = Content.L("offener Pfad", "open trail")
	elif p.cleared:
		state = "✓ " + Content.tx(ob.fix)
	else:
		state = "✗ " + Content.tx(ob.name)
	if p.plank:
		state += " · " + Content.L("Bohlenweg", "plank road")
	if p.cleared and not Logistics.pass_open(w, p):
		state += " · " + Content.L("im Winter gesperrt", "closed in winter")
	var head := UI.label("⛰ %s – %s" % [_vname(w, other), state])
	head.tooltip_text = Content.tx(ob.desc)
	head.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(head)
	if p.project != null:
		var what := Content.L("Bohlenweg", "Plank road") if p.project.kind == "plank" else Content.tx(ob.fix)
		box.add_child(UI.hbox([UI.label(what + " …", "Muted"), UI.bar(1.0 - p.project.left / p.project.total, false, 120)]))
	elif not p.cleared:
		var locked := not w.tier_unlocked(ob.unlockTier)
		var btn := h.act(Content.tx(ob.fix), func(): h.game.command({"type": "clear_pass", "pass": p.idx}), "Small", locked)
		btn.tooltip_text = Content.tx(ob.desc)
		box.add_child(UI.hbox([btn, _cost_row(ob.cost)]))
		if locked:
			box.add_child(UI.label(Content.L("ab Stufe ", "from tier ") + Content.tx(Content.TIER[ob.unlockTier].name), "Muted"))
	elif not p.plank and not ob.get("no_wagons", false) and w.tier_unlocked(Logistics.PLANK_TIER):
		var btn := h.act(Content.L("Bohlenweg legen", "Lay plank road"), func(): h.game.command({"type": "plank_pass", "pass": p.idx}))
		btn.tooltip_text = Content.L("Nur auf Bohlenwegen kommen Ochsenkarren über den Pass.", "Ox carts can only cross on plank roads.")
		box.add_child(UI.hbox([btn, _cost_row(Logistics.PLANK_COST)]))
	return box


# ---------------------------------------------------------------- caravans

const CARAVAN_STATUS := {
	"idle": ["Wartet auf eine Route", "Waiting for a route"], "moving": ["Unterwegs", "On the way"],
	"blocked": ["Kein offener Weg!", "No open way!"], "winter": ["Wartet auf das Tauwetter", "Waiting for the thaw"],
}


static func caravans(h: Hud) -> void:
	var w := h.game.world
	h.add(UI.label(Content.L("Karawanen", "Caravans"), "Title"))
	h.add(_wrap(Content.L("Karawanen sind die Schiffe der Berge: Sie ziehen auf einer festen Route von Tal zu Tal, laden an jedem Halt Waren und liefern sie am nächsten ab. Jede Ware belegt einen Platz.", "Caravans are the ships of the mountains: they follow a fixed route from valley to valley, load goods at each stop and deliver them at the next. Each good takes one slot."), "Muted"))
	var own := w.valleys.filter(func(v): return v.owner == World.PLAYER)
	# hire new caravans at caravan camps
	var posts := []
	for v in own:
		for b in w.buildings.values():
			if b.type == "caravanpost" and b.valley == v.idx and b.owner == World.PLAYER:
				posts.append(v.idx)
				break
	if posts.is_empty():
		h.add(_status_box(Content.L("Baue einen Rastplatz am Fuß eines Passes, um Karawanen aufzustellen.", "Build a caravan camp at the foot of a pass to hire caravans."), false))
	for v in posts:
		var box := UI.vbox([UI.label(Content.L("Rastplatz in ", "Caravan camp in ") + _vname(w, v), "Heading")])
		for cd in Content.caravans:
			var locked := not w.tier_unlocked(cd.unlockTier)
			var btn := h.act(Content.tx(cd.name), func(): h.game.command({"type": "buy_caravan", "valley": v, "caravan": cd.id}), "Small", locked)
			btn.tooltip_text = "%s\n%d × %d %s · %s %d/min" % [Content.tx(cd.desc), int(cd.slots), int(cd.capacity), Content.L("Plätze", "slots"), Content.L("Unterhalt", "upkeep"), int(cd.upkeep)]
			var line := UI.hbox([btn, _cost_row(cd.cost)])
			if locked:
				line.add_child(UI.label(Content.tx(Content.TIER[cd.unlockTier].name), "Muted"))
			box.add_child(line)
		h.add(UI.panel([box], "Dark"))
	for c in w.caravans:
		h.add(_caravan_box(h, c, own))


static func _caravan_box(h: Hud, c: Dictionary, own: Array) -> Control:
	var w := h.game.world
	var def: Dictionary = Content.CARAVAN[c.type]
	var st: Array = CARAVAN_STATUS.get(c.status, [c.status, c.status])
	var box := UI.vbox([UI.row(UI.label("%s #%d" % [Content.tx(def.name), c.id], "Heading"), h.act("✕", func(): h.game.command({"type": "delete_caravan", "id": c.id})))])
	var status := Content.L(st[0], st[1])
	if c.status == "moving" and not c.stops.is_empty():
		status += " → " + _vname(w, c.stops[c.leg].v)
	box.add_child(_status_box(status, c.status != "blocked"))
	var cargo := UI.hbox([UI.label(Content.L("Ladung:", "Cargo:"))], 3)
	for g in c.cargo:
		cargo.add_child(UI.good_icon(g, 22))
		cargo.add_child(UI.label(str(floori(c.cargo[g]))))
	cargo.add_child(UI.label("  (%d × %d)" % [int(def.slots), int(def.capacity)], "Muted"))
	box.add_child(cargo)
	box.add_child(UI.label(Content.L("Geliefert: %d Waren", "Delivered: %d goods") % floori(c.delivered), "Muted"))
	# route editor
	for i in c.stops.size():
		var stop: Dictionary = c.stops[i]
		var sbox := UI.vbox([UI.row(UI.label("%d. %s" % [i + 1, _vname(w, stop.v)]), h.act("✕", func():
			var next := _copy_stops(c)
			next.remove_at(i)
			h.game.command({"type": "caravan_stops", "id": c.id, "stops": next})))], 2)
		for mode in ["load", "unload"]:
			var line := UI.hbox([UI.label(Content.L("Laden:", "Load:") if mode == "load" else Content.L("Abladen:", "Unload:"), "Muted")], 3)
			for g in stop[mode]:
				var gb := UI.good_icon(g, 28)
				gb.mouse_filter = Control.MOUSE_FILTER_STOP
				gb.tooltip_text = Content.tx(Content.GOOD[g].name) + Content.L(" – klicken zum Entfernen", " – click to remove")
				gb.gui_input.connect(func(e):
					if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
						var next := _copy_stops(c)
						next[i][mode].erase(g)
						h.game.command({"type": "caravan_stops", "id": c.id, "stops": next})
						h.render_panel())
				line.add_child(gb)
			var pick := OptionButton.new()
			pick.fit_to_longest_item = false
			pick.theme_type_variation = "Small"
			pick.custom_minimum_size = Vector2(46, 30)
			pick.tooltip_text = Content.L("Ware hinzufügen", "Add a good")
			pick.add_item("+", 0)
			var k := 1
			var choices := []
			for g in Content.goods:
				if g.id in stop[mode]:
					continue
				var have := 0.0
				for v in own:
					have += v.storage.get(g.id, 0.0)
				if have <= 0.0 and Economy.good_balance(w).get(g.id, {}).get("prod", 0.0) <= 0.0:
					continue
				pick.add_icon_item(Art.good_icon(g.id), Content.tx(g.name), k)
				choices.append(g.id)
				k += 1
			pick.item_selected.connect(func(idx):
				if idx <= 0:
					return
				var next := _copy_stops(c)
				next[i][mode].append(choices[idx - 1])
				h.game.command({"type": "caravan_stops", "id": c.id, "stops": next})
				h.render_panel())
			line.add_child(pick)
			sbox.add_child(line)
		box.add_child(UI.panel([sbox]))
	var add := OptionButton.new()
	add.fit_to_longest_item = false
	add.theme_type_variation = "Small"
	add.add_item(Content.L("+ Halt hinzufügen", "+ Add stop"), -1)
	for v in own:
		add.add_item(_vname(w, v.idx), v.idx)
	add.item_selected.connect(func(idx):
		var vid := add.get_item_id(idx)
		if vid < 0:
			return
		var next := _copy_stops(c)
		next.append({"v": vid, "load": [], "unload": []})
		h.game.command({"type": "caravan_stops", "id": c.id, "stops": next})
		h.render_panel())
	box.add_child(add)
	return UI.panel([box], "Dark")


static func _copy_stops(c: Dictionary) -> Array:
	var out := []
	for st in c.stops:
		out.append({"v": st.v, "load": st.load.duplicate(), "unload": st.unload.duplicate()})
	return out


# ---------------------------------------------------------------- production chains

static var chain_tier := ""


## Anno-style chain planner: how many of each building feed 100 residents of a tier.
static func chains(h: Hud) -> void:
	var w := h.game.world
	h.add(UI.label(Content.L("Produktionsketten", "Production Chains"), "Title"))
	if chain_tier == "" or not w.tier_unlocked(chain_tier):
		chain_tier = w.unlocked_tiers[-1]
	var tabs := HFlowContainer.new()
	for t in Content.tiers:
		if w.tier_unlocked(t.id):
			tabs.add_child(h.act(Content.tx(t.name), func(): chain_tier = t.id, "Active" if t.id == chain_tier else "Small"))
	h.add(tabs)
	var tier: Dictionary = Content.TIER[chain_tier]
	h.add(_wrap(Content.tx(tier.get("history", {})), "Muted"))
	h.add(UI.label(Content.L("Bedarf für 100 Bewohner", "Demand of 100 residents"), "Heading"))
	for n in tier.needs:
		if not n.has("consumption"):
			var sv: String = Content.service_ids.get(n.id, "")
			if sv != "":
				h.add(UI.hbox([UI.icon(Art.building_icon(sv), 24), UI.label(Content.tx(Content.BUILDING[sv].name)), UI.label(Content.L("Einzugsbereich", "service radius"), "Muted")]))
			continue
		var demand := float(n.consumption) * 100.0
		var box := UI.vbox([UI.hbox([UI.good_icon(n.id, 26), UI.label(Content.need_name(n.id) + (Content.L(" (Luxus)", " (luxury)") if n.kind == "luxury" else ""), "Heading"), UI.label("%.1f/min" % demand, "Muted")])], 1)
		_chain_lines(w, box, n.id, demand, 0, {})
		h.add(UI.panel([box], "Dark"))
	h.add(UI.label(Content.L("Warenbilanz (alle Täler)", "Goods balance (all valleys)"), "Heading"))
	var bal := Economy.good_balance(w)
	for g in Content.goods:
		var stock := 0.0
		for v in w.valleys:
			if v.owner == World.PLAYER:
				stock += v.storage.get(g.id, 0.0)
		var bb: Dictionary = bal.get(g.id, {"prod": 0.0, "cons": 0.0})
		if stock < 0.5 and bb.prod <= 0.0 and bb.cons <= 0.0:
			continue
		var diff: float = bb.prod - bb.cons
		var val := UI.label("%+.1f/min" % diff)
		val.add_theme_color_override("font_color", UI.GOOD if diff >= -0.01 else UI.BAD)
		h.add(UI.row(UI.hbox([UI.good_icon(g.id, 22), UI.label(Content.tx(g.name)), UI.label(str(floori(stock)), "Muted")]), val))


static func _producer(good: String) -> Dictionary:
	for b in Content.buildings:
		if b.get("outputs", {}).has(good):
			return b
	return {}


static func _chain_lines(w: World, box: VBoxContainer, good: String, demand: float, depth: int, seen: Dictionary) -> void:
	var b := _producer(good)
	if b.is_empty() or seen.has(b.id) or depth > 5:
		return
	var rate: float = float(b.outputs[good]) * 60.0 / float(b.cycle)
	var count := demand / rate
	var text := "%s%.1f × %s" % ["    ".repeat(depth), count, Content.tx(b.name)]
	var req: Dictionary = b.get("requires", {})
	var where := ""
	if req.has("fertility"):
		where = Content.tx(Content.FERTILITY[req.fertility].name)
	elif req.has("deposit"):
		where = "⛏ " + Content.tx(Content.GOOD.get({"copper": "copperore"}.get(req.deposit, req.deposit), {"name": req.deposit}).name)
	var line := UI.hbox([UI.icon(Art.building_icon(b.id), 22), UI.label(text)], 4)
	if where != "":
		var places := []
		for v in w.valleys:
			if v.discovered and ((req.has("fertility") and req.fertility in v.fertilities) or (req.has("deposit") and req.deposit in Content.valley_def(v.def).deposits)):
				places.append(_vname(w, v.idx))
		var wl := UI.label("(%s%s)" % [where, ": " + ", ".join(places) if not places.is_empty() else Content.L(" – noch unbekannt", " – not found yet")], "Muted")
		line.add_child(wl)
	box.add_child(line)
	var s2 := seen.duplicate()
	s2[b.id] = true
	for g in b.get("inputs", {}):
		_chain_lines(w, box, g, count * float(b.inputs[g]) * 60.0 / float(b.cycle), depth + 1, s2)


static func trade(h: Hud) -> void:
	var w := h.game.world
	var home := w.home_valley()
	h.add(UI.label(Content.L("Handel", "Trade"), "Title"))
	h.add(_wrap(Content.L("Gehandelt wird über das Lager von %s.", "Trades use the storage of %s.") % Content.tx(Content.valley_def(home.def).name), "Muted"))
	h.add(UI.label(Content.L("Händler vom Fluss", "River trader"), "Heading"))
	if w.trader.present:
		h.add(UI.label(Content.L("Bleibt noch %d s.", "Stays for %d s.") % ceili(w.trader.timer), "Muted"))
		for g in w.trader.prices:
			h.add(UI.hbox([UI.good_icon(g, 28), _name_stock(g, home), UI.spacer(),
				h.act("%s 5 · %d" % [Content.L("Kauf", "Buy"), Logistics.buy_price(w, g) * 5], func(): h.game.command({"type": "trade", "partner": "trader", "good": g, "amount": 5})),
				h.act("%s 5 · %d" % [Content.L("Verk.", "Sell"), Logistics.sell_price(w, g) * 5], func(): h.game.command({"type": "trade", "partner": "trader", "good": g, "amount": -5}))]))
	else:
		h.add(UI.label(Content.L("Der nächste Händler kommt in etwa %d s.", "The next trader arrives in about %d s.") % ceili(w.trader.timer), "Muted"))
	h.add(UI.label(Content.L("Stämme", "Tribes"), "Heading"))
	var known := w.rivals.filter(func(r): return r.contacted)
	if known.is_empty():
		h.add(_wrap(Content.L("Noch kein Kontakt. Hinter den Bergen leben andere Stämme – erkunde die Pfade.", "No contact yet. Other tribes live beyond the mountains – explore the paths."), "Muted"))
	for r in known:
		var def: Dictionary = Content.RIVAL[r.id]
		var box := UI.vbox([UI.row(UI.label(Content.tx(def.name), "Heading"), h.act(Content.L("Geschenk (150)", "Gift (150)"), func(): h.game.command({"type": "gift", "rival": r.id}))),
			UI.hbox([UI.label(Content.L("Beziehung", "Relation")), UI.bar(r.relation / 100.0, r.relation < 25, 140), UI.label(str(roundi(r.relation)))]),
			UI.label("%d %s" % [r.population, Content.L("Bewohner", "residents")], "Muted")])
		for g in def.sells:
			box.add_child(UI.hbox([UI.good_icon(g, 26), UI.label(Content.tx(Content.GOOD[g].name)), UI.spacer(),
				h.act("%s 5 · %d" % [Content.L("Kauf", "Buy"), Logistics.rival_buy_price(g, r.relation) * 5], func(): h.game.command({"type": "trade", "partner": r.id, "good": g, "amount": 5}))]))
		for g in def.buys:
			box.add_child(UI.hbox([UI.good_icon(g, 26), _name_stock(g, home), UI.spacer(),
				h.act("%s 5 · %d" % [Content.L("Verk.", "Sell"), Logistics.rival_sell_price(g, r.relation) * 5], func(): h.game.command({"type": "trade", "partner": r.id, "good": g, "amount": -5}))]))
		h.add(UI.panel([box], "Dark"))


static func _name_stock(g: String, home: Dictionary) -> Control:
	return UI.vbox([UI.label(Content.tx(Content.GOOD[g].name)), UI.label("%s %d" % [Content.L("Lager", "Stock"), floori(home.storage.get(g, 0.0))], "Muted")], -4)
