extends Node
## Application root: main menu with a living backdrop, game sessions, overlays and menus.

var game: Game
var backdrop: Game
var menu_layer := CanvasLayer.new()
var menu_root := Control.new()
var _was_paused := false
var _t := 0.0


func _ready() -> void:
	# Merged into the engine default theme so it also reaches CanvasLayers and tooltip popups.
	var theme := UI.build_theme()
	ThemeDB.get_default_theme().merge_with(theme)
	ThemeDB.fallback_font = UI.font_body
	get_tree().root.theme = theme
	get_tree().set_auto_accept_quit(true)
	await IconBaker.bake(self)
	_build_finish_layer()
	menu_layer.layer = 20
	add_child(menu_layer)
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(menu_root)
	Settings.changed.connect(_on_settings_changed)
	var args := OS.get_cmdline_user_args()
	if "--new-game" in args:
		start_new(42, "talherz")
	elif "--demo" in args:
		_start(demo_world(7))
	else:
		show_main_menu()
	for a in args:
		if a.begins_with("--panel=") and game and game.hud:
			if a.substr(8) == "building":
				# the first home: shows needs, mood and the upgrade section
				for b in game.world.buildings.values():
					if b.owner == World.PLAYER and b.has("tier"):
						game.selected = b.id
						break
			game.hud.open_panel(a.substr(8))
		if a.begins_with("--zoom=") and game:
			game.view.set_zoom(a.substr(7).to_float())
		if a.begins_with("--yaw=") and game:
			game.view.yaw = deg_to_rad(a.substr(6).to_float())
			game.view.set_zoom(game.view.zoom)
		if a == "--winter" and game:
			game.world.time = World.SEASON_LENGTH * 3.0 + 5.0
			game.world.last_season = World.WINTER
			game.view._winter = 1.0
		if a.begins_with("--focus=") and game:
			for v in game.world.valleys:
				if v.def == a.substr(8):
					game.view.center_on(v.cx, v.cy)
		if a.begins_with("--pass=") and game:
			# look at the first discovered pass with this obstacle
			for p in game.world.passes:
				if p.discovered and p.obstacle == a.substr(7):
					game.view.center_on(p.mid % game.world.size, p.mid / game.world.size)
					break
		if a.begins_with("--menu="):
			match a.substr(7):
				"new": show_new_game()
				"load": show_load()
				"save": show_save()
				"pause": open_pause()
				"settings": show_settings(show_main_menu)
				"credits": show_credits()
				"tier": show_tier_card("sedentary")
				"victory": show_victory()
				"dialog":
					if game and game.hud:
						game.hud.open_dialog("ama")
		if a.begins_with("--shot="):
			_screenshot_and_quit(a.substr(7))


## Debug helper for docs and CI: `godot -- --shot=out.png [--new-game]`.
func _screenshot_and_quit(path: String) -> void:
	await get_tree().create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


## Soft vignette over the world.
func _build_finish_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var vignette := TextureRect.new()
	var grad := GradientTexture2D.new()
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(1.05, 1.05)
	var g := Gradient.new()
	g.set_color(0, Color(0.24, 0.16, 0.08, 0.0))
	g.set_color(1, Color(0.24, 0.16, 0.08, 0.45))
	g.add_point(0.55, Color(0.24, 0.16, 0.08, 0.0))
	grad.gradient = g
	vignette.texture = grad
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vignette)


func _process(delta: float) -> void:
	_t += delta
	if backdrop and backdrop.view:
		# slow drift over the living village behind the main menu
		var home := backdrop.world.home_valley()
		backdrop.view.yaw = deg_to_rad(45.0) + sin(_t * 0.03) * 0.5
		backdrop.view.center_on(home.cx + sin(_t * 0.05) * 5.0, home.cy + cos(_t * 0.04) * 4.0)


# ---------------------------------------------------------------- sessions

func _make_backdrop() -> void:
	if backdrop:
		return
	var w := demo_world(7)
	backdrop = Game.new()
	add_child(backdrop)
	backdrop.start(w, false)
	backdrop.view.interactive = false
	backdrop.view.show_markers = false
	backdrop.view.set_zoom(1.15)


## A settled village around the Talherz with a colony and a porter caravan, built by the bot.
## Used for the menu backdrop, screenshots and `--demo`.
static func demo_world(seed_value: int) -> World:
	var w := World.create(seed_value, "talherz")
	var home: int = w.home_valley().idx
	w.shells = 100000
	w.prestige_pts = 60.0
	w.flags.trade = true
	if not w.tier_unlocked("sedentary"):
		w.unlocked_tiers.append("sedentary")
	for b in Content.buildings:
		if b.unlockTier in w.unlocked_tiers:
			w.unlocked[b.id] = true
	for id in ["ama", "borr", "sela", "nuri", "oro"]:
		w.chars[id].state = "here"
	w.valleys[home].storage = {"wood": 600.0, "hides": 80.0, "stone": 80.0, "tools": 40.0, "berries": 60.0, "meat": 40.0}
	Bot.lay_roads(w, home)
	Bot.build_near(w, home, "hearth", 3)
	for i in 16:
		Bot.build_near(w, home, "tent")
	for t in ["fireplace", "fireplace", "gardenbed", "gardenbed", "gardenbed", "totempost"]:
		Bot.build_near(w, home, t)
	for t in ["berrygatherer", "woodcutter", "woodcutter", "nutgatherer", "hunter", "trapper", "stonegatherer", "storagepit", "smokehouse"]:
		Bot.build_near(w, home, t, 5)
	Bot.run_minutes(w, 3)
	for t in ["fisher", "graingatherer", "grinder", "tanner", "toolmaker"]:
		Bot.build_near(w, home, t, 5)
	for t in ["shaman", "ancestors", "scout"]:
		Bot.build_near(w, home, t)
	# a few families have already settled down in pit houses
	var n := 0
	for b in w.buildings.values():
		if b.type == "tent" and b.owner == World.PLAYER and n < 6:
			b.type = "hut"
			b.tier = "sedentary"
			b.needs = {}
			n += 1
	w.dirty += 1
	# reveal the neighbouring valleys and found the flint gorge
	for p in w.passes:
		if p.a == home or p.b == home:
			p.discovered = true
			w.valleys[p.b if p.a == home else p.a].discovered = true
	w.pass_ver += 1
	var flint := -1
	for v in w.valleys:
		if v.def == "flint":
			flint = v.idx
	var fv: Dictionary = w.valleys[flint]
	var spot := w.find_free_spot(flint, 3, 3, fv.cx, fv.cy)
	var founded := Commands.apply(w, {"type": "build", "building": "storage", "x": spot.x, "y": spot.y})
	if not founded.ok:
		push_warning("demo: could not found the flint gorge: %s" % founded.reason.en)
		return w
	fv.storage.wood = 60.0
	Bot.lay_roads(w, flint, 8)
	Bot.build_near(w, flint, "flintquarry")
	Bot.build_near_pass(w, home, "caravanpost")
	var car: Dictionary = Commands.apply(w, {"type": "buy_caravan", "valley": home, "caravan": "porters"})
	if car.ok:
		Commands.apply(w, {"type": "caravan_stops", "id": car.id, "stops": [
			{"v": home, "load": ["wood"], "unload": ["flint"]}, {"v": flint, "load": ["flint"], "unload": ["wood"]}]})
	Bot.run_minutes(w, 2)
	return w


func _clear_backdrop() -> void:
	if backdrop:
		backdrop.queue_free()
		backdrop = null


func start_new(seed_value: int, difficulty: String) -> void:
	_start(World.create(seed_value, difficulty))


func _start(w: World) -> void:
	_clear_backdrop()
	if game:
		game.queue_free()
	game = Game.new()
	add_child(game)
	game.start(w)
	close_menu()


func load_slot(slot: String) -> void:
	var w := Saves.load_world(slot)
	if w == null:
		return
	_start(w)


func to_main_menu() -> void:
	if game:
		game.queue_free()
		game = null
	show_main_menu()


func _on_settings_changed() -> void:
	if game and game.hud:
		game.hud.render_top()
		game.hud.refresh_buildbar()


# ---------------------------------------------------------------- menus

func close_menu() -> void:
	UI.clear(menu_root)
	if game:
		game.paused = _was_paused
		game.view.interactive = true


func _screen(content: Control, dim := true) -> void:
	UI.clear(menu_root)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.08, 0.04, 0.55 if dim else 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(center)
	center.add_child(content)


func show_main_menu() -> void:
	_make_backdrop()
	UI.clear(menu_root)
	var title := UI.label("Talherz", "Title")
	title.add_theme_font_size_override("font_size", 150)
	title.add_theme_color_override("font_color", Color("fbf0d6"))
	title.add_theme_color_override("font_outline_color", UI.INK)
	title.add_theme_constant_override("outline_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := UI.label(Content.L("Täler der Ersten", "Valleys of the First"), "Title")
	sub.add_theme_font_size_override("font_size", 44)
	sub.add_theme_color_override("font_color", Color("f5e3bc"))
	sub.add_theme_color_override("font_outline_color", UI.INK)
	sub.add_theme_constant_override("outline_size", 8)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var buttons := []
	var saves := Saves.list()
	if not saves.is_empty():
		buttons.append(UI.button(Content.L("Fortsetzen", "Continue"), func(): load_slot(saves[0].slot)))
	buttons.append(UI.button(Content.L("Neue Partie", "New Game"), show_new_game))
	buttons.append(UI.button(Content.L("Laden", "Load"), show_load))
	var mp := UI.button(Content.L("Mehrspieler", "Multiplayer"), func(): pass)
	mp.disabled = true
	mp.tooltip_text = Content.L("Kommt mit der Steam-Anbindung (Lockstep über Steam Networking).", "Coming with the Steam integration (lockstep over Steam Networking).")
	buttons.append(mp)
	buttons.append(UI.button(Content.L("Einstellungen", "Settings"), func(): show_settings(show_main_menu)))
	buttons.append(UI.button(Content.L("Mitwirkende", "Credits"), show_credits))
	buttons.append(UI.button(Content.L("Beenden", "Quit"), func(): get_tree().quit()))
	for b in buttons:
		b.custom_minimum_size = Vector2(300, 52)
		b.add_theme_font_size_override("font_size", 30)
	var panel := UI.panel([UI.vbox(buttons, 8)])
	var col := UI.vbox([title, sub, _gap(30), _centered(panel)], -10)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(center)
	center.add_child(col)
	var version := UI.label("v" + str(ProjectSettings.get_setting("application/config/version")) + " · " + Content.L("Alpha", "Alpha"), "LeatherLabel")
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position = Vector2(-200, -36)
	menu_root.add_child(version)


func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


const PRESETS := [
	["lagerfeuer", "Lagerfeuer", "Campfire", "Viel Zuzug, wenig Verderb, selten Krisen. Zum Kennenlernen.", "Many newcomers, little spoilage, rare crises. For getting to know the game."],
	["talherz", "Talherz", "Valley Heart", "Das Spiel, wie es gedacht ist: Winter, Verderb und Krisen fordern Vorausplanung.", "The game as intended: winters, spoilage and crises demand foresight."],
	["bergwinter", "Bergwinter", "Mountain Winter", "Knappe Vorräte, häufigere Krisen, stärkere Nachbarn.", "Scarce stores, more frequent crises, stronger neighbours."],
	["eiszeit", "Eiszeit", "Ice Age", "Für Kenner: wenig Zuzug, rascher Verderb, harte Winter.", "For veterans: few newcomers, fast spoilage, hard winters."],
	["sandbox", "Sandkasten", "Sandbox", "Alles freigeschaltet, keine Krisen, keine Geschichte – freies Bauen.", "Everything unlocked, no crises, no story – free building."],
]


func show_new_game() -> void:
	var seed_edit := LineEdit.new()
	seed_edit.text = str(randi() % 1000000)
	seed_edit.custom_minimum_size.x = 160
	var diff := OptionButton.new()
	for p in PRESETS:
		diff.add_item(Content.L(p[1], p[2]))
	diff.select(1)
	var desc := _wrap(Content.L(PRESETS[1][3], PRESETS[1][4]), 440, "Muted")
	diff.item_selected.connect(func(i): desc.text = Content.L(PRESETS[i][3], PRESETS[i][4]))
	var hints := CheckBox.new()
	hints.text = Content.L("Hinweise der Figuren anzeigen", "Show the characters' hints")
	hints.button_pressed = Settings.data.tutorial_hints
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	grid.add_child(UI.label(Content.L("Weltsamen", "World seed")))
	grid.add_child(UI.hbox([seed_edit, UI.button("⟳", func(): seed_edit.text = str(randi() % 1000000), "Small")]))
	grid.add_child(UI.label(Content.L("Spielart", "Mode")))
	grid.add_child(diff)
	grid.add_child(UI.label(""))
	grid.add_child(desc)
	grid.add_child(UI.label(""))
	grid.add_child(hints)
	var start := UI.button(Content.L("Aufbrechen!", "Set out!"), func():
		Settings.set_value("tutorial_hints", hints.button_pressed)
		start_new(int(seed_edit.text) if seed_edit.text.is_valid_int() else hash(seed_edit.text), PRESETS[diff.selected][0]))
	var p := UI.panel([UI.label(Content.L("Neue Partie", "New Game"), "Title"),
		_wrap(Content.L("Eine Handvoll Sammler erreicht ein unberührtes Tal. Ama, die Älteste, entzündet das erste Feuer – das Talherz. Was daraus wird, liegt bei dir.", "A handful of foragers reach an untouched valley. Ama, the elder, lights the first fire – the valley heart. What becomes of it is up to you."), 440),
		grid, _gap(8), UI.hbox([UI.button(Content.L("Zurück", "Back"), show_main_menu, "Small"), UI.spacer(), start])])
	p.custom_minimum_size.x = 560
	_screen(p)


func _wrap(text: String, width := 420, variation := "") -> Label:
	var l := UI.label(text, variation, true)
	l.custom_minimum_size.x = width
	return l


func show_load() -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	var saves := Saves.list()
	if saves.is_empty():
		list.add_child(UI.label(Content.L("Noch keine Spielstände.", "No saved games yet."), "Muted"))
	for s in saves:
		var when := Time.get_datetime_string_from_unix_time(int(s.saved_at), true)
		var info := UI.vbox([UI.label(s.name, "Heading"), UI.label("%s · %d %s · %s" % [when, s.population, Content.L("Bewohner", "residents"), _clock(s.time)], "Muted")], -4)
		list.add_child(UI.panel([UI.hbox([info, UI.spacer(), UI.button(Content.L("Laden", "Load"), func(): load_slot(s.slot), "Small"),
			UI.button("✕", func():
				Saves.delete(s.slot)
				show_load(), "Small")])], "Dark"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var back := show_pause if game else show_main_menu
	_screen(UI.panel([UI.label(Content.L("Laden", "Load"), "Title"), scroll, UI.button(Content.L("Zurück", "Back"), back, "Small")]))


func _clock(seconds: float) -> String:
	var m := int(seconds / 60.0)
	return "%d:%02d h" % [m / 60, m % 60]


func show_save() -> void:
	var name_edit := LineEdit.new()
	name_edit.text = "%s – %s" % [Content.tx(Content.valley_def(game.world.home_valley().def).name), Time.get_date_string_from_system()]
	name_edit.custom_minimum_size.x = 360
	var list := VBoxContainer.new()
	for s in Saves.list():
		if s.slot == "autosave":
			continue
		list.add_child(UI.hbox([UI.label(s.name), UI.spacer(), UI.button(Content.L("Überschreiben", "Overwrite"), func():
			Saves.save(s.slot, s.name, game.world)
			game.hud.toast(Content.L("Gespeichert.", "Saved."), "good", 2.0)
			show_pause(), "Small")]))
	var save_new := UI.button(Content.L("Speichern", "Save"), func():
		Saves.save("save_%d" % Time.get_unix_time_from_system(), name_edit.text, game.world)
		game.hud.toast(Content.L("Gespeichert.", "Saved."), "good", 2.0)
		show_pause())
	_screen(UI.panel([UI.label(Content.L("Speichern", "Save"), "Title"), UI.hbox([name_edit, save_new]), list, UI.button(Content.L("Zurück", "Back"), show_pause, "Small")]))


func open_pause() -> void:
	if not game:
		return
	_was_paused = game.paused
	game.paused = true
	game.view.interactive = false
	show_pause()


func show_pause() -> void:
	var buttons := [
		UI.button(Content.L("Weiterspielen", "Resume"), close_menu),
		UI.button(Content.L("Speichern", "Save"), show_save),
		UI.button(Content.L("Laden", "Load"), show_load),
		UI.button(Content.L("Einstellungen", "Settings"), func(): show_settings(show_pause)),
		UI.button(Content.L("Hauptmenü", "Main menu"), to_main_menu),
		UI.button(Content.L("Beenden", "Quit"), func(): get_tree().quit()),
	]
	for b in buttons:
		b.custom_minimum_size = Vector2(280, 48)
	_screen(UI.panel([_centered(UI.label(Content.L("Pause", "Paused"), "Title")), UI.vbox(buttons, 8)]))


func show_settings(back: Callable) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	var section := func(text: String):
		grid.add_child(UI.label(text, "Heading"))
		grid.add_child(UI.label(""))
	var slider := func(text: String, key: String, lo: float, hi: float, step: float):
		var s := HSlider.new()
		s.min_value = lo
		s.max_value = hi
		s.step = step
		s.value = Settings.data[key]
		s.custom_minimum_size.x = 220
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		s.value_changed.connect(func(v): Settings.set_value(key, v))
		grid.add_child(UI.label(text))
		grid.add_child(s)
	var check := func(text: String, key: String):
		var c := CheckBox.new()
		c.button_pressed = Settings.data[key]
		c.toggled.connect(func(on): Settings.set_value(key, on))
		grid.add_child(UI.label(text))
		grid.add_child(c)
	section.call(Content.L("Grafik", "Graphics"))
	check.call(Content.L("Vollbild", "Fullscreen"), "fullscreen")
	check.call("VSync", "vsync")
	slider.call(Content.L("Oberflächen-Größe", "Interface scale"), "ui_scale", 0.75, 1.5, 0.05)
	section.call("Audio")
	slider.call(Content.L("Gesamt", "Master"), "master_volume", 0, 1, 0.05)
	slider.call(Content.L("Musik", "Music"), "music_volume", 0, 1, 0.05)
	slider.call(Content.L("Effekte", "Effects"), "sfx_volume", 0, 1, 0.05)
	slider.call(Content.L("Umgebung", "Ambience"), "ambience_volume", 0, 1, 0.05)
	section.call(Content.L("Spiel", "Game"))
	var lang := OptionButton.new()
	lang.add_item("Deutsch")
	lang.add_item("English")
	lang.select(0 if Settings.data.language == "de" else 1)
	lang.item_selected.connect(func(i):
		Settings.set_value("language", ["de", "en"][i])
		show_settings(back))
	grid.add_child(UI.label(Content.L("Sprache", "Language")))
	grid.add_child(lang)
	slider.call(Content.L("Autosave (Minuten, 0 = aus)", "Autosave (minutes, 0 = off)"), "autosave_minutes", 0, 30, 1)
	check.call(Content.L("Ziele & Hinweise", "Objectives & hints"), "tutorial_hints")
	check.call(Content.L("Am Bildschirmrand scrollen", "Edge scrolling"), "edge_scroll")
	slider.call(Content.L("Scrollgeschwindigkeit", "Scroll speed"), "scroll_speed", 0.4, 2.5, 0.1)
	check.call(Content.L("Zoom umkehren", "Invert zoom"), "invert_zoom")
	var keys := _wrap(Content.L(
		"Steuerung: WASD/Pfeile Kamera · Q/E drehen · Mausrad Zoom · Rechts/Mitte ziehen schwenken · Figuren anklicken für Aufgaben · P Pfad · X Abreißen · 1–9 Gebäude · Tab Stufe wechseln · J Aufgaben · H Talherz · M Täler · B Bevölkerung · T Handel · Leertaste Pause · F5 Schnellspeichern · Esc Menü",
		"Controls: WASD/arrows camera · Q/E rotate · wheel zoom · right/middle drag pan · click characters for tasks · P path · X demolish · 1–9 buildings · Tab switch tier · J tasks · H valley heart · M valleys · B population · T trade · Space pause · F5 quicksave · Esc menu"), 520, "Muted")
	_screen(UI.panel([UI.label(Content.L("Einstellungen", "Settings"), "Title"), grid, keys, UI.button(Content.L("Zurück", "Back"), back, "Small")]))


func show_credits() -> void:
	var text := Content.L(
		"Talherz – ein Aufbauspiel über die Neolithische Revolution.\n\nSpieldesign, Code und gemalte Platzhalter-Grafik: entstanden mit Claude Code.\nSchriften: Amatic SC und Kalam (SIL Open Font License).\nEngine: Godot 4 (MIT).\n\nAlle Grafiken und Klänge sind austauschbare Platzhalter – siehe docs/ASSETS.md.",
		"Talherz – a city builder about the Neolithic Revolution.\n\nGame design, code and painted placeholder art: made with Claude Code.\nFonts: Amatic SC and Kalam (SIL Open Font License).\nEngine: Godot 4 (MIT).\n\nAll art and sound are replaceable placeholders – see docs/ASSETS.md.")
	_screen(UI.panel([UI.label(Content.L("Mitwirkende", "Credits"), "Title"), _wrap(text, 520), UI.button(Content.L("Zurück", "Back"), show_main_menu, "Small")]))


func show_tier_card(tier_id: String) -> void:
	if not game:
		return
	var t: Dictionary = Content.TIER[tier_id]
	_was_paused = game.paused
	game.paused = true
	game.view.interactive = false
	var age := UI.label(Content.tx(t.age), "Heading")
	age.add_theme_color_override("font_color", UI.OCHRE_DARK)
	age.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var name := UI.label(Content.tx(t.name), "Title")
	name.add_theme_font_size_override("font_size", 72)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var intro := _wrap(Content.tx(t.intro), 480)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hist := _wrap(Content.tx(t.get("history", "")), 480)
	hist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hist.theme_type_variation = "Muted"
	var house := UI.icon(Art.building_icon(t.house), 150)
	var p := UI.panel([_centered(UI.label(Content.L("Eine neue Zeit beginnt", "A new age begins"), "Heading")), age, name, _centered(house), intro, _gap(4), hist, _gap(6), _centered(UI.button(Content.L("Weiter", "Continue"), close_menu))])
	_screen(p)


## Shown once when Ama's last task is done: the bronze age has come to the valleys.
func show_victory() -> void:
	if not game:
		return
	var w := game.world
	_was_paused = game.paused
	game.paused = true
	game.view.interactive = false
	var pop := w.total_population()
	var mins := int(w.time / 60.0)
	var fests := 0
	for k in w.stats.festivals:
		fests += int(w.stats.festivals[k])
	var title := UI.label(Content.L("Das Zeitalter der Bronze", "The Age of Bronze"), "Title")
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var text := _wrap(Content.L(
		"Aus einer Handvoll Sammler am ersten Feuer ist ein Volk der Täler geworden. Ama blickt über die Dächer und lächelt: „Das Talherz schlägt weiter – in jedem Tal, das ihr besiedelt habt.“",
		"A handful of foragers at the first fire have become a people of the valleys. Ama looks over the roofs and smiles: \"The valley heart beats on – in every valley you have settled.\""), 480)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var facts := _wrap(Content.L("%d Bewohner · %d Täler · %d Feste · %d Aufwertungen · %d:%02d h gespielt", "%d residents · %d valleys · %d festivals · %d upgrades · %d:%02d h played") % [
		pop, w.valleys.filter(func(v): return v.owner == World.PLAYER).size(), fests, w.stats.upgrades, mins / 60, mins % 60], 480, "Muted")
	facts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait := UI.icon(Art.portrait("ama"), 150) if Art.portrait("ama") else _gap(4)
	var p := UI.panel([_centered(portrait), title, text, _gap(4), facts, _gap(6),
		_centered(UI.hbox([UI.button(Content.L("Weiterbauen", "Keep building"), close_menu), UI.button(Content.L("Hauptmenü", "Main menu"), to_main_menu)], 12))])
	_screen(p)
