extends Node
## Dev tool: the quest-following bot plays a fresh game; prints the state every minute and when each
## age arrives, to check the pacing against the concept (age 2 after ~45–60 min).
## godot --headless --path . res://tools/balance.tscn -- [--minutes=90] [--seed=42] [--mode=talherz]


func _ready() -> void:
	var minutes := 70
	var seed_value := 42
	var mode := "talherz"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.substr(10))
		if a.begins_with("--seed="):
			seed_value = int(a.substr(7))
		if a.begins_with("--mode="):
			mode = a.substr(7)
	var w := World.create(seed_value, mode)
	var home: int = w.home_valley().idx
	var log := []
	var seen := 0
	for minute in minutes:
		Bot.play(w, 1, log)
		var v: Dictionary = w.valleys[home]
		var pop := w.player_population()
		var quests := []
		for q in Story.active_quests(w):
			quests.append(q.id)
		var houses := w.buildings.values().filter(func(b): return b.owner == World.PLAYER and b.has("tier")).size()
		print("min %2d %s  pop %-40s mood %3d  food %4d  wood %3d  shells %6d  ansehen %3d  houses %2d  tasks %s" % [
			minute + 1, ["Fr", "So", "He", "Wi"][w.season()], _pop(pop), v.mood, w.food_stock(home), v.storage.get("wood", 0.0),
			w.shells, w.prestige(), houses, quests])
		for n in w.notifications:
			if n.id > seen and n.kind in ["quest_done", "tier", "crisis", "warning"]:
				print("        · %s" % n.text.de)
		seen = w.next_note - 1
		for e in log:
			print("   >>> %s nach %.1f min" % [e.get("tier", "Sieg"), e.t / 60.0])
		log.clear()
		if w.won:
			break
	# where it stands at the end: storage, buildings and every open goal
	var v: Dictionary = w.valleys[home]
	print("storage ", v.storage)
	var counts := {}
	for b in w.buildings.values():
		if b.owner == World.PLAYER:
			counts[b.type] = counts.get(b.type, 0) + 1
	print("buildings ", counts)
	var status := {}
	for b in w.buildings.values():
		if b.owner == World.PLAYER and Content.BUILDING[b.type].category == "production":
			status["%s:%s" % [b.type, b.status]] = status.get("%s:%s" % [b.type, b.status], 0) + 1
	print("status ", status)
	for q in Story.active_quests(w):
		for gi in q.goals.size():
			print("  %s goal %d %s -> %s" % [q.id, gi, q.goals[gi], Story.progress(w, q, gi, w.quests[q.id])])
	get_tree().quit()


func _pop(pop: Dictionary) -> String:
	var parts := []
	for t in Content.tiers:
		if pop.get(t.id, 0) > 0:
			parts.append("%s %d" % [t.id.substr(0, 3), pop[t.id]])
	return ", ".join(parts)
