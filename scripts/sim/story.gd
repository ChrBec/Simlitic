class_name Story
## The people of the valley and their quests. Characters arrive when their moment has come, walk in
## over the mountains and hand out quests (Anno-style). Quests unlock buildings, festivals, customs,
## treasures and – through Ama's threshold quests – the next age.

const WALK_TIME := 25.0 # seconds a newcomer needs to walk into the valley
const COMMENT_GAP := 120.0


static func setup(w: World) -> void:
	for c in Content.characters:
		w.chars[c.id] = {"state": "away", "t": 0.0}
	if w.sandbox:
		return
	w.chars.ama.state = "here"
	_offer_next(w, "ama")


static func here(w: World, id: String) -> bool:
	return w.chars.get(id, {}).get("state", "") == "here"


static func char_name(id: String) -> Dictionary:
	return Content.CHARACTER[id].name if Content.CHARACTER.has(id) else {"de": id, "en": id}


## A line spoken by a character: shown as a toast with their portrait.
static func say(w: World, who: String, text: Dictionary, kind := "info") -> void:
	var n := char_name(who)
	w.notify({"de": "%s: „%s“" % [n.de, text.de], "en": "%s: \"%s\"" % [n.en, text.en]}, kind, {"char": who})


static func tick(w: World) -> void:
	if w.sandbox:
		return
	var dt := World.TICK * 10.0
	for c in Content.characters:
		var st: Dictionary = w.chars[c.id]
		if st.state == "away" and _met(w, c.arrive, {}):
			st.state = "arriving"
			st.t = 0.0
			w.notify({"de": "Jemand kommt über die Berge: %s, %s." % [c.name.de, c.title.de], "en": "Someone is coming over the mountains: %s, %s." % [c.name.en, c.title.en]}, "info", {"char": c.id})
		elif st.state == "arriving":
			st.t += dt
			if st.t >= WALK_TIME:
				st.state = "here"
				say(w, c.id, c.greeting, "good")
	for c in Content.characters:
		if here(w, c.id):
			_offer_next(w, c.id)
	for q in Content.quests:
		var s = w.quests.get(q.id)
		if s != null and s.state == "active" and complete(w, q):
			if q.has("choices"):
				s.state = "choose"
				say(w, q.char, {"de": "Du hast alles beisammen – komm zu mir und triff deine Wahl.", "en": "You have everything – come to me and make your choice."}, "good")
			else:
				finish(w, q.id, -1)
	_pop_unlocks(w)
	if w.tick % 100 == 0:
		_comments(w)


## Offers the character's next quest once its prerequisites are met (only one open offer per person).
static func _offer_next(w: World, who: String) -> void:
	for q in Content.quests:
		if q.char != who:
			continue
		var s = w.quests.get(q.id)
		if s != null:
			if s.state == "offered" or s.state == "choose":
				return
			continue
		var ok := true
		for a in q.after:
			if w.quests.get(a, {}).get("state", "") != "done":
				ok = false
		if ok and _met_all(w, q.when, {}):
			w.quests[q.id] = {"state": "offered", "base": {}, "ok": {}}
			say(w, who, {"de": "Ich habe eine Aufgabe für dich – „%s“." % q.title.de, "en": "I have a task for you – \"%s\"." % q.title.en}, "quest")
		return


static func offered(w: World, who: String) -> String:
	for q in Content.quests:
		if q.char == who and w.quests.get(q.id, {}).get("state", "") in ["offered", "choose"]:
			return q.id
	return ""


static func active_quests(w: World) -> Array:
	var out := []
	for q in Content.quests:
		if w.quests.get(q.id, {}).get("state", "") in ["active", "choose"]:
			out.append(q)
	return out


static func accept(w: World, qid: String) -> Dictionary:
	var s = w.quests.get(qid)
	if s == null or s.state != "offered":
		return {"ok": false, "reason": {"de": "Diese Aufgabe ist nicht offen", "en": "This task is not open"}}
	var q: Dictionary = Content.QUEST[qid]
	s.state = "active"
	s.t = w.time
	for g in q.goals:
		match g.type:
			"produce":
				s.base[g.good] = w.stats.produced.get(g.good, 0.0)
			"festival":
				s.base[g.festival] = w.stats.festivals.get(g.festival, 0)
			"find":
				_spawn_find(w, g.what)
			"survive":
				if w.cold == null and not w.flags.get("cold_survived", false):
					w.cold = {"state": "pending", "pop": 0}
	for b in q.unlock:
		_unlock(w, b, false)
	for f in q.get("festivals", []):
		if not f in w.festivals_unlocked:
			w.festivals_unlocked.append(f)
	for f in q.get("flags", []):
		w.flags[f] = true
	return {"ok": true}


## Does the quest's every goal hold right now?
static func complete(w: World, q: Dictionary) -> bool:
	var s: Dictionary = w.quests[q.id]
	for i in q.goals.size():
		var p := progress(w, q, i, s)
		if p[0] < p[1]:
			return false
	return true


## [have, need] for goal i of a quest.
static func progress(w: World, q: Dictionary, i: int, s: Dictionary) -> Array:
	var g: Dictionary = q.goals[i]
	if g.type == "winter_food":
		return [1 if s.ok.get(str(i), false) else 0, 1]
	return [_value(w, g, s), float(g.get("n", 1))]


static func _value(w: World, g: Dictionary, s: Dictionary) -> float:
	var home := w.home_valley()
	match g.type:
		"build":
			return w.count(g.building, true)
		"houses":
			var n := 0
			for b in w.buildings.values():
				if b.owner == World.PLAYER and b.get("tier", "") == g.tier:
					n += 1
			return n
		"pop":
			return w.player_population().get(g.tier, 0) if g.has("tier") else w.total_population()
		"stock", "deliver":
			return floorf(home.storage.get(g.good, 0.0))
		"produce":
			return floorf(w.stats.produced.get(g.good, 0.0) - s.get("base", {}).get(g.good, 0.0))
		"served":
			var n := 0
			for id in w.coverage:
				if w.coverage[id].has(g.service):
					n += 1
			return n
		"festival":
			return w.stats.festivals.get(g.festival, 0) - s.get("base", {}).get(g.festival, 0)
		"find":
			for f in w.finds:
				if f.id == g.what and f.found:
					return 1
			return 0
		"explore":
			return w.passes.filter(func(p): return p.discovered).size()
		"valleys":
			return w.valleys.filter(func(v): return v.owner == World.PLAYER).size()
		"contact":
			return w.rivals.filter(func(r): return r.contacted).size()
		"caravan":
			return w.caravans.filter(func(c): return c.stops.size() >= 2).size()
		"custom":
			return w.customs.size()
		"game":
			return floorf(home.game * 100.0)
		"survive":
			return 1 if w.flags.get("cold_survived", false) else 0
		"tier":
			return 1 if w.tier_unlocked(g.tier) else 0
	return 0


static func _met(w: World, g: Dictionary, s: Dictionary) -> bool:
	match g.type:
		"start":
			return true
		"pop":
			return (w.player_population().get(g.tier, 0) if g.has("tier") else w.total_population()) >= int(g.n)
	return _value(w, g, s) >= float(g.get("n", 1))


static func _met_all(w: World, goals: Array, s: Dictionary) -> bool:
	for g in goals:
		if not _met(w, g, s):
			return false
	return true


## Hands in a quest: deliveries leave the storage, rewards arrive.
static func finish(w: World, qid: String, choice: int) -> void:
	var q: Dictionary = Content.QUEST[qid]
	var s: Dictionary = w.quests[qid]
	var home := w.home_valley()
	for g in q.goals:
		if g.type == "deliver":
			home.storage[g.good] = maxf(0.0, home.storage.get(g.good, 0.0) - float(g.n))
	s.state = "done"
	var reward: Dictionary = q.reward.duplicate(true)
	if choice >= 0 and q.has("choices"):
		reward.merge(q.choices[choice].reward, true)
	w.notify({"de": "%s: „%s“" % [char_name(q.char).de, q.done.de], "en": "%s: \"%s\"" % [char_name(q.char).en, q.done.en]}, "quest_done", {"char": q.char, "quest": qid})
	give(w, reward)


static func give(w: World, r: Dictionary) -> void:
	if r.has("shells"):
		w.shells += float(r.shells)
	if r.has("prestige"):
		w.prestige_pts += float(r.prestige)
	for b in r.get("unlock", []):
		_unlock(w, b, true)
	for it in r.get("items", []):
		w.items.append(it)
		var d: Dictionary = Content.ITEM[it]
		w.notify({"de": "Neue Kostbarkeit: %s – lege sie in eine Nische des Talherzens. (%s)" % [d.name.de, d.desc.de], "en": "New treasure: %s – place it in a niche of the Valley Heart. (%s)" % [d.name.en, d.desc.en]}, "good", {"item": it})
	if r.has("customs"):
		w.custom_slots += int(r.customs)
		w.notify({"de": "Bräuche: Am Talherz kannst du jetzt einen Brauch annehmen.", "en": "Customs: you can now adopt a custom at the Valley Heart."}, "good")
	if r.has("tier") and not w.tier_unlocked(r.tier):
		w.unlocked_tiers.append(r.tier)
		if w.custom_slots > 0:
			w.custom_slots += 1
		var t: Dictionary = Content.TIER[r.tier]
		w.notify({"de": "Eine neue Zeit beginnt: %s. Häuser lassen sich jetzt aufwerten." % t.name.de, "en": "A new age begins: %s. Homes can now be upgraded." % t.name.en}, "tier")
	if r.get("win", false):
		w.won = true
		w.notify({"de": "Das große Talherz-Fest! Du hast deinen Stamm von den Wildbeutern bis in die Bronzezeit geführt.", "en": "The great Valley Heart feast! You led your tribe from foragers to the Bronze Age."}, "tier")


static func _unlock(w: World, b: String, loud: bool) -> void:
	if w.unlocked.has(b):
		return
	w.unlocked[b] = true
	if loud or true:
		var name: Dictionary = Content.BUILDING[b].name
		w.notify({"de": "Neu freigeschaltet: %s" % name.de, "en": "Newly unlocked: %s" % name.en}, "unlock", {"building": b})


## Buildings that open at population marks of their tier (Anno's "at 20 farmers …").
static func _pop_unlocks(w: World) -> void:
	var pop := w.player_population()
	for b in Content.buildings:
		var u: Dictionary = b.get("unlock", {})
		if not u.has("pop") or w.unlocked.has(b.id):
			continue
		var tier: String = u.pop[0]
		if w.tier_unlocked(tier) and pop.get(tier, 0) >= int(u.pop[1]):
			_unlock(w, b.id, true)


## Why a building is still locked, for tooltips and the placement check.
static func unlock_hint(w: World, type: String) -> Dictionary:
	var u: Dictionary = Content.BUILDING[type].get("unlock", {})
	if u.has("pop"):
		var t: Dictionary = Content.TIER[u.pop[0]]
		if not w.tier_unlocked(u.pop[0]):
			return {"de": "Ab der Stufe %s (bei %d Bewohnern)" % [t.name.de, int(u.pop[1])], "en": "From the %s age (at %d residents)" % [t.name.en, int(u.pop[1])]}
		return {"de": "Ab %d %s" % [int(u.pop[1]), t.name.de], "en": "At %d %s" % [int(u.pop[1]), t.name.en]}
	if u.has("quest"):
		var q: Dictionary = Content.QUEST[u.quest]
		var c: Dictionary = Content.CHARACTER[q.char]
		return {"de": "%s, %s, zeigt es dir („%s“)" % [c.name.de, c.title.de, q.title.de], "en": "%s, %s, will show you (\"%s\")" % [c.name.en, c.title.en, q.title.en]}
	return {"de": "Noch nicht freigeschaltet", "en": "Not unlocked yet"}


## Borr's dog runs off into the forest: a find somewhere among the trees of the home valley.
static func _spawn_find(w: World, what: String) -> void:
	for f in w.finds:
		if f.id == what:
			return
	var home := w.home_valley()
	var st = w.storage_of(home.idx)
	var cands := []
	for y in range(st.y - 18, st.y + 19):
		for x in range(st.x - 18, st.x + 19):
			if not w.inside(x, y):
				continue
			var i := w.idx(x, y)
			var d := Vector2(x - st.x, y - st.y).length()
			if d >= 9.0 and d <= 17.0 and w.valley[i] == home.idx and w.nature[i] == World.N_TREE and w.bmap[i] == 0:
				cands.append(Vector2i(x, y))
	if cands.is_empty():
		cands.append(Vector2i(st.x + 10, st.y + 4))
	var p: Vector2i = cands[w.rng.randi_range(0, cands.size() - 1)]
	w.finds.append({"id": what, "x": p.x, "y": p.y, "found": false, "valley": home.idx})


static func find(w: World, what: String) -> Dictionary:
	for f in w.finds:
		if f.id == what and not f.found:
			f.found = true
			return {"ok": true}
	return {"ok": false, "reason": {"de": "Nichts zu finden", "en": "Nothing to find"}}


static func on_season(w: World, s: int) -> void:
	if s != World.WINTER:
		return
	var home := w.home_valley()
	for q in Content.quests:
		var st = w.quests.get(q.id)
		if st == null or st.state != "active":
			continue
		for i in q.goals.size():
			var g: Dictionary = q.goals[i]
			if g.type != "winter_food" or st.ok.get(str(i), false):
				continue
			var food := w.food_stock(home.idx)
			if food >= float(g.n):
				st.ok[str(i)] = true
				say(w, q.char, {"de": "%d Körbe Nahrung zum ersten Schnee – das reicht für den Winter!" % floori(food), "en": "%d baskets of food at the first snow – enough for winter!" % floori(food)}, "good")
			else:
				say(w, q.char, {"de": "Nur %d von %d Körben Nahrung zum Winterbeginn. Nächsten Herbst müssen wir mehr einlagern." % [floori(food), int(g.n)], "en": "Only %d of %d baskets of food at the start of winter. Next autumn we must store more." % [floori(food), int(g.n)]}, "warn")


## Characters comment on problems in the valley (with a cooldown per topic).
static func _comments(w: World) -> void:
	for v in w.valleys:
		if v.owner != World.PLAYER:
			continue
		var pop := 0.0
		for t in v.get("population", {}):
			pop += v.population[t]
		if pop < 1.0:
			continue
		if Content.GOOD.has(v.get("food_short", "")):
			var gn: Dictionary = Content.GOOD[v.food_short].name
			_comment(w, "hunger", "ama", {"de": "Die Leute hungern – es fehlt an %s!" % gn.de, "en": "People are hungry – we're short of %s!" % gn.en})
		if v.get("freezing", false):
			_comment(w, "freezing", "ama", {"de": "Ohne Feuerholz frieren die Leute! Wir brauchen Holz, schnell!", "en": "Without firewood people freeze! We need wood, quickly!"})
		if v.game < 0.25 and here(w, "borr"):
			_comment(w, "game", "borr", {"de": "Das Wild ist fast verschwunden. Lass ein paar Jagdlager ruhen, sonst jagen wir bald gar nichts mehr.", "en": "The game is almost gone. Let a few hunting camps rest or soon we'll hunt nothing at all."})
		if v.mood < 30.0:
			_comment(w, "mood", "ama", {"de": "Die Stimmung ist schlecht – so zieht niemand mehr zu uns. Feste, Schönheit oder Luxusgüter würden helfen.", "en": "The mood is low – nobody will join us like this. Festivals, beauty or luxuries would help."})
		if v.get("spoil", {}).get("berries", 0.0) > 2.5 and w.count("storagepit", false, v.idx) == 0 and here(w, "sela"):
			_comment(w, "spoil", "sela", {"de": "Die Beeren verfaulen schneller, als wir sie essen. Eine Vorratsgrube würde helfen.", "en": "The berries rot faster than we eat them. A storage pit would help."})
	var ready := 0
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.get("ready", false) and not b.locked:
			ready += 1
	if ready >= 3:
		_comment(w, "ready", "ama", {"de": "%d Häuser sind bereit zum Aufwerten – achte auf den Pfeil über dem Dach." % ready, "en": "%d homes are ready to be upgraded – look for the arrow above the roof." % ready}, 300.0)


static func _comment(w: World, key: String, who: String, text: Dictionary, gap := COMMENT_GAP) -> void:
	if not here(w, who):
		return
	var k := "said_" + key
	if w.time - float(w.flags.get(k, -1e9)) < gap:
		return
	w.flags[k] = w.time
	say(w, who, text, "warn")
