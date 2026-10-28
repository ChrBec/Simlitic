class_name HudPanels
## Content of the right-hand panels: selected building, population, valleys & routes, trade.

const STATUS := {
	"ok": ["Arbeitet", "Working"], "noRoad": ["Kein Pfad zum Lagerplatz!", "No path to the storage yard!"],
	"noWorkers": ["Zu wenige Arbeitskräfte", "Not enough workers"], "noInput": ["Rohstoffe fehlen", "Missing input goods"],
	"full": ["Lager voll", "Storage full"], "paused": ["Pausiert", "Paused"], "noNature": ["Zu wenig Natur im Umkreis", "Not enough nature nearby"],
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


static func valleys(h: Hud) -> void:
	var w := h.game.world
	h.add(UI.label(Content.L("Täler & Pfade", "Valleys & Paths"), "Title"))
	h.add(_wrap(Content.L("Jedes Tal ist wie eine Insel: eigene Fruchtbarkeiten, eigenes Lager, eigene Arbeiter.", "Every valley is like an island: its own fertilities, storage and workers."), "Muted"))
	var ex = w.expedition
	if ex != null:
		h.add(UI.hbox([UI.label(Content.L("Kundschafter unterwegs …", "Scouts on their way …")), UI.bar(1.0 - ex.time_left / ex.total, false, 140)]))
	for v in w.valleys:
		if not v.discovered:
			continue
		var name := Content.tx(Content.valley_def(v.def).name)
		var pop := 0.0
		for k in v.population:
			pop += v.population[k]
		var status := ""
		if v.owner == World.PLAYER:
			status = "%s · %d %s" % [Content.L("Dein Tal", "Your valley"), roundi(pop), Content.L("Bewohner", "residents")]
		elif v.owner != null:
			status = Content.tx(Content.RIVAL[v.owner].name)
		else:
			status = Content.L("Unbesiedelt – baue hier einen Lagerplatz", "Unsettled – build a storage yard here")
		var box := UI.vbox([UI.row(UI.label(name, "Heading"), h.act(Content.L("Zeigen", "Show"), func(): h.game.view.center_on(v.cx, v.cy))), _wrap(status, "Muted")])
		var chips := []
		for f in v.fertilities:
			chips.append(Content.tx(Content.FERTILITY[f].name))
		box.add_child(_wrap(", ".join(chips), "Muted"))
		if v.owner == World.PLAYER:
			var has_scout := false
			for b in w.buildings.values():
				if b.type == "scout" and b.valley == v.idx and b.owner == World.PLAYER:
					has_scout = true
			var open := false
			for p in w.passes:
				if (p.a != v.idx and p.b != v.idx) or p.discovered:
					continue
				open = true
				var other: Dictionary = w.valleys[p.b if p.a == v.idx else p.a]
				var target := Content.tx(Content.valley_def(other.def).name) if other.discovered else Content.L("Unbekannter Pfad", "Unknown path")
				box.add_child(UI.row(UI.label("⛰ %s (%d %s)" % [target, p.tiles.size(), Content.L("Felder", "tiles")]),
					h.act(Content.L("Erkunden", "Explore"), func(): h.game.command({"type": "explore", "pass": p.idx, "from": v.idx}), "Small", not has_scout or ex != null)))
			if open and not has_scout:
				var hint := Content.L("Baue ein Kundschafterlager, um Pfade zu erkunden (Proviant: 5 Fleisch, 150 Muscheln).", "Build a scout camp to explore paths (provisions: 5 meat, 150 shells).") if w.tier_unlocked("hunters") else Content.L("Kundschafter gibt es ab der Stufe der Jäger.", "Scouts become available with the hunters.")
				box.add_child(_wrap(hint, "Muted"))
		h.add(UI.panel([box], "Dark"))
	var unknown := w.valleys.filter(func(v): return not v.discovered).size()
	if unknown > 0:
		h.add(_wrap(Content.L("%d Täler liegen noch im Nebel der Berge.", "%d valleys still lie hidden in the mountains.") % unknown, "Muted"))

	h.add(UI.label(Content.L("Trägerrouten", "Porter routes"), "Heading"))
	var own := w.valleys.filter(func(v): return v.owner == World.PLAYER and w.storage_of(v.idx) != null)
	for r in w.routes:
		var a: Dictionary = w.valleys[r.a]
		var b: Dictionary = w.valleys[r.b]
		var an := Content.tx(Content.valley_def(a.def).name)
		var bn := Content.tx(Content.valley_def(b.def).name)
		var box := UI.vbox([UI.row(UI.label("%s ⇄ %s" % [an, bn]), h.act("✕", func(): h.game.command({"type": "delete_route", "id": r.id})))])
		for dir in ["ab", "ba"]:
			var from: Dictionary = a if dir == "ab" else b
			var current: Array = r["cargo_" + dir]
			box.add_child(UI.label("%s → %s" % [an, bn] if dir == "ab" else "%s → %s" % [bn, an], "Muted"))
			var pick := HFlowContainer.new()
			for g in Content.goods:
				if from.storage.get(g.id, 0.0) <= 0.0 and not g.id in current:
					continue
				var btn := Button.new()
				btn.theme_type_variation = "Item"
				btn.icon = Art.good_icon(g.id)
				btn.expand_icon = true
				btn.custom_minimum_size = Vector2(38, 38)
				btn.tooltip_text = Content.tx(g.name)
				btn.modulate = Color(1.15, 1.05, 0.7) if g.id in current else Color(1, 1, 1, 0.75)
				btn.pressed.connect(func():
					var next := current.duplicate()
					if g.id in next:
						next.erase(g.id)
					else:
						next.append(g.id)
					h.game.command({"type": "route_cargo", "id": r.id, "dir": dir, "goods": next})
					h.render_panel())
				pick.add_child(btn)
			if pick.get_child_count() == 0:
				pick.add_child(UI.label(Content.L("Lager leer", "Storage empty"), "Muted"))
			box.add_child(pick)
		h.add(UI.panel([box], "Dark"))
	if own.size() >= 2:
		var sa := OptionButton.new()
		var sb := OptionButton.new()
		for v in own:
			sa.add_item(Content.tx(Content.valley_def(v.def).name), v.idx)
			sb.add_item(Content.tx(Content.valley_def(v.def).name), v.idx)
		sb.select(1)
		h.add(UI.hbox([sa, UI.label("⇄"), sb]))
		h.add(h.act(Content.L("Route anlegen (200 Muscheln)", "Create route (200 shells)"), func(): h.game.command({"type": "create_route", "a": sa.get_selected_id(), "b": sb.get_selected_id()})))
	else:
		h.add(_wrap(Content.L("Besiedle ein zweites Tal, um Träger zwischen den Tälern laufen zu lassen.", "Settle a second valley to send porters between valleys."), "Muted"))


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
