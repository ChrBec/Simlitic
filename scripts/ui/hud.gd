class_name Hud
extends CanvasLayer
## In-game HUD: top bar, build bar, objectives, notifications, storage and the right-hand panels.

var game: Game
var panel := "" # "", "building", "population", "valleys", "trade"
var root := Control.new()
var top := PanelContainer.new()
var top_row := HBoxContainer.new()
var build := PanelContainer.new()
var left := VBoxContainer.new()
var objective := PanelContainer.new()
var toasts := VBoxContainer.new()
var storage := PanelContainer.new()
var right := PanelContainer.new()
var right_body := VBoxContainer.new()
var tab := 0
var _seen_note := 0
var _tier_count := 0
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

	top.theme_type_variation = "Leather"
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size.y = 58
	top_row.add_theme_constant_override("separation", 16)
	top.add_child(top_row)
	root.add_child(top)

	build.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	build.grow_horizontal = Control.GROW_DIRECTION_BOTH
	build.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build.position.y -= 10
	root.add_child(build)

	left.position = Vector2(12, 70)
	left.custom_minimum_size.x = 310
	left.add_theme_constant_override("separation", 8)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective.custom_minimum_size.x = 310
	left.add_child(objective)
	toasts.add_theme_constant_override("separation", 6)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(toasts)
	root.add_child(left)

	storage.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	storage.grow_vertical = Control.GROW_DIRECTION_BEGIN
	storage.position = Vector2(12, -12)
	storage.custom_minimum_size.x = 310
	root.add_child(storage)

	right.custom_minimum_size = Vector2(370, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(350, 0)
	right_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_body.add_theme_constant_override("separation", 5)
	scroll.add_child(right_body)
	right.add_child(scroll)
	right.visible = false
	root.add_child(right)

	_seen_note = game.world.next_note - 1
	_tier_count = game.world.unlocked_tiers.size()
	render_top()
	refresh_buildbar()
	_render_objective()
	_render_storage()


func _process(delta: float) -> void:
	var w := game.world
	for n in w.notifications:
		if n.id <= _seen_note:
			continue
		_seen_note = n.id
		if n.kind != "tier":
			toast(Content.tx(n.text), n.kind)
	if w.unlocked_tiers.size() != _tier_count:
		_tier_count = w.unlocked_tiers.size()
		Sfx.play("tier")
		refresh_buildbar()
		get_parent().get_parent().show_tier_card(w.unlocked_tiers[-1])
	_t_top += delta
	_t_panel += delta
	if _t_top > 0.5:
		_t_top = 0.0
		render_top()
		_render_objective()
		_render_storage()
	if panel != "" and _t_panel > 1.0 and not right.get_global_rect().has_point(right.get_global_mouse_position()):
		render_panel()
	# keep the right panel inside the screen
	var vs := root.get_viewport_rect().size
	right.get_child(0).custom_minimum_size.y = minf(right_body.get_combined_minimum_size().y + 4, vs.y - 110)
	right.position = Vector2(vs.x - right.size.x - 12, 70)


# ---------------------------------------------------------------- top bar

func render_top() -> void:
	var w := game.world
	UI.clear(top_row)
	var pop := w.player_population()
	var net := w.income - w.upkeep
	var top_tier := 0
	for t in w.unlocked_tiers:
		top_tier = maxi(top_tier, Content.tier_index(t))
	var title := UI.vbox([UI.label("SimLitic", "LeatherLabel"), UI.label(Content.tx(Content.tiers[top_tier].age), "LeatherLabel")], -6)
	title.get_child(0).add_theme_font_override("font", UI.font_display)
	title.get_child(0).add_theme_font_size_override("font_size", 30)
	title.get_child(1).add_theme_font_size_override("font_size", 13)
	top_row.add_child(title)
	var shells := UI.hbox([UI.icon(Art.tex("ui/shell"), 26), UI.label("%d" % floori(w.shells), "LeatherLabel"), UI.label(("%+d/min" % roundi(net)), "LeatherLabel")])
	shells.get_child(2).add_theme_color_override("font_color", Color("b8e08a") if net >= 0 else Color("ffaa8a"))
	shells.get_child(2).add_theme_font_size_override("font_size", 14)
	shells.tooltip_text = Content.L("Muscheln – die Währung der Täler.\nEinnahmen %d/min, Unterhalt %d/min", "Shells – the currency of the valleys.\nIncome %d/min, upkeep %d/min") % [roundi(w.income), roundi(w.upkeep)]
	top_row.add_child(shells)
	var pres := UI.label("✶ %d" % w.prestige(), "LeatherLabel")
	pres.tooltip_text = Content.L("Ansehen – wächst mit Bevölkerung, Tälern und Zeitalter.", "Prestige – grows with population, valleys and age.")
	pres.mouse_filter = Control.MOUSE_FILTER_PASS
	top_row.add_child(pres)
	for t in Content.tiers:
		if not w.tier_unlocked(t.id):
			continue
		var dot := ColorRect.new()
		dot.color = Color(t.color)
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var tp := UI.hbox([dot, UI.label(str(pop[t.id]), "LeatherLabel")], 4)
		tp.tooltip_text = Content.tx(t.name)
		top_row.add_child(tp)
	top_row.add_child(UI.spacer())
	var year := floori(w.time / 480.0) + 1
	var season: String = [Content.L("Frühling", "Spring"), Content.L("Sommer", "Summer"), Content.L("Herbst", "Autumn"), Content.L("Winter", "Winter")][floori(fmod(w.time, 480.0) / 120.0)]
	top_row.add_child(UI.label("%s %d · %s" % [Content.L("Jahr", "Year"), year, season], "LeatherLabel"))
	for sp in [0, 1, 2, 4]:
		var label: String = {0: "II", 1: ">", 2: ">>", 4: ">>>"}[sp]
		var active: bool = game.paused if sp == 0 else (not game.paused and game.speed == sp)
		var b := UI.button(label, func():
			if sp == 0:
				game.paused = not game.paused
			else:
				game.paused = false
				game.speed = sp
			render_top(), "Active" if active else "Small")
		b.custom_minimum_size = Vector2(44, 34)
		b.tooltip_text = Content.L("Pause (Leertaste)", "Pause (Space)") if sp == 0 else "%s %dx" % [Content.L("Tempo", "Speed"), sp]
		top_row.add_child(b)
	for entry in [["population", Content.L("Volk", "People"), "B"], ["valleys", Content.L("Täler", "Valleys"), "M"], ["trade", Content.L("Handel", "Trade"), "T"]]:
		var b := UI.button(entry[1], func(): toggle_panel(entry[0]), "Active" if panel == entry[0] else "Small")
		b.tooltip_text = "%s (%s)" % [entry[1], entry[2]]
		top_row.add_child(b)
	top_row.add_child(UI.button(Content.L("Menü", "Menu"), func(): get_parent().get_parent().open_pause(), "Small"))


# ---------------------------------------------------------------- build bar

func refresh_buildbar() -> void:
	var w := game.world
	UI.clear(build)
	var tabs := HBoxContainer.new()
	var names := []
	for t in Content.tiers:
		names.append(Content.tx(t.name))
	names.append(Content.L("Wege & Werkzeuge", "Paths & Tools"))
	for i in names.size():
		var locked := i < Content.tiers.size() and not w.tier_unlocked(Content.tiers[i].id)
		var b := UI.button(names[i], func():
			tab = i
			refresh_buildbar(), "Active" if i == tab else "Small")
		b.modulate.a = 0.5 if locked else 1.0
		tabs.add_child(b)
	var items := HBoxContainer.new()
	items.add_theme_constant_override("separation", 6)
	_item_buttons.clear()
	if tab == 0 or tab == Content.tiers.size():
		items.add_child(_tool_button(Content.L("Pfad", "Path") + "\n(P)", "path", Content.L("Trampelpfad ziehen: klicken und ziehen. Verbindet Häuser und Betriebe mit dem Lagerplatz. 2 Muscheln pro Feld.", "Drag a footpath: click and drag. Connects homes and workplaces to the storage yard. 2 shells per tile.")))
		items.add_child(_tool_button(Content.L("Abreißen", "Demolish") + "\n(X)", "demolish", Content.L("Gebäude oder Pfade entfernen. Die Hälfte der Kosten kommt zurück.", "Remove buildings or paths. Half of the cost is refunded.")))
	var list := []
	for def in Content.buildings:
		if tab < Content.tiers.size():
			if def.unlockTier == Content.tiers[tab].id and def.get("buildable", true) and def.category != "infrastructure":
				list.append(def)
		elif def.category == "infrastructure" and def.id != "path":
			list.append(def)
	for def in list:
		var unlocked := w.tier_unlocked(def.unlockTier)
		var b := TipButton.new()
		b.theme_type_variation = "Item"
		b.custom_minimum_size = Vector2(76, 76)
		b.icon = Art.building_icon(def.id)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.tooltip_text = Content.tx(def.name)
		b.tip_builder = func(): return _building_tip(def)
		b.disabled = not unlocked
		if game.tool.kind == "build" and game.tool.building == def.id:
			b.modulate = Color(1.2, 1.1, 0.75)
		b.pressed.connect(func():
			Sfx.play("click")
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
	b.custom_minimum_size = Vector2(76, 76)
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
	if not w.tier_unlocked(def.unlockTier):
		var req := UI.label(Content.L("Benötigt: ", "Requires: ") + Content.tx(Content.TIER[def.unlockTier].name))
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
	var req: Dictionary = def.get("requires", {})
	if req.has("fertility"):
		box.add_child(UI.label("%s: %s" % [Content.L("Fruchtbarkeit", "Fertility"), Content.tx(Content.FERTILITY[req.fertility].name)], "Muted"))
	if req.has("deposit"):
		box.add_child(UI.label("%s: %s" % [Content.L("Vorkommen", "Deposit"), req.deposit], "Muted"))
	var cost := UI.hbox([])
	for k in def.cost:
		cost.add_child(UI.icon(Art.tex("ui/shell"), 20) if k == "shells" else UI.good_icon(k, 22))
		cost.add_child(UI.label(str(int(def.cost[k]))))
	if def.upkeep > 0:
		cost.add_child(UI.label("  %s %d/min" % [Content.L("Unterhalt", "Upkeep"), int(def.upkeep)], "Muted"))
	box.add_child(cost)
	return box


# ---------------------------------------------------------------- toasts, objective, storage

func flash(text: String) -> void:
	toast(text, "warn", 2.5)


func toast(text: String, kind: String, seconds := 7.0) -> void:
	var l := UI.label(text, "", true)
	l.custom_minimum_size.x = 280
	var p := UI.panel([l])
	if kind == "warn":
		l.add_theme_color_override("font_color", UI.BAD)
	elif kind == "good":
		l.add_theme_color_override("font_color", UI.GOOD)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_child(p)
	toasts.move_child(p, 0)
	while toasts.get_child_count() > 5:
		toasts.get_child(toasts.get_child_count() - 1).queue_free()
		toasts.remove_child(toasts.get_child(toasts.get_child_count() - 1))
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)


func _render_objective() -> void:
	var id := Objectives.current(game.world)
	objective.visible = Settings.data.tutorial_hints and id != ""
	if not objective.visible:
		return
	UI.clear(objective)
	var l := UI.label(Content.tx(Objectives.TEXT[id]), "", true)
	l.custom_minimum_size.x = 280
	var head := UI.label(Content.L("Nächstes Ziel", "Next objective"), "Heading")
	head.add_theme_color_override("font_color", UI.OCHRE_DARK)
	objective.add_child(UI.vbox([head, l], 0))


func _render_storage() -> void:
	var w := game.world
	var v: Dictionary = w.valleys[game.focus]
	var vdef := Content.valley_def(v.def)
	UI.clear(storage)
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
		chips.add_child(_chip("⛏ " + {"flint": Content.L("Feuerstein", "Flint"), "copper": Content.L("Kupfer", "Copper"), "tin": Content.L("Zinn", "Tin")}.get(d, d), Color("8a8a8a")))
	box.add_child(chips)
	if v.owner == World.PLAYER:
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 6)
		for g in Content.goods:
			var n: float = v.storage.get(g.id, 0.0)
			if n < 0.5:
				continue
			var cell := UI.vbox([UI.good_icon(g.id, 34), UI.label(str(floori(n)))], 0)
			cell.get_child(1).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.get_child(1).add_theme_font_size_override("font_size", 13)
			if n >= cap:
				cell.get_child(1).add_theme_color_override("font_color", UI.BAD)
			cell.tooltip_text = "%s: %d / %d" % [Content.tx(g.name), floori(n), cap]
			cell.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_child(cell)
		box.add_child(grid if grid.get_child_count() > 0 else UI.label(Content.L("Das Lager ist leer.", "The storage is empty."), "Muted"))
	else:
		var l := UI.label(Content.L("Fremdes Tal", "Foreign valley") if v.owner != null else Content.L("Gründe hier einen Lagerplatz, um das Tal zu besiedeln.", "Found a storage yard here to settle the valley."), "Muted", true)
		l.custom_minimum_size.x = 280
		box.add_child(l)
	storage.add_child(box)


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


# ---------------------------------------------------------------- right panels

func toggle_panel(p: String) -> void:
	open_panel("" if panel == p else p)


func open_panel(p: String) -> void:
	panel = p
	if p != "building":
		game.selected = 0
	right.visible = p != ""
	render_top()
	if p != "":
		render_panel()


func render_panel() -> void:
	_t_panel = 0.0
	UI.clear(right_body)
	var close := UI.button("✕", func(): open_panel(""), "Small")
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


func add(c: Control) -> void:
	right_body.add_child(c)


func act(text: String, cb: Callable, variation := "Small", disabled := false) -> Button:
	var b := UI.button(text, func():
		cb.call()
		render_panel(), variation)
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
			if game.tool.kind != "select":
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
		KEY_H:
			var v := game.world.home_valley()
			game.view.center_on(v.cx, v.cy)
		KEY_TAB:
			tab = (tab + 1) % (Content.tiers.size() + 1)
			refresh_buildbar()
		KEY_F5:
			if Saves.save("quicksave", Content.L("Schnellspeicherung", "Quicksave"), game.world):
				toast(Content.L("Gespeichert.", "Saved."), "good", 2.0)
		_:
			if k.physical_keycode >= KEY_1 and k.physical_keycode <= KEY_9:
				var n: int = k.physical_keycode - KEY_1
				if n < _item_buttons.size() and not _item_buttons[n].disabled:
					_item_buttons[n].pressed.emit()
	get_viewport().set_input_as_handled()


## Button whose tooltip is a rich control.
class TipButton extends Button:
	var tip_builder: Callable

	func _make_custom_tooltip(_for_text: String) -> Object:
		return tip_builder.call() if tip_builder.is_valid() else null
