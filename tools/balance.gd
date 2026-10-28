extends Node
## Dev tool: plays a scripted village with the bot and prints the economy every minute.
## godot --headless --path . res://tools/balance.tscn


func _ready() -> void:
	var w := World.create(42)
	var home: int = w.home_valley().idx
	Bot.lay_roads(w, home, 16)
	for t in ["tent", "tent", "tent", "tent", "tent", "tent", "fireplace", "berrygatherer", "woodcutter", "hunter"]:
		Bot.build_near(w, home, t, 0.0 if t == "tent" or t == "fireplace" else 5.0)
	for minute in 30:
		Bot.run_minutes(w, 1)
		if minute == 2:
			for i in 14:
				Bot.build_near(w, home, "tent")
			for t in ["berrygatherer", "hunter", "fireplace", "nutgatherer", "woodcutter"]:
				Bot.build_near(w, home, t, 5.0)
		if minute == 8:
			for t in ["trapper", "fisher", "fisher", "graingatherer", "grinder", "grinder", "graingatherer", "tanner", "trapper", "shaman", "ancestors"]:
				Bot.build_near(w, home, t, 5.0)
		if minute == 14:
			for i in 10:
				Bot.build_near(w, home, "tent")
			for t in ["berrygatherer", "hunter", "fisher", "woodcutter"]:
				Bot.build_near(w, home, t, 5.0)
		var pop := w.player_population()
		var bal := Economy.good_balance(w)
		var short := []
		for g in bal:
			if bal[g].prod - bal[g].cons < -0.05:
				short.append("%s%.1f" % [g, bal[g].prod - bal[g].cons])
		print("min %2d  shells %6d  +%4d -%4d  pop %s  short %s" % [minute + 1, w.shells, w.income, w.upkeep, pop, short])
	get_tree().quit()
