class_name Hud
extends CanvasLayer
## In-game HUD in the Talherz layout: season card and quests top-left, resources top-right, place card
## bottom-left, round action buttons bottom-right, build bar bottom-centre, detail panels on the right
## and character dialogs in the middle.

var game: Game
var panel := "" # "", "building", "population", "chains", "valleys", "caravans", "trade", "hearth", "quests"
var root := Control.new()
var season_card := PanelContainer.new()
var left := VBoxContainer.new()
var quest_box := VBoxContainer.new()
var toasts := VBoxContainer.new()
var res_card := PanelContainer.new()
var place := PanelContainer.new()
var actions := HBoxContainer.new()
var build := PanelContainer.new()
var build_open := true
var right := PanelContainer.new()
var right_body := VBoxContainer.new()
var dialog := PanelContainer.new()
var dialog_char := ""
var tab := 0
var fresh := {} # buildings unlocked but not yet tried
var _seen_note := 0
var _tier_count := 0
var _won_shown := false
var _t_top := 0.0
var _t_panel := 0.0
var _item_buttons: Array[Button] = []


func setup(g: Game) -> void:
	game = g
	layer = 10
	root.theme = UI.build_theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	left.position = Vector2(12, 12)
	left.add_theme_constant_override("separation", 8)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(season_card)
	quest_box.add_theme_constant_override("separation", 6)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(quest_box)
	toasts.add_theme_constant_override("separation", 6)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(toasts)
	root.add_child(left)

	root.add_child(res_card)

	place.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	place.grow_vertical = Control.GROW_DIRECTION_BEGIN
	place.custom_minimum_size.x = 300
	root.add_child(place)

	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	build.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	build.grow_horizontal = Control.GROW_DIRECTION_BOTH
	build.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(build)

	right.custom_minimum_size = Vector2(380, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(360, 0)
	right_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_body.add_theme_constant_override("separation", 5)
	scroll.add_child(right_body)
	right.add_child(scroll)
	right.visible = false
	root.add_child(right)

	dialog.visible = false
	root.add_child(dialog)

	_seen_note = game.world.next_note - 1
	_tier_count = game.world.unlocked_tiers.size()
	render_top()
	refresh_buildbar()
	_render_actions()
	_render_quests()
	_render_place()


func _process(delta: float) -> void:
	var w := game.world
	for n in w.notifications:
		if n.id <= _seen_note:
			continue
		_seen_note = n.id
		_on_note(n)
	if w.unlocked_tiers.size() != _tier_count:
		_tier_count = w.unlocked_tiers.size()
		Sfx.play("tier")
		refresh_buildbar()
		get_parent().get_parent().show_tier_card(w.unlocked_tiers[-1])
	if w.won and not _won_shown:
		_won_shown = true
		get_parent().get_parent().show_victory()
	if w.flags.get("choose_spirit", false) and dialog_char != "@spirit":
		open_spirit_choice()
	_t_top += delta
	_t_panel += delta
	if _t_top > 0.5:
		_t_top = 0.0
		render_top()
		_render_quests()
		_render_place()
		if dialog.visible and dialog_char != "" and not dialog.get_global_rect().has_point(dialog.get_global_mouse_position()):
			render_dialog()
	if panel != "" and _t_panel > 1.0 and not right.get_global_rect().has_point(right.get_global_mouse_position()):
		render_panel()
	_layout()


func _layout() -> void:
	var vs := root.get_viewport_rect().size
	res_card.position = Vector2(vs.x - res_card.size.x - 12, 12)
	place.position = Vector2(12, vs.y - place.size.y - 12)
	actions.position = Vector2(vs.x - actions.size.x - 14, vs.y - actions.size.y - 14)
	# centred, but never over the place card on the left or past the right edge
	var bx := maxf((vs.x - build.size.x) / 2.0, place.position.x + place.size.x + 12.0)
	build.position = Vector2(minf(bx, vs.x - build.size.x - 12.0), vs.y - build.size.y - 96)
	right.get_child(0).custom_minimum_size.y = minf(right_body.get_combined_minimum_size().y + 4, vs.y - res_card.size.y - 130)
	right.position = Vector2(vs.x - right.size.x - 12, res_card.size.y + 22)
	dialog.position = Vector2((vs.x - dialog.size.x) / 2.0, maxf(20.0, (vs.y - dialog.size.y) / 2.0 - 40.0))


func _on_note(n: Dictionary) -> void:
	match n.kind:
		"tier":
			return
		"unlock":
			fresh[n.building] = true
			Sfx.play("tier")
			var t := Content.tier_index(Content.BUILDING[n.building].unlockTier)
			if game.tool.kind == "select" and t >= 0:
				tab = t
			refresh_buildbar()
			toast(Content.tx(n.text), "good", 6.0, "", n.building)
		"quest_done":
			Sfx.play("tier")
			toast(Content.tx(n.text), "good", 11.0, n.get("char", ""))
		"quest":
			toast(Content.tx(n.text), "quest", 8.0, n.get("char", ""))
		"crisis":
			Sfx.play("error")
			toast(Content.tx(n.text), "warn", 10.0)
		_:
			toast(Content.tx(n.text), n.kind, 7.0, n.get("char", ""))


# ---------------------------------------------------------------- season card, resources

func render_top() -> void:
	var w := game.world
	UI.clear(season_card)
	var s := w.season()
	var icon := UI.Glyph.new(["sprout", "sun", "leaf", "snow"][s], 40)
	var name := UI.label(Content.season_name(s), "Heading")
	var sub := UI.label("%s %d" % [Content.L("Jahr", "Year"), w.year()], "Muted")
	var prog := UI.bar(w.season_progress(), false, 120)
	prog.tooltip_text = Content.L("Fortschritt der Jahreszeit. Ein Jahr dauert 10 Minuten.", "Progress of the season. A year lasts 10 minutes.")
	var speeds := UI.hbox([], 2)
	for sp in [0, 1, 2, 4]:
		var active: bool = game.paused if sp == 0 else (not game.paused and game.speed == sp)
		var b := Button.new()
		b.theme_type_variation = "Active" if active else "Small"
		b.custom_minimum_size = Vector2(34, 30)
		var gl := UI.Glyph.new({0: "pause", 1: "play", 2: "fast", 4: "faster"}[sp], 20)
		gl.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.add_child(gl)
		b.tooltip_text = Content.L("Pause (Leertaste)", "Pause (Space)") if sp == 0 else "%s %dx" % [Content.L("Tempo", "Speed"), sp]
		b.pressed.connect(func():
			Sfx.play("click")
			if sp == 0:
				game.paused = not game.paused
			else:
				game.paused = false
				game.speed = sp
			render_top())
		speeds.add_child(b)
	var tip: String = [Content.L("Frühling: Wild bekommt Junge, mehr Zuzug, Felder wachsen an.", "Spring: game has young, more newcomers, fields sprout."),
		Content.L("Sommer: alles arbeitet normal.", "Summer: everything works normally."),
		Content.L("Herbst: Sammler und Ernte +50 %, Jagd +25 % – Vorräte anlegen!", "Autumn: gatherers and harvest +50%, hunting +25% – lay in stores!"),
		Content.L("Winter: Sammler und Felder ruhen, jedes Haus braucht Feuerholz, Pässe auf Gletschern sind zu.", "Winter: gatherers and fields rest, every home needs firewood, glacier passes are shut.")][s]
	var box := UI.hbox([icon, UI.vbox([UI.hbox([name, sub], 8), prog], -2), speeds], 10)
	box.tooltip_text = tip
	season_card.tooltip_text = tip
	season_card.add_child(box)

	UI.clear(res_card)
	var pop := w.player_population()
	var net := w.income - w.upkeep
	var row := UI.hbox([], 14)
	var shells := UI.hbox([UI.icon(Art.tex("ui/shell"), 26), UI.label("%d" % floori(w.shells)), UI.label("%+d" % roundi(net), "Muted")], 3)
	shells.get_child(2).add_theme_color_override("font_color", UI.GOOD if net >= 0 else UI.BAD)
	shells.tooltip_text = Content.L("Muscheln – die Währung der Täler.\nEinnahmen %d/min, Unterhalt %d/min", "Shells – the currency of the valleys.\nIncome %d/min, upkeep %d/min") % [roundi(w.income), roundi(w.upkeep)]
	shells.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(shells)
	var pres := UI.hbox([UI.Glyph.new("prestige", 24), UI.label(str(w.prestige()))], 3)
	pres.tooltip_text = Content.L("Ansehen – durch Feste, Aufgaben und glückliche Bewohner. Du brauchst es, um neue Täler zu gründen (nächstes: %d) und Bräuche anzunehmen (%d).", "Prestige – from festivals, quests and happy residents. You need it to found new valleys (next: %d) and to adopt customs (%d).") % [w.found_cost(), Life.CUSTOM_COST]
	pres.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(pres)
	var people := UI.hbox([UI.Glyph.new("people", 24), UI.label(str(w.total_population()))], 3)
	var ptip := []
	for t in Content.tiers:
		if w.tier_unlocked(t.id):
			ptip.append("%s: %d" % [Content.tx(t.name), pop[t.id]])
	people.tooltip_text = "\n".join(ptip)
	people.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(people)
	var v: Dictionary = w.valleys[game.focus] if w.valleys[game.focus].owner == World.PLAYER else w.home_valley()
	var mood: float = v.get("mood", 50.0)
	var mg := UI.Glyph.new("mood", 24, _mood_color(mood))
	var moodbox := UI.hbox([mg, UI.label(str(roundi(mood)))], 3)
	moodbox.tooltip_text = Content.L("Stimmung im Tal (0–100). Unter 30 zieht niemand zu, unter 15 gehen Leute. Über 70 mehr Zuzug, Einnahmen und Ansehen.", "Mood in the valley (0–100). Below 30 nobody moves in, below 15 people leave. Above 70 more newcomers, income and prestige.")
	moodbox.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(moodbox)
	var food := UI.hbox([UI.Glyph.new("food", 24), UI.label(str(floori(w.food_stock(v.idx))))], 3)
	food.tooltip_text = Content.L("Nahrung im Lager dieses Tals (alle Lebensmittel).", "Food in this valley's storage (all foodstuffs).")
	food.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(food)
	for g in ["wood", "stone", "hides", "tools", "bricks"]:
		var n: float = v.storage.get(g, 0.0)
		if n < 0.5 and not (g == "wood" or (g == "stone" and w.is_unlocked("stonegatherer"))):
			continue
		var cell := UI.hbox([UI.good_icon(g, 26), UI.label(str(floori(n)))], 2)
		if g == "wood" and w.is_winter() and v.get("freezing", false):
			cell.get_child(1).add_theme_color_override("font_color", UI.BAD)
		row.add_child(cell)
	res_card.add_child(row)


static func _mood_color(m: float) -> Color:
	if m < 30.0:
		return UI.BAD
	if m > 70.0:
		return UI.GOOD
	return Color("b08a3a")


# ---------------------------------------------------------------- round action buttons

func _render_actions() -> void:
	UI.clear(actions)
	for e in [["build", Content.L("Bauen", "Build"), ""], ["hearth", Content.L("Talherz", "Valley Heart"), "H"], ["quests", Content.L("Aufgaben", "Tasks"), "J"],
			["population", Content.L("Volk", "People"), "B"], ["chains", Content.L("Ketten", "Chains"), "C"], ["valleys", Content.L("Täler", "Valleys"), "M"],
			["caravans", Content.L("Karawanen", "Caravans"), "K"], ["trade", Content.L("Handel", "Trade"), "T"], ["menu", Content.L("Menü", "Menu"), "Esc"]]:
		var kind: String = e[0]
		var active := (kind == "build" and build_open) or panel == kind
		var b := _round(kind, "%s (%s)" % [e[1], e[2]] if e[2] != "" else e[1], active)
		b.pressed.connect(func():
			Sfx.play("click")
			match kind:
				"build":
					build_open = not build_open
					build.visible = build_open
				"menu":
					get_parent().get_parent().open_pause()
				_:
					toggle_panel(kind)
			_render_actions())
		actions.add_child(b)


func _round(kind: String, tip: String, active: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 58)
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("f1e2c0") if not active else Color("e2b866")
		if state == "hover":
			sb.bg_color = sb.bg_color.lightened(0.12)
		if state == "pressed":
			sb.bg_color = sb.bg_color.darkened(0.1)
		sb.border_color = Color("8a6a46")
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(29)
		sb.shadow_color = Color(0.2, 0.12, 0.05, 0.35)
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 2)
		b.add_theme_stylebox_override(state, sb)
	var g := UI.Glyph.new({"population": "people"}.get(kind, kind), 34, Color("5a3a22"))
	g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.offset_left = 12
	g.offset_top = 12
	g.offset_right = -12
	g.offset_bottom = -12
	b.add_child(g)
	return b


# ---------------------------------------------------------------- build bar

func refresh_buildbar() -> void:
	var w := game.world
	UI.clear(build)
	build.visible = build_open
	var tabs := HBoxContainer.new()
	var names := []
	for t in Content.tiers:
		names.append(Content.tx(t.name))
	names.append(Content.L("Wege & Erkundung", "Paths & Scouting"))
	for i in names.size():
		var locked := i < Content.tiers.size() and not w.tier_unlocked(Content.tiers[i].id)
		var b := UI.button(names[i], func():
			tab = i
			refresh_buildbar(), "Active" if i == tab else "Small")
		b.modulate.a = 0.45 if locked else 1.0
		if locked:
			b.tooltip_text = Content.L("Diese Zeit liegt noch vor euch – Ama weiß, was es dafür braucht.", "This age still lies ahead – Ama knows what it takes.")
		tabs.add_child(b)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 6)
	_item_buttons.clear()
	if tab == 0 or tab == Content.tiers.size():
		items.add_child(_tool_button(Content.L("Pfad", "Path") + "\n(P)", "path", Content.L("Trampelpfad ziehen: klicken und ziehen. Verbindet Häuser und Betriebe mit dem Lagerplatz. 2 Muscheln pro Feld.", "Drag a footpath: click and drag. Connects homes and workplaces to the storage yard. 2 shells per tile.")))
		items.add_child(_tool_button(Content.L("Abreißen", "Demolish") + "\n(X)", "demolish", Content.L("Gebäude oder Pfade entfernen. Die Hälfte der Kosten kommt zurück.", "Remove buildings or paths. Half of the cost is refunded.")))
	var list := []
	for def in Content.buildings:
		if not def.get("buildable", true) or def.style == "path":
			continue
		if tab < Content.tiers.size():
			if def.unlockTier == Content.tiers[tab].id and def.category != "infrastructure":
				list.append(def)
		elif def.category == "infrastructure":
			list.append(def)
	# the Valley Heart first, then homes, then what is unlocked, then what is still locked
	list.sort_custom(func(a, b):
		var ka: int = (0 if a.id == "hearth" else (1 if a.category == "residence" else 2)) + (0 if w.is_unlocked(a.id) else 10)
		var kb: int = (0 if b.id == "hearth" else (1 if b.category == "residence" else 2)) + (0 if w.is_unlocked(b.id) else 10)
		return ka < kb)
	for def in list:
		var unlocked := w.is_unlocked(def.id)
		var b := Hud.TipButton.new()
		b.theme_type_variation = "Item"
		b.custom_minimum_size = Vector2(74, 74)
		b.icon = Art.building_icon(def.id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.tooltip_text = Content.tx(def.name)
		b.tip_builder = func(): return _building_tip(def)
		if not unlocked:
			b.modulate = Color(0.55, 0.52, 0.5, 0.75)
		elif game.tool.kind == "build" and game.tool.building == def.id:
			b.modulate = Color(1.2, 1.1, 0.75)
		if unlocked and fresh.has(def.id):
			var dot := Label.new()
			dot.text = Content.L("neu", "new")
			dot.add_theme_color_override("font_color", Color("fbf0d6"))
			dot.add_theme_font_size_override("font_size", 12)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("c0602e")
			sb.set_corner_radius_all(6)
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			dot.add_theme_stylebox_override("normal", sb)
			dot.position = Vector2(2, 2)
			b.add_child(dot)
		b.pressed.connect(func():
			Sfx.play("click")
			if not unlocked:
				flash(Content.tx(Content.BUILDING[def.id].name) + " – " + Content.tx(Story.unlock_hint(w, def.id)))
				return
			fresh.erase(def.id)
			if game.tool.kind == "build" and game.tool.building == def.id:
				game.set_tool({"kind": "select"})
			else:
				game.set_tool({"kind": "build", "building": def.id}))
		items.add_child(b)
		_item_buttons.append(b)
	build.add_child(UI.vbox([tabs, items], 6))


func _tool_button(text: String, kind: String, tip: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = "Item"
	b.text = text
	b.custom_minimum_size = Vector2(74, 74)
	b.add_theme_font_size_override("font_size", 20)
	b.tooltip_text = tip
	if game.tool.kind == kind:
		b.modulate = Color(1.2, 1.1, 0.75)
	b.pressed.connect(func():
		Sfx.play("click")
		game.set_tool({"kind": "select"} if game.tool.kind == kind else {"kind": kind}))
	return b


func _building_tip(def: Dictionary) -> Control:
	var w := game.world
	var box := UI.vbox([UI.label(Content.tx(def.name), "Heading")])
	var desc := UI.label(Content.tx(def.desc), "", true)
	desc.custom_minimum_size.x = 300
	box.add_child(desc)
	if not w.is_unlocked(def.id):
		var req := UI.label(Content.L("Gesperrt: ", "Locked: ") + Content.tx(Story.unlock_hint(w, def.id)), "", true)
		req.custom_minimum_size.x = 300
		req.add_theme_color_override("font_color", UI.BAD)
		box.add_child(req)
	if def.has("outputs"):
		var flow := UI.hbox([])
		for g in def.get("inputs", {}):
			flow.add_child(UI.good_icon(g, 26))
		if def.has("inputs"):
			flow.add_child(UI.label("→"))
		for g in def.outputs:
			flow.add_child(UI.good_icon(g, 26))
		flow.add_child(UI.label("  %ds" % int(def.cycle), "Muted"))
		box.add_child(flow)
	if def.has("workforce"):
		box.add_child(UI.label("%s: %d %s" % [Content.L("Arbeiter", "Workers"), int(def.workforce.amount), Content.tx(Content.TIER[def.workforce.tier].name)], "Muted"))
	if def.has("service"):
		box.add_child(UI.label("%s: %d" % [Content.L("Reichweite", "Radius"), int(def.service.radius)], "Muted"))
	if def.has("beauty"):
		box.add_child(UI.label(Content.L("Schönheit +%d im Umkreis %d", "Beauty +%d within %d") % [int(def.beauty.value), int(def.beauty.radius)], "Muted"))
	if def.has("noise"):
		box.add_child(UI.label(Content.L("Lärm und Gestank: Stimmung −%d im Umkreis %d", "Noise and stench: mood −%d within %d") % [int(def.noise.value), int(def.noise.radius)], "Muted"))
	var group: String = def.get("group", "")
	if Economy.SEASON.has(group):
		var f: Array = Economy.SEASON[group]
		box.add_child(UI.label(Content.L("Jahreszeiten: Frühling %d %% · Sommer %d %% · Herbst %d %% · Winter %d %%", "Seasons: spring %d%% · summer %d%% · autumn %d%% · winter %d%%") % [roundi(f[0] * 100), roundi(f[1] * 100), roundi(f[2] * 100), roundi(f[3] * 100)], "Muted"))
	var req2: Dictionary = def.get("requires", {})
	if req2.has("fertility"):
		box.add_child(UI.label("%s: %s" % [Content.L("Fruchtbarkeit", "Fertility"), Content.tx(Content.FERTILITY[req2.fertility].name)], "Muted"))
	if req2.has("deposit"):
		box.add_child(UI.label("%s: %s" % [Content.L("Vorkommen", "Deposit"), req2.deposit], "Muted"))
	var cost := UI.hbox([])
	for k in def.cost:
		cost.add_child(UI.icon(Art.tex("ui/shell"), 20) if k == "shells" else UI.good_icon(k, 22))
		cost.add_child(UI.label(str(int(def.cost[k]))))
	if def.upkeep > 0:
		cost.add_child(UI.label("  %s %d/min" % [Content.L("Unterhalt", "Upkeep"), int(def.upkeep)], "Muted"))
	box.add_child(cost)
	return box


# ---------------------------------------------------------------- toasts, quests, place card

func flash(text: String) -> void:
	toast(text, "warn", 3.5)


func toast(text: String, kind: String, seconds := 7.0, who := "", building := "") -> void:
	var l := UI.label(text, "", true)
	l.custom_minimum_size.x = 250 if who != "" or building != "" else 290
	if kind == "warn":
		l.add_theme_color_override("font_color", UI.BAD)
	elif kind == "good":
		l.add_theme_color_override("font_color", UI.GOOD)
	var row := UI.hbox([l], 6)
	if who != "":
		row.add_child(UI.icon(Art.portrait(who), 44))
		row.move_child(row.get_child(1), 0)
	elif building != "":
		row.add_child(UI.icon(Art.building_icon(building), 44))
		row.move_child(row.get_child(1), 0)
	var p := UI.panel([row])
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_child(p)
	toasts.move_child(p, 0)
	while toasts.get_child_count() > 4:
		var last := toasts.get_child(toasts.get_child_count() - 1)
		toasts.remove_child(last)
		last.queue_free()
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)


func _render_quests() -> void:
	var w := game.world
	UI.clear(quest_box)
	# people who have something for you: one card, or a row of faces when several are waiting
	var offers := []
	for c in Content.characters:
		if Story.here(w, c.id) and Story.offered(w, c.id) != "":
			offers.append(c)
	if offers.size() == 1:
		var c: Dictionary = offers[0]
		var qid := Story.offered(w, c.id)
		var q: Dictionary = Content.QUEST[qid]
		var choose: bool = w.quests[qid].state == "choose"
		var head := UI.label(("%s: " % Content.tx(c.name)) + (Content.L("Wähle deine Belohnung!", "Choose your reward!") if choose else Content.L("Neue Aufgabe!", "New task!")), "")
		head.add_theme_color_override("font_color", UI.OCHRE_DARK)
		var t := UI.label(Content.tx(q.title), "Heading")
		t.add_theme_font_size_override("font_size", 22)
		var card := _clickable_card(UI.hbox([_bang(), UI.icon(Art.portrait(c.id), 48), UI.vbox([head, t], -4)], 6), func(): open_dialog(c.id))
		quest_box.add_child(card)
	elif offers.size() > 1:
		var row := UI.hbox([_bang()], 4)
		for c in offers:
			var q: Dictionary = Content.QUEST[Story.offered(w, c.id)]
			var face := _face(c.id, 50, func(): open_dialog(c.id))
			face.tooltip_text = "%s: %s" % [Content.tx(c.name), Content.tx(q.title)]
			row.add_child(face)
		var head := UI.label(Content.L("%d Leute haben Aufgaben für dich", "%d people have tasks for you") % offers.size(), "Muted")
		quest_box.add_child(UI.panel([UI.vbox([head, row], 0)]))
	# tracked quests
	var act := Story.active_quests(w)
	for i in mini(3, act.size()):
		var q: Dictionary = act[i]
		var s: Dictionary = w.quests[q.id]
		var lines := UI.vbox([], -2)
		var title := UI.label(Content.tx(q.title), "Heading")
		title.add_theme_font_size_override("font_size", 22)
		lines.add_child(title)
		for gi in q.goals.size():
			var p := Story.progress(w, q, gi, s)
			var done: bool = p[0] >= p[1]
			var l := UI.label(("✓ " if done else "○ ") + HudPanels.goal_text(w, q, gi), "", true)
			l.custom_minimum_size.x = 230
			l.add_theme_font_size_override("font_size", 14)
			if done:
				l.add_theme_color_override("font_color", UI.GOOD)
			lines.add_child(l)
		var card := _clickable_card(UI.hbox([UI.icon(Art.portrait(q.char), 40), lines], 6), func(): open_panel("quests"))
		quest_box.add_child(card)
	if act.size() > 3:
		quest_box.add_child(_clickable_card(UI.label(Content.L("+%d weitere Aufgaben …", "+%d more tasks …") % (act.size() - 3), "Muted"), func(): open_panel("quests")))
	# crises that a click can avert
	for e in w.events:
		if e.state != "active" or not Events.CRISES.has(e.kind):
			continue
		var c: Dictionary = Events.CRISES[e.kind]
		var line := UI.label("%s – %s" % [Content.tx(c.name), HudPanels.vname(w, e.valley)], "Heading")
		line.add_theme_color_override("font_color", UI.BAD)
		line.add_theme_font_size_override("font_size", 22)
		var box := UI.vbox([line], 2)
		var left_s := maxf(0.0, e.until - w.time)
		box.add_child(UI.label(Content.L("noch %d s", "%d s left") % ceili(left_s), "Muted"))
		if not c.fix.is_empty():
			var fixes := UI.hbox([], 4)
			for fix in c.fix:
				var txt := []
				for g in fix:
					txt.append("%d %s" % [int(fix[g]), Content.tx(Content.GOOD[g].name)])
				fixes.add_child(act_button(Content.L("Abwenden: ", "Avert: ") + ", ".join(txt), func(): game.command({"type": "resolve_event", "id": e.id}, "build")))
			box.add_child(fixes)
		var p := UI.panel([box])
		quest_box.add_child(p)
	if not w.items.is_empty():
		quest_box.add_child(_clickable_card(UI.label(Content.L("✶ %d Kostbarkeit(en) warten auf eine Nische im Talherz", "✶ %d treasure(s) waiting for a niche in the Valley Heart") % w.items.size(), "", true), func(): open_panel("hearth")))


func act_button(text: String, cb: Callable) -> Button:
	var b := UI.button(text, cb, "Small")
	b.add_theme_font_size_override("font_size", 17)
	return b


func _bang() -> Control:
	var l := UI.label("!", "Title")
	l.add_theme_color_override("font_color", Color("e8a13a"))
	l.add_theme_color_override("font_outline_color", UI.INK)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_font_size_override("font_size", 42)
	return l


## A character's portrait on a round parchment disc that reacts to clicks.
func _face(id: String, px: int, cb: Callable) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f1e2c0")
	sb.border_color = Color("8a6a46")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(px / 2 + 4)
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UI.icon(Art.portrait(id), px))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Sfx.play("click")
			cb.call())
	return p


func _clickable_card(content: Control, cb: Callable) -> PanelContainer:
	var p := UI.panel([content])
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Sfx.play("click")
			cb.call())
	return p


## Bottom-left: the selected building in short, otherwise the valley under the camera.
func _render_place() -> void:
	var w := game.world
	UI.clear(place)
	if game.selected != 0 and w.buildings.has(game.selected):
		place.add_child(HudPanels.place_building(self, w.buildings[game.selected]))
		return
	var v: Dictionary = w.valleys[game.focus]
	var vdef := Content.valley_def(v.def)
	var cap := w.storage_cap(v.idx)
	var owner_text := ""
	if v.owner == World.PLAYER:
		owner_text = "%s %d" % [Content.L("Lager", "Storage"), cap]
	elif v.owner != null:
		owner_text = Content.tx(Content.RIVAL[v.owner].name)
	else:
		owner_text = Content.L("unbesiedelt", "unsettled")
	var box := UI.vbox([UI.row(UI.label(Content.tx(vdef.name), "Heading"), UI.label(owner_text, "Muted"))])
	var chips := HFlowContainer.new()
	for f in v.fertilities:
		chips.add_child(_chip(Content.tx(Content.FERTILITY[f].name), Color(Content.FERTILITY[f].color)))
	var deps := {}
	for i in w.deposit:
		if w.valley[i] == v.idx:
			deps[w.deposit[i]] = true
	for d in deps:
		var good: String = {"copper": "copperore"}.get(d, d)
		chips.add_child(_chip("⛏ " + (Content.tx(Content.GOOD[good].name) if Content.GOOD.has(good) else d), Color("8a8a8a")))
	box.add_child(chips)
	if v.owner == World.PLAYER:
		var stats := UI.hbox([], 10)
		stats.add_child(UI.label("%s %d %%" % [Content.L("Wild", "Game"), roundi(v.game * 100)], "Muted"))
		if v.fertilities.has("fish"):
			stats.add_child(UI.label("%s %d %%" % [Content.L("Fisch", "Fish"), roundi(v.fish * 100)], "Muted"))
		if v.festival != null:
			stats.add_child(UI.label("♪ " + Content.tx(Content.FESTIVAL[v.festival.id].name), "Muted"))
		box.add_child(stats)
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 6)
		var spoil: Dictionary = v.get("spoil", {})
		for g in Content.goods:
			var n: float = v.storage.get(g.id, 0.0)
			if n < 0.5:
				continue
			var cell := UI.vbox([UI.good_icon(g.id, 32), UI.label(str(floori(n)))], 0)
			cell.get_child(1).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.get_child(1).add_theme_font_size_override("font_size", 13)
			if n >= cap:
				cell.get_child(1).add_theme_color_override("font_color", UI.BAD)
			var tip := "%s: %d / %d" % [Content.tx(g.name), floori(n), cap]
			if spoil.get(g.id, 0.0) > 0.05:
				tip += "\n" + Content.L("verdirbt: −%.1f/min", "spoils: −%.1f/min") % spoil[g.id]
			cell.tooltip_text = tip
			cell.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_child(cell)
		box.add_child(grid if grid.get_child_count() > 0 else UI.label(Content.L("Das Lager ist leer.", "The storage is empty."), "Muted"))
	else:
		var l := UI.label(Content.L("Fremdes Tal", "Foreign valley") if v.owner != null else Content.L("Gründe hier einen Lagerplatz, um das Tal zu besiedeln (kostet %d Ansehen).", "Found a storage yard here to settle the valley (costs %d prestige).") % w.found_cost(), "Muted", true)
		l.custom_minimum_size.x = 270
		box.add_child(l)
	place.add_child(box)


func _chip(text: String, color: Color) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f6ecd2")
	sb.border_color = color.darkened(0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	p.add_theme_stylebox_override("panel", sb)
	var l := UI.label(text)
	l.add_theme_font_size_override("font_size", 12)
	p.add_child(l)
	return p


# ---------------------------------------------------------------- character dialog

func open_dialog(char_id: String) -> void:
	dialog_char = char_id
	dialog.visible = true
	render_dialog()


func close_dialog() -> void:
	dialog.visible = false
	dialog_char = ""


func render_dialog() -> void:
	UI.clear(dialog)
	if dialog_char == "@spirit":
		HudPanels.spirit_dialog(self)
	else:
		HudPanels.character_dialog(self, dialog_char)


func open_spirit_choice() -> void:
	dialog_char = "@spirit"
	dialog.visible = true
	render_dialog()


# ---------------------------------------------------------------- right panels

func toggle_panel(p: String) -> void:
	open_panel("" if panel == p else p)


func open_panel(p: String) -> void:
	panel = p
	if p != "building":
		game.selected = 0
	right.visible = p != ""
	_render_actions()
	if p != "":
		render_panel()


func render_panel() -> void:
	_t_panel = 0.0
	UI.clear(right_body)
	var close := Button.new()
	close.theme_type_variation = "Small"
	close.custom_minimum_size = Vector2(34, 30)
	var x := UI.Glyph.new("close", 18)
	x.set_anchors_preset(Control.PRESET_FULL_RECT)
	close.add_child(x)
	close.pressed.connect(func(): open_panel(""))
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_body.add_child(close)
	match panel:
		"building":
			if not game.world.buildings.has(game.selected):
				open_panel("")
				return
			HudPanels.building(self, game.world.buildings[game.selected])
		"population":
			HudPanels.population(self)
		"valleys":
			HudPanels.valleys(self)
		"trade":
			HudPanels.trade(self)
		"caravans":
			HudPanels.caravans(self)
		"chains":
			HudPanels.chains(self)
		"hearth":
			HudPanels.hearth(self)
		"quests":
			HudPanels.quests(self)


func add(c: Control) -> void:
	right_body.add_child(c)


func act(text: String, cb: Callable, variation := "Small", disabled := false) -> Button:
	var b := UI.button(text, func():
		cb.call()
		render_panel()
		_render_quests(), variation)
	b.disabled = disabled
	return b


# ---------------------------------------------------------------- keys

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var main = get_parent().get_parent()
	match k.physical_keycode:
		KEY_ESCAPE:
			if dialog.visible and dialog_char != "@spirit":
				close_dialog()
			elif game.tool.kind != "select":
				game.set_tool({"kind": "select"})
			elif panel != "":
				open_panel("")
			else:
				main.open_pause()
		KEY_SPACE:
			game.paused = not game.paused
			render_top()
		KEY_P:
			game.set_tool({"kind": "select"} if game.tool.kind == "path" else {"kind": "path"})
		KEY_X, KEY_DELETE:
			game.set_tool({"kind": "select"} if game.tool.kind == "demolish" else {"kind": "demolish"})
		KEY_M:
			toggle_panel("valleys")
		KEY_B:
			toggle_panel("population")
		KEY_T:
			toggle_panel("trade")
		KEY_K:
			toggle_panel("caravans")
		KEY_C:
			toggle_panel("chains")
		KEY_J:
			toggle_panel("quests")
		KEY_H:
			toggle_panel("hearth")
		KEY_TAB:
			tab = (tab + 1) % (Content.tiers.size() + 1)
			refresh_buildbar()
		KEY_F5:
			if Saves.save("quicksave", Content.L("Schnellspeicherung", "Quicksave"), game.world):
				toast(Content.L("Gespeichert.", "Saved."), "good", 2.0)
		_:
			if k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_9:
				var n: int = k.physical_keycode - KEY_1
				if n < _item_buttons.size():
					_item_buttons[n].pressed.emit()
	get_viewport().set_input_as_handled()


## Button whose tooltip is a rich control.
class TipButton extends Button:
	var tip_builder: Callable

	func _make_custom_tooltip(_for_text: String) -> Object:
		return tip_builder.call() if tip_builder.is_valid() else null
