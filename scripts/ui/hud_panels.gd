class_name HudPanels
## Content of the right-hand panels: selected building, population, valleys & routes, trade.

const STATUS := {
	"ok": ["Arbeitet", "Working"], "noRoad": ["Kein Pfad zum Lagerplatz!", "No path to the storage yard!"],
	"noWorkers": ["Zu wenige Arbeitskräfte", "Not enough workers"], "noInput": ["Rohstoffe fehlen", "Missing input goods"],
	"full": ["Lager voll", "Storage full"], "paused": ["Pausiert", "Paused"], "noNature": ["Zu wenig Natur im Umkreis", "Not enough nature nearby"],
	"winter": ["Winterruhe", "Winter rest"], "season": ["Jahreszeit – arbeitet langsamer", "Off season – working slower"],
	"noGame": ["Das Wild ist knapp", "Game is scarce"], "noFish": ["Kaum noch Fische", "Few fish left"],
	"fire": ["Es brennt!", "On fire!"], "flood": ["Hochwasser – steht still", "Flooded – idle"],
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
	h.add(UI.hbox([UI.icon(Art.building_icon(b.type), 64), UI.vbox([UI.label(Content.tx(def.name), "Title"), UI.label(vname(w, b.valley) + ("" if b.owner == World.PLAYER else " · " + Content.tx(Content.RIVAL[b.owner].name)), "Muted")], -6)]))
	if b.owner != World.PLAYER:
		h.add(_wrap(Content.tx(def.desc)))
		return
	var demolish := h.act(Content.L("Abreißen", "Demolish"), func():
		h.game.command({"type": "demolish", "x": b.x, "y": b.y}, "demolish")
		h.open_panel(""))
	if b.get("burning", false):
		h.add(_status_box(Content.L("Es brennt! Lösche mit 5 Holz, bevor es niederbrennt.", "It's burning! Put it out with 5 wood before it burns down."), false))
		for e in w.events:
			if e.kind == "fire" and e.get("building", 0) == b.id:
				h.add(h.act(Content.L("Löschen (5 Holz)", "Put out (5 wood)"), func(): h.game.command({"type": "resolve_event", "id": e.id}, "build"), "Active"))
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
		h.add(UI.hbox([UI.label(Content.L("Produktivität", "Productivity")), UI.bar(minf(1.0, b.productivity), b.productivity < 0.5, 120), UI.label("%d%%" % roundi(b.productivity * 100))]))
		var wf: Dictionary = v.workforce[def.workforce.tier]
		h.add(UI.row(UI.label("%s: %d %s" % [Content.L("Arbeiter", "Workers"), int(def.workforce.amount), Content.tx(Content.TIER[def.workforce.tier].name)]),
			UI.label("%s %d/%d" % [Content.L("Tal", "Valley"), floori(wf.have), wf.need], "Muted")))
		var group: String = def.get("group", "")
		if Economy.SEASON.has(group):
			h.add(UI.row(UI.label(Content.L("Jahreszeit", "Season")), UI.label("%d %%" % roundi(Economy.SEASON[group][w.season()] * 100))))
		if group == "hunt":
			h.add(UI.row(UI.label(Content.L("Wildbestand im Tal", "Game in the valley")), UI.label("%d %%" % roundi(v.game * 100))))
			h.add(_wrap(Content.L("Jede Jagd lichtet das Wild. Es wächst nach – im Frühling doppelt so schnell. Zu viele Jäger jagen bald ins Leere.", "Every hunt thins the game. It regrows – twice as fast in spring. Too many hunters soon hunt for nothing."), "Muted"))
		if group == "fish":
			h.add(UI.row(UI.label(Content.L("Fischbestand im Tal", "Fish in the valley")), UI.label("%d %%" % roundi(v.fish * 100))))
		if def.get("requires", {}).has("nature"):
			var kind_text := Content.L("Bäume im Umkreis", "Trees nearby") if def.requires.nature.kind == "tree" else Content.L("Sträucher im Umkreis", "Bushes nearby")
			h.add(UI.row(UI.label(kind_text), UI.label("%d%%" % roundi(maxf(0.0, b.nature) * 100))))
			if group == "wood":
				h.add(_wrap(Content.L("Gefällte Bäume hinterlassen Stümpfe, die nach etwa zwei Jahren nachwachsen.", "Felled trees leave stumps that grow back after about two years."), "Muted"))
		h.add(UI.row(UI.label(Content.L("Unterhalt", "Upkeep")), UI.label("%d/min" % int(def.upkeep))))
		h.add(UI.hbox([h.act(Content.L("Fortsetzen", "Resume") if b.paused else Content.L("Pausieren", "Pause"), func(): h.game.command({"type": "pause", "id": b.id, "paused": not b.paused})), demolish]))
	elif b.has("tier"):
		_house(h, b, def, v, demolish)
	else:
		h.add(_wrap(Content.tx(def.desc)))
		if b.type == "hearth":
			h.add(h.act(Content.L("Feste, Kostbarkeiten & Bräuche …", "Festivals, treasures & customs …"), func(): h.open_panel("hearth"), "Active"))
		if def.has("service"):
			var served := 0
			for x in w.buildings.values():
				if x.has("tier") and x.valley == b.valley and w.coverage.get(x.id, {}).has(def.service.id):
					served += 1
			h.add(UI.row(UI.label(Content.L("Reichweite", "Radius")), UI.label(str(int(def.service.radius)))))
			h.add(UI.row(UI.label(Content.L("Versorgte Häuser", "Homes served")), UI.label(str(served))))
			if not b.connected:
				h.add(_status_box(_status("noRoad"), false))
		if def.has("store"):
			var prot := []
			for g in def.store.get("protect", []):
				prot.append(Content.tx(Content.GOOD[g].name))
			if not prot.is_empty():
				h.add(_wrap(Content.L("Schützt vor Verderb: ", "Protects from spoiling: ") + ", ".join(prot), "Muted"))
			if not b.connected:
				h.add(_status_box(_status("noRoad"), false))
		if def.has("beauty"):
			h.add(UI.row(UI.label(Content.L("Schönheit", "Beauty")), UI.label("+%d (%s %d)" % [int(def.beauty.value), Content.L("Umkreis", "radius"), int(def.beauty.radius)])))
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


## A home: who lives here, what they wish for, how they feel – and the upgrade to the next age.
static func _house(h: Hud, b: Dictionary, def: Dictionary, v: Dictionary, demolish: Button) -> void:
	var w := h.game.world
	var tier: Dictionary = Content.TIER[b.tier]
	var pop := w.player_population()
	h.add(UI.row(UI.label(Content.tx(tier.name), "Heading"), UI.label("%d / %d %s" % [roundi(b.residents), roundi(b.get("target", 0.0)), Content.L("Bewohner", "residents")])))
	if not b.connected:
		h.add(_status_box(_status("noRoad"), false))
	var mood: float = b.mood
	h.add(UI.hbox([UI.Glyph.new("mood", 24, Hud._mood_color(mood)), UI.label(Content.L("Stimmung", "Mood")), UI.bar(mood / 100.0, mood < 30.0, 110), UI.label(str(roundi(mood)))]))
	var parts := []
	if b.get("hungry", false):
		parts.append(Content.L("Hunger −20", "hunger −20"))
	if v.get("freezing", false):
		parts.append(Content.L("Kälte −20", "cold −20"))
	if b.get("beauty", 0.0) > 0.0:
		parts.append(Content.L("Schönheit +%d", "beauty +%d") % roundi(b.beauty))
	if b.get("noise", 0.0) > 0.0:
		parts.append(Content.L("Lärm −%d", "noise −%d") % roundi(b.noise))
	var m: Dictionary = v.get("mods", {})
	if m.get("mood", 0.0) != 0.0:
		parts.append(Content.L("Feste, Bräuche & Kostbarkeiten %+d", "festivals, customs & treasures %+d") % roundi(m.mood))
	if not parts.is_empty():
		h.add(_wrap(", ".join(parts), "Muted"))
	for section in [[Content.L("Grundbedürfnisse", "Basic needs"), ["basic", "service"]], [Content.L("Luxus (Stimmung)", "Luxury (mood)"), ["luxury", "service-luxury"]]]:
		var needs: Array = tier.needs.filter(func(n): return n.kind in section[1])
		if needs.is_empty():
			continue
		h.add(UI.label(section[0], "Heading"))
		for n in needs:
			var ic: Control = UI.good_icon(n.id, 26) if Content.GOOD.has(n.id) else UI.icon(Art.building_icon(Content.service_ids.get(n.id, "fireplace")), 26)
			var name := Content.need_name(n.id)
			if n.has("residents"):
				name += "  +%d" % int(n.residents)
			var lab := UI.label(name)
			lab.custom_minimum_size.x = 170
			if not Economy.need_active(n, pop, b.tier):
				var later := UI.hbox([ic, lab, UI.label(Content.L("ab %d %s", "at %d %s") % [int(n.at), Content.tx(tier.name)], "Muted")])
				later.modulate.a = 0.5
				h.add(later)
				continue
			var sat: float = b.needs.get(n.id, 0.0)
			h.add(UI.hbox([ic, lab, UI.bar(sat, sat < 0.5, 100)]))
	var nt = Content.next_tier(b.tier)
	if nt != null:
		h.add(UI.label(Content.L("Aufwerten: ", "Upgrade: ") + Content.tx(Content.BUILDING[nt.house].name), "Heading"))
		var mats := UI.hbox([UI.label(Content.L("Material:", "Materials:"))])
		for g in nt.upgradeCost:
			var have: float = v.storage.get(g, 0.0)
			mats.add_child(UI.good_icon(g, 24))
			var l := UI.label("%d/%d" % [floori(have), int(nt.upgradeCost[g])])
			if have < nt.upgradeCost[g]:
				l.add_theme_color_override("font_color", UI.BAD)
			mats.add_child(l)
		h.add(mats)
		var reasons := []
		if not w.tier_unlocked(nt.id):
			reasons.append(Content.L("%s sind noch nicht freigeschaltet – Ama kennt den Weg.", "%s are not unlocked yet – Ama knows the way.") % Content.tx(nt.name))
		else:
			if b.get("hungry", false) or not b.ready:
				reasons.append(Content.L("Grundbedürfnisse ≥ 70 %, Stimmung ≥ 30 und ein volles Haus nötig.", "Needs basic needs ≥ 70%, mood ≥ 30 and a full home."))
			if not w.can_afford(nt.upgradeCost, v.storage):
				reasons.append(Content.L("Es fehlt Material im Lager.", "Materials are missing in storage."))
		for r in reasons:
			h.add(_wrap(r, "Muted"))
		var up := h.act(Content.L("Aufwerten", "Upgrade"), func(): h.game.command({"type": "upgrade", "id": b.id}, "build"), "Active", not reasons.is_empty() or b.locked)
		var lock := CheckBox.new()
		lock.text = Content.L("Aufwertung sperren", "Lock upgrade")
		lock.button_pressed = b.locked
		lock.toggled.connect(func(on): h.game.command({"type": "lock_upgrade", "id": b.id, "locked": on}))
		h.add(UI.hbox([up, lock]))
		h.add(_wrap(Content.L("Neue Wünsche beginnen nach dem Aufwerten bei null. Eine Minute lang zieht deshalb niemand aus.", "New wishes start at zero after an upgrade. For one minute nobody moves out because of that."), "Muted"))
	h.add(demolish)


## The compact card bottom-left for a selected building.
static func place_building(h: Hud, b: Dictionary) -> Control:
	var w := h.game.world
	var def: Dictionary = Content.BUILDING[b.type]
	var sub := ""
	if b.has("tier"):
		sub = "%d %s · %s %d" % [roundi(b.residents), Content.L("Personen", "people"), Content.L("Stimmung", "mood"), roundi(b.mood)]
		if b.get("ready", false) and not b.locked:
			sub += " · ⇧ " + Content.L("bereit", "ready")
	elif def.category == "production":
		sub = "%s · %d %s" % [_status(b.status if b.connected else "noRoad"), int(def.workforce.amount), Content.L("Personen", "people")]
	else:
		sub = Content.tx(Content.valley_def(w.valleys[b.valley].def).name)
	var l := UI.label(sub, "", true)
	l.custom_minimum_size.x = 170
	return UI.hbox([UI.icon(Art.building_icon(b.type), 84), UI.vbox([UI.label(Content.tx(def.name), "Heading"), l], -2)], 8)


static func population(h: Hud) -> void:
	var w := h.game.world
	var pop := w.player_population()
	var bal := Economy.good_balance(w)
	h.add(UI.label(Content.L("Bevölkerung", "Population"), "Title"))
	h.add(_wrap(Content.L("Neue Leute ziehen nach und nach zu – schneller bei guter Stimmung und im Frühling. Aufwerten musst du selbst: Ein Pfeil über dem Dach zeigt, wer bereit ist.", "Newcomers arrive one by one – faster with a good mood and in spring. Upgrading is up to you: an arrow over the roof shows who is ready."), "Muted"))
	for v in w.valleys:
		if v.owner == World.PLAYER:
			h.add(UI.row(UI.label(vname(w, v.idx)), UI.hbox([UI.Glyph.new("mood", 20, Hud._mood_color(v.mood)), UI.label("%d" % roundi(v.mood)), UI.label(Content.L(" · Nahrung %d", " · food %d") % floori(w.food_stock(v.idx)), "Muted")])))
	for t in Content.tiers:
		var unlocked := w.tier_unlocked(t.id)
		var homes := 0
		var ready := 0
		for b in w.buildings.values():
			if b.owner == World.PLAYER and b.get("tier", "") == t.id:
				homes += 1
				if b.get("ready", false) and not b.locked:
					ready += 1
		var box := UI.vbox([UI.row(UI.label(Content.tx(t.name), "Heading"), UI.label(Content.tx(t.age), "Muted")),
			UI.row(UI.label("%d %s" % [pop[t.id], Content.L("Bewohner", "residents")]), UI.label("%d %s" % [homes, Content.L("Häuser", "homes")]))])
		if not unlocked:
			box.add_child(_wrap(Content.L("Noch nicht erreicht – Ama stellt dir die Aufgabe, wenn es so weit ist.", "Not reached yet – Ama will set you the task when the time comes."), "Muted"))
		else:
			for n in t.needs:
				if not n.has("consumption") or not Economy.need_active(n, pop, t.id):
					continue
				var bb: Dictionary = bal.get(n.id, {"prod": 0.0, "cons": 0.0})
				var diff: float = bb.prod - bb.cons
				var val := UI.label("%+.1f/min" % diff)
				val.add_theme_color_override("font_color", UI.GOOD if diff >= -0.01 else UI.BAD)
				var name := Content.need_name(n.id) + (Content.L(" (Luxus)", " (luxury)") if n.kind == "luxury" else "")
				box.add_child(UI.row(UI.hbox([UI.good_icon(n.id, 22), UI.label(name)]), val))
			var nt = Content.next_tier(t.id)
			if nt != null and w.tier_unlocked(nt.id):
				box.add_child(UI.row(UI.label(Content.L("Bereit zum Aufwerten: %d", "Ready to upgrade: %d") % ready),
					h.act(Content.L("Alle bereiten aufwerten", "Upgrade all ready"), func(): h.game.command({"type": "upgrade_all", "tier": t.id}, "build"), "Small", ready == 0)))
		var p := UI.panel([box], "Dark")
		p.modulate.a = 1.0 if unlocked else 0.6
		h.add(p)


static func vname(w: World, v: int) -> String:
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
		var box := UI.vbox([UI.row(UI.label(vname(w, v.idx), "Heading"), h.act(Content.L("Zeigen", "Show"), func(): h.game.view.center_on(v.cx, v.cy))), _wrap(status, "Muted")])
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
					var target := vname(w, other) if w.valleys[other].discovered else Content.L("Unbekannter Pfad", "Unknown path")
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
	var head := UI.label("⛰ %s – %s" % [vname(w, other), state])
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
		var box := UI.vbox([UI.label(Content.L("Rastplatz in ", "Caravan camp in ") + vname(w, v), "Heading")])
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
		status += " → " + vname(w, c.stops[c.leg].v)
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
		var sbox := UI.vbox([UI.row(UI.label("%d. %s" % [i + 1, vname(w, stop.v)]), h.act("✕", func():
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
		add.add_item(vname(w, v.idx), v.idx)
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
				places.append(vname(w, v.idx))
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


# ---------------------------------------------------------------- quests and characters

## One line of a quest goal, e.g. "Build 4 hide domes (2/4)".
static func goal_text(w: World, q: Dictionary, i: int) -> String:
	var g: Dictionary = q.goals[i]
	var s: Dictionary = w.quests.get(q.id, {"base": {}, "ok": {}})
	var p := Story.progress(w, q, i, s)
	var have := int(p[0])
	var need := int(p[1])
	var n := int(g.get("n", 1))
	match g.type:
		"build":
			return Content.L("Baue %d× %s (%d/%d)", "Build %d× %s (%d/%d)") % [n, Content.tx(Content.BUILDING[g.building].name), mini(have, need), need]
		"houses":
			return Content.L("%d× %s (%d/%d)", "%d× %s (%d/%d)") % [n, Content.tx(Content.BUILDING[Content.TIER[g.tier].house].name), mini(have, need), need]
		"pop":
			var who := Content.tx(Content.TIER[g.tier].name) if g.has("tier") else Content.L("Bewohner", "residents")
			return "%d %s (%d)" % [n, who, have]
		"stock":
			return Content.L("%d %s im Lager (%d)", "%d %s in storage (%d)") % [n, Content.tx(Content.GOOD[g.good].name), have]
		"deliver":
			return Content.L("Liefere %d %s ans Talherz (%d)", "Deliver %d %s to the Valley Heart (%d)") % [n, Content.tx(Content.GOOD[g.good].name), have]
		"produce":
			return Content.L("Stelle %d %s her (%d)", "Produce %d %s (%d)") % [n, Content.tx(Content.GOOD[g.good].name), have]
		"served":
			return Content.L("%d Häuser am %s (%d)", "%d homes served by the %s (%d)") % [n, Content.tx(Content.BUILDING[Content.service_ids[g.service]].name), have]
		"festival":
			return Content.L("Feiere: %s", "Celebrate: %s") % Content.tx(Content.FESTIVAL[g.festival].name)
		"find":
			return Content.L("Finde Fenn im Wald – klick ihn an", "Find Fenn in the forest – click him")
		"explore":
			return Content.L("Erkunde einen Bergpfad", "Explore a mountain path")
		"valleys":
			return Content.L("Halte %d Täler (%d)", "Hold %d valleys (%d)") % [n, have]
		"contact":
			return Content.L("Triff einen fremden Stamm", "Meet a foreign tribe")
		"caravan":
			return Content.L("Eine Karawane mit Route über 2 Täler", "A caravan with a route through 2 valleys")
		"custom":
			return Content.L("Nimm am Talherz einen Brauch an", "Adopt a custom at the Valley Heart")
		"game":
			return Content.L("Wildbestand im Haupttal ≥ %d %% (%d %%)", "Game in the main valley ≥ %d%% (%d%%)") % [n, have]
		"winter_food":
			return Content.L("%d Nahrung im Lager, wenn der Winter beginnt (jetzt %d)", "%d food in storage when winter begins (now %d)") % [n, floori(w.food_stock(w.home_valley().idx))]
		"survive":
			return Content.L("Überstehe die Große Kälte (nächster Winter)", "Survive the Great Cold (next winter)")
	return g.type


static func reward_lines(q: Dictionary, r: Dictionary) -> Array:
	var out := []
	for b in q.get("unlock", []):
		out.append(Content.L("Bauplan: ", "Blueprint: ") + Content.tx(Content.BUILDING[b].name))
	for b in r.get("unlock", []):
		out.append(Content.L("Bauplan: ", "Blueprint: ") + Content.tx(Content.BUILDING[b].name))
	for f in q.get("festivals", []):
		out.append(Content.L("Fest: ", "Festival: ") + Content.tx(Content.FESTIVAL[f].name))
	if r.has("shells"):
		out.append(Content.L("%d Muscheln", "%d shells") % int(r.shells))
	if r.has("prestige"):
		out.append(Content.L("+%d Ansehen", "+%d prestige") % int(r.prestige))
	for it in r.get("items", []):
		out.append(Content.L("Kostbarkeit: ", "Treasure: ") + Content.tx(Content.ITEM[it].name))
	if r.has("customs"):
		out.append(Content.L("Bräuche", "Customs"))
	if r.has("tier"):
		out.append(Content.L("Neue Zeit: ", "New age: ") + Content.tx(Content.TIER[r.tier].name))
	if r.get("win", false):
		out.append(Content.L("Das Ende der Steinzeit", "The end of the Stone Age"))
	return out


static func character_dialog(h: Hud, who: String) -> void:
	var w := h.game.world
	var c: Dictionary = Content.CHARACTER[who]
	var portrait := UI.icon(Art.portrait(who), 170)
	var head := UI.vbox([UI.label(Content.tx(c.name), "Title"), UI.label(Content.tx(c.title), "Muted")], -8)
	var body := UI.vbox([head], 6)
	var qid := Story.offered(w, who)
	var close := UI.button(Content.L("Später", "Later"), h.close_dialog, "Small")
	if qid != "":
		var q: Dictionary = Content.QUEST[qid]
		var st: String = w.quests[qid].state
		var t := UI.label(Content.tx(q.title), "Heading")
		t.add_theme_color_override("font_color", UI.OCHRE_DARK)
		body.add_child(t)
		body.add_child(_wrap_w(Content.tx(q.text), 470))
		var goals := UI.vbox([UI.label(Content.L("Aufgabe", "Task"), "Heading")], 0)
		for i in q.goals.size():
			goals.add_child(_wrap_w("• " + goal_text(w, q, i), 470, "Muted"))
		body.add_child(goals)
		var rl := reward_lines(q, q.reward)
		if q.get("threshold", false):
			rl.push_front(Content.L("Schwelle zur nächsten Zeit", "Threshold to the next age"))
		if not rl.is_empty():
			body.add_child(_wrap_w(Content.L("Du erhältst: ", "You receive: ") + " · ".join(rl), 470, "Muted"))
		if st == "offered":
			body.add_child(UI.hbox([UI.button(Content.L("Annehmen", "Accept"), func():
				h.game.command({"type": "accept_quest", "id": qid}, "build")
				h.close_dialog()), close], 10))
		elif st == "choose":
			var row := UI.hbox([], 8)
			for i in q.choices.size():
				var ch: Dictionary = q.choices[i]
				var b := UI.button(Content.tx(ch.label), func():
					h.game.command({"type": "quest_choice", "id": qid, "choice": i}, "build")
					h.close_dialog(), "Small")
				var it: Array = ch.reward.get("items", [])
				if not it.is_empty():
					b.tooltip_text = Content.tx(Content.ITEM[it[0]].desc)
				row.add_child(b)
			body.add_child(row)
	else:
		var mine := Story.active_quests(w).filter(func(q): return q.char == who)
		if mine.is_empty():
			body.add_child(_wrap_w(_idle_line(w, who), 470))
		for q in mine:
			body.add_child(UI.label(Content.tx(q.title), "Heading"))
			for i in q.goals.size():
				body.add_child(_wrap_w("• " + goal_text(w, q, i), 470, "Muted"))
		body.add_child(UI.button(Content.L("Schließen", "Close"), h.close_dialog, "Small"))
	h.dialog.add_child(UI.hbox([portrait, body], 14))


## What a character says when there is no task: a hint about the valley's state.
static func _idle_line(w: World, who: String) -> String:
	var home := w.home_valley()
	match who:
		"borr":
			if home.game < 0.4:
				return Content.L("Das Wild wird knapp. Lass ein, zwei Jagdlager ruhen – im Frühling erholt es sich am schnellsten.", "Game is getting scarce. Let a camp or two rest – it recovers fastest in spring.")
			return Content.L("Der Wald ist voller Leben. Fenn riecht Hirsche bis hinter den See.", "The forest is full of life. Fenn smells deer all the way across the lake.")
		"sela":
			return Content.L("Beeren verderben schnell, Nüsse fast nie. Lagert im Herbst, was ihr könnt.", "Berries spoil fast, nuts almost never. Store what you can in autumn.")
		"nuri":
			return Content.L("Jeder Pass hat sein Hindernis. Manche öffnet ein Steig, andere nur eine Brücke.", "Every pass has its obstacle. Some open with a stairway, others only with a bridge.")
		"ilun":
			return Content.L("Die Geister mögen Feste. Ein Tal, das feiert, ist ein Tal, das wächst.", "The spirits like festivals. A valley that celebrates is a valley that grows.")
		"tamo":
			return Content.L("Kauf billig, verkauf teuer – und vergiss nie, wer dir geholfen hat.", "Buy cheap, sell dear – and never forget who helped you.")
	return Content.L("Die Leute sind froh, hier zu sein. Achte auf ihre Wünsche, dann bleiben sie.", "People are glad to be here. Mind their wishes and they will stay.")


static func _wrap_w(text: String, width: int, variation := "") -> Label:
	var l := UI.label(text, variation, true)
	l.custom_minimum_size.x = width
	return l


static func spirit_dialog(h: Hud) -> void:
	var w := h.game.world
	var body := UI.vbox([UI.label(Content.L("Wintersonnwende", "Winter Solstice"), "Title"),
		_wrap_w(Content.L("In der längsten Nacht antwortet ein Geist. Wen bittest du, ein Jahr lang über deinen Stamm zu wachen?", "In the longest night a spirit answers. Whom do you ask to watch over your tribe for a year?"), 520)], 8)
	for sp in Content.spirits:
		var b := UI.button(Content.tx(sp.name), func():
			h.game.command({"type": "spirit", "spirit": sp.id}, "build")
			h.close_dialog(), "Small")
		body.add_child(UI.hbox([b, _wrap_w(Content.tx(sp.desc), 300, "Muted")], 10))
	h.dialog.add_child(UI.hbox([UI.icon(Art.portrait("ilun"), 150), body], 14))


static func quests(h: Hud) -> void:
	var w := h.game.world
	h.add(UI.label(Content.L("Aufgaben", "Tasks"), "Title"))
	var any := false
	for c in Content.characters:
		var qid := Story.offered(w, c.id)
		if qid != "" and Story.here(w, c.id):
			any = true
			h.add(UI.row(UI.hbox([UI.icon(Art.portrait(c.id), 36), UI.label("%s: %s" % [Content.tx(c.name), Content.tx(Content.QUEST[qid].title)])]), h.act(Content.L("Sprechen", "Talk"), func(): h.open_dialog(c.id))))
	for q in Story.active_quests(w):
		any = true
		var s: Dictionary = w.quests[q.id]
		var box := UI.vbox([UI.hbox([UI.icon(Art.portrait(q.char), 36), UI.label(Content.tx(q.title), "Heading")])], 1)
		for i in q.goals.size():
			var p := Story.progress(w, q, i, s)
			var l := _wrap(("✓ " if p[0] >= p[1] else "○ ") + goal_text(w, q, i), "Muted")
			if p[0] >= p[1]:
				l.add_theme_color_override("font_color", UI.GOOD)
			box.add_child(l)
		var rl := reward_lines({}, q.reward)
		if not rl.is_empty():
			box.add_child(_wrap(Content.L("Belohnung: ", "Reward: ") + " · ".join(rl), "Muted"))
		h.add(UI.panel([box], "Dark"))
	if not any:
		h.add(_wrap(Content.L("Gerade hat niemand eine Aufgabe für dich. Wenn dein Volk wächst, kommen neue Leute ins Tal.", "Nobody has a task for you right now. As your people grow, new folk will come to the valley."), "Muted"))
	h.add(UI.label(Content.L("Die Leute im Tal", "The people of the valley"), "Heading"))
	for c in Content.characters:
		var st: String = w.chars.get(c.id, {}).get("state", "away")
		if st == "away":
			continue
		h.add(UI.row(UI.hbox([UI.icon(Art.portrait(c.id), 32), UI.label("%s, %s" % [Content.tx(c.name), Content.tx(c.title)])]), UI.label(Content.L("unterwegs …", "on the way …") if st == "arriving" else "", "Muted")))
	var done := 0
	for q in Content.quests:
		if w.quests.get(q.id, {}).get("state", "") == "done":
			done += 1
	h.add(UI.label(Content.L("%d von %d Aufgaben erfüllt", "%d of %d tasks done") % [done, Content.quests.size()], "Muted"))


# ---------------------------------------------------------------- the Valley Heart

static func hearth(h: Hud) -> void:
	var w := h.game.world
	var v: Dictionary = w.valleys[h.game.focus] if w.valleys[h.game.focus].owner == World.PLAYER else w.home_valley()
	h.add(UI.label(Content.L("Talherz", "Valley Heart"), "Title"))
	h.add(UI.label(vname(w, v.idx), "Muted"))
	if w.hearth_of(v.idx) == null:
		h.add(_wrap(Content.L("In diesem Tal brennt noch kein Talherz. Ohne Talherz gibt es keine Feste und keine Nischen für Kostbarkeiten.", "No Valley Heart burns in this valley yet. Without one there are no festivals and no niches for treasures."), "Muted"))
	# festivals
	h.add(UI.label(Content.L("Feste", "Festivals"), "Heading"))
	if v.festival != null:
		h.add(_status_box(Content.L("Es wird gefeiert: %s (noch %d s)", "Celebrating: %s (%d s left)") % [Content.tx(Content.FESTIVAL[v.festival.id].name), ceili(v.festival.until - w.time)], true))
	var known := 0
	for f in Content.festivals:
		if not f.id in w.festivals_unlocked:
			continue
		known += 1
		var block := Life.festival_block(w, v.idx, f.id)
		var box := UI.vbox([UI.row(UI.label(Content.tx(f.name), "Heading"), h.act(Content.L("Feiern", "Celebrate"), func(): h.game.command({"type": "festival", "valley": v.idx, "festival": f.id}, "build"), "Small", not block.is_empty()))], 1)
		box.add_child(_wrap(Content.tx(f.desc), "Muted"))
		box.add_child(_cost_row(Life.festival_cost(w, v.idx, f.id)))
		if not block.is_empty():
			box.add_child(_wrap(Content.tx(block), "Muted"))
		h.add(UI.panel([box], "Dark"))
	if known == 0:
		h.add(_wrap(Content.L("Noch kennt dein Stamm keine Feste. Ama wird es dir zeigen.", "Your tribe knows no festivals yet. Ama will show you."), "Muted"))
	if w.spirit != null:
		var sp: Dictionary = Content.SPIRIT[w.spirit.id]
		h.add(_wrap(Content.L("Schutzgeist: %s – %s (noch %d s)", "Guardian spirit: %s – %s (%d s left)") % [Content.tx(sp.name), Content.tx(sp.desc), ceili(w.spirit.until - w.time)], "Muted"))
	# treasures
	h.add(UI.label(Content.L("Kostbarkeiten", "Treasures"), "Heading"))
	h.add(_wrap(Content.L("Drei Nischen im Talherz. Was hier ruht, wirkt auf das ganze Tal.", "Three niches in the Valley Heart. What rests here affects the whole valley."), "Muted"))
	for i in World.NICHES:
		var id: String = v.niches[i]
		if id != "":
			var it: Dictionary = Content.ITEM[id]
			h.add(UI.row(UI.vbox([UI.label("%d. %s" % [i + 1, Content.tx(it.name)]), _wrap(Content.tx(it.desc), "Muted")], -2), h.act(Content.L("Entnehmen", "Take out"), func(): h.game.command({"type": "remove_item", "valley": v.idx, "slot": i}))))
		else:
			var row := UI.hbox([UI.label(Content.L("%d. leer", "%d. empty") % (i + 1), "Muted")])
			if w.hearth_of(v.idx) != null:
				for it_id in w.items:
					var it: Dictionary = Content.ITEM[it_id]
					var b := h.act(Content.tx(it.name), func(): h.game.command({"type": "place_item", "item": it_id, "valley": v.idx, "slot": i}, "build"))
					b.tooltip_text = Content.tx(it.desc)
					row.add_child(b)
			h.add(row)
	# customs
	h.add(UI.label(Content.L("Bräuche (%d/%d)", "Customs (%d/%d)") % [w.customs.size(), w.custom_slots], "Heading"))
	if w.custom_slots == 0:
		h.add(_wrap(Content.L("Nach dem ersten Fest erzählt Ama von den Bräuchen.", "After the first festival Ama will tell you about customs."), "Muted"))
		return
	h.add(_wrap(Content.L("Ein Brauch gilt für den ganzen Stamm und kostet %d Ansehen. Jede neue Zeit bringt einen weiteren Platz.", "A custom applies to the whole tribe and costs %d prestige. Every new age brings another slot.") % Life.CUSTOM_COST, "Muted"))
	for cu in Content.customs:
		var on: bool = cu.id in w.customs
		var b := h.act(Content.L("Aufgeben", "Drop") if on else Content.L("Annehmen", "Adopt"), func(): h.game.command({"type": "custom", "custom": cu.id, "on": not on}), "Active" if on else "Small",
			not on and (w.customs.size() >= w.custom_slots or w.prestige() < Life.CUSTOM_COST))
		h.add(UI.row(UI.vbox([UI.label(Content.tx(cu.name)), _wrap(Content.tx(cu.desc), "Muted")], -2), b))
