class_name Events
## Crises and lucky events. A crisis is announced one season ahead by one of the characters, so the
## player can prepare – and most crises can be averted with a click and a few goods.

## season: when it strikes (-1 any); fix: goods that avert it; who: the character who warns; len: seconds.
const CRISES := {
	"wolves": {"season": 3, "fix": [{"meat": 5}], "who": "borr", "len": 150.0,
		"name": {"de": "Wölfe", "en": "Wolves"},
		"warn": {"de": "Ich habe Wolfsspuren im Schnee der Pässe gesehen. Diesen Winter kommen sie bis an unsere Vorräte.", "en": "I've seen wolf tracks in the snow of the passes. This winter they'll come for our stores."},
		"hit": {"de": "Wölfe schleichen um das Lager! Leg 5 Fleisch als Köder aus, sonst holen sie sich mehr.", "en": "Wolves prowl around the camp! Put out 5 meat as bait, or they'll take more."}},
	"illness": {"season": -1, "fix": [{"herbs": 3}, {"honey": 3}], "who": "ilun", "len": 90.0,
		"name": {"de": "Krankheit", "en": "Sickness"},
		"warn": {"de": "Im Rauch sehe ich Fieber. Haltet Kräuter oder Honig bereit.", "en": "I see fever in the smoke. Keep herbs or honey ready."},
		"hit": {"de": "Fieber geht um! Gib 3 Kräuter oder 3 Honig, sonst sterben Menschen. Wer nah am Schamanenplatz wohnt, ist sicherer.", "en": "Fever is spreading! Give 3 herbs or 3 honey or people will die. Those living near the shaman's place are safer."}},
	"fire": {"season": 1, "fix": [{"wood": 5}], "who": "ama", "len": 40.0,
		"name": {"de": "Feuer", "en": "Fire"},
		"warn": {"de": "Der Sommer wird trocken. Ein Funke genügt – haltet Holz zum Ausschlagen bereit.", "en": "The summer will be dry. One spark is enough – keep wood ready to beat out flames."},
		"hit": {"de": "Feuer! Ein Gebäude brennt – klick es an und lösch es mit 5 Holz, bevor es niederbrennt!", "en": "Fire! A building is burning – click it and put it out with 5 wood before it burns down!"}},
	"flood": {"season": 0, "fix": [], "who": "sela", "len": 60.0,
		"name": {"de": "Hochwasser", "en": "Flood"},
		"warn": {"de": "Auf den Gipfeln liegt viel Schnee. Wenn er schmilzt, tritt das Wasser über die Ufer.", "en": "There's much snow on the peaks. When it melts, the water will break its banks."},
		"hit": {"de": "Hochwasser! Alles am Ufer steht eine Weile still.", "en": "Flood! Everything by the water stands still for a while."}},
	"drought": {"season": 1, "fix": [], "who": "sela", "len": 150.0,
		"name": {"de": "Dürre", "en": "Drought"},
		"warn": {"de": "Der Frühling war zu trocken. Im Sommer werden Sträucher und Halme wenig tragen.", "en": "Spring was too dry. In summer bushes and stalks will bear little."},
		"hit": {"de": "Dürre: Sammler und Felder bringen 40 % weniger.", "en": "Drought: gatherers and fields yield 40% less."}},
	"coldsnap": {"season": 3, "fix": [], "who": "ama", "len": 150.0,
		"name": {"de": "Kälteeinbruch", "en": "Cold Snap"},
		"warn": {"de": "Meine Knie sagen mir: Der Winter wird bitter. Stapelt doppelt so viel Holz.", "en": "My knees tell me: winter will be bitter. Stack twice the wood."},
		"hit": {"de": "Bittere Kälte: Jedes Haus verbrennt doppelt so viel Holz.", "en": "Bitter cold: every home burns twice the wood."}},
}
const LUCK := ["wanderers", "herd", "swarm", "star"]


static func effect(e: Dictionary) -> Dictionary:
	match e.kind:
		"wolves": return {"mood": -10}
		"illness": return {"mood": -15}
		"drought": return {"gather": -0.4, "field": -0.4}
		"coldsnap": return {"firewood": 1.0}
		"star": return {"mood": 5}
	return {}


static func _next_id(w: World) -> int:
	w.flags.event_id = int(w.flags.get("event_id", 0)) + 1
	return w.flags.event_id


## On every new season: maybe announce a crisis for the next one, maybe something lucky happens now.
static func season_changed(w: World, s: int) -> void:
	if w.sandbox:
		return
	var next := (s + 1) % 4
	for v in w.valleys:
		if v.owner != World.PLAYER or _people(w, v.idx) < 10.0:
			continue
		var m: Dictionary = v.get("mods", {})
		# crises only from the third year on, about one per valley and year on normal difficulty
		if w.year() >= 3 and w.rng.randf() < float(w.diff.crises) / 4.0:
			var options := []
			for k in CRISES:
				var c: Dictionary = CRISES[k]
				if int(c.season) != -1 and int(c.season) != next:
					continue
				if k == "wolves" and m.get("no_wolves", 0.0) > 0.0:
					continue
				if k == "flood" and (m.get("no_flood", 0.0) > 0.0 or not _has_water(w, v.idx)):
					continue
				if k == "illness" and w.rng.randf() < -m.get("illness", 0.0):
					continue
				if k == "fire" and w.rng.randf() < -m.get("fire", 0.0):
					continue
				options.append(k)
			if not options.is_empty():
				var kind: String = options[w.rng.randi_range(0, options.size() - 1)]
				var start := (floorf(w.time / World.SEASON_LENGTH) + 1.0) * World.SEASON_LENGTH
				w.events.append({"id": _next_id(w), "kind": kind, "valley": v.idx, "state": "announced", "start": start, "until": start + float(CRISES[kind].len)})
				var who: String = CRISES[kind].who
				if not Story.here(w, who):
					who = "ama"
				Story.say(w, who, CRISES[kind].warn, "warn")
		# lucky events after the first summer
		if w.time > World.SEASON_LENGTH * 2.0 and w.rng.randf() < 0.12:
			_luck(w, v, LUCK[w.rng.randi_range(0, LUCK.size() - 1)])


static func _people(w: World, v: int) -> float:
	var n := 0.0
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == v and b.has("tier"):
			n += b.residents
	return n


static func _has_water(w: World, v: int) -> bool:
	return Content.valley_def(w.valleys[v].def).get("water", "none") != "none"


static func _luck(w: World, v: Dictionary, kind: String) -> void:
	var name: Dictionary = Content.valley_def(v.def).name
	match kind:
		"wanderers":
			var n := w.rng.randi_range(5, 10)
			var came := 0
			for b in w.buildings.values():
				if came >= n:
					break
				if b.owner == World.PLAYER and b.valley == v.idx and b.has("tier"):
					var room := floorf(b.get("target", 0.0) - b.residents)
					if room >= 1.0:
						var k := mini(int(room), n - came)
						b.residents += k
						came += k
			if came > 0:
				w.notify({"de": "Wanderer aus dem Norden bleiben in %s: %d neue Bewohner!" % [name.de, came], "en": "Wanderers from the north stay in %s: %d new residents!" % [name.en, came]}, "good")
		"herd":
			v.game = minf(1.0, v.game + 0.3)
			w.notify({"de": "Eine Hirschherde zieht durch %s – das Wild ist zurück (+30 %%)." % name.de, "en": "A herd of deer moves through %s – the game is back (+30%%)." % name.en}, "good")
		"swarm":
			var good := "honey" if w.tier_unlocked("sedentary") else "berries"
			v.storage[good] = minf(w.storage_cap(v.idx), v.storage.get(good, 0.0) + 15.0)
			if good == "honey":
				w.notify({"de": "Ein Bienenschwarm in einem hohlen Baum: +15 Honig in %s." % name.de, "en": "A bee swarm in a hollow tree: +15 honey in %s." % name.en}, "good")
			else:
				w.notify({"de": "Ein Hang voller reifer Beeren: +15 Beeren in %s." % name.de, "en": "A slope full of ripe berries: +15 berries in %s." % name.en}, "good")
		"star":
			w.events.append({"id": _next_id(w), "kind": "star", "valley": v.idx, "state": "active", "start": w.time, "until": w.time + World.SEASON_LENGTH})
			w.notify({"de": "Ein Schweifstern am Himmel über %s! Alle sehen darin ein gutes Zeichen (Stimmung +5)." % name.de, "en": "A comet in the sky over %s! Everyone takes it as a good sign (mood +5)." % name.en}, "good")


## Every second: crises start, do their damage and end.
static func tick(w: World) -> void:
	var gone := []
	for e in w.events:
		if e.state == "announced" and w.time >= e.start:
			e.state = "active"
			e.t = 0.0
			if CRISES.has(e.kind):
				if e.kind == "fire" and not _ignite(w, e):
					gone.append(e)
					continue
				w.notify({"de": "%s: %s" % [CRISES[e.kind].name.de, CRISES[e.kind].hit.de], "en": "%s: %s" % [CRISES[e.kind].name.en, CRISES[e.kind].hit.en]}, "crisis", {"event": e.id})
			continue
		if e.state != "active":
			continue
		e.t = e.get("t", 0.0) + 1.0
		var v: Dictionary = w.valleys[e.valley]
		match e.kind:
			"wolves":
				if int(e.t) % 30 == 0:
					v.storage.meat = maxf(0.0, v.storage.get("meat", 0.0) - 5.0)
			"illness":
				if int(e.t) % 15 == 0:
					_sicken(w, e.valley)
		if w.time >= e.until:
			gone.append(e)
			if e.kind == "fire":
				_burn_down(w, e)
			elif CRISES.has(e.kind):
				w.notify({"de": "%s ist vorüber." % CRISES[e.kind].name.de, "en": "The %s is over." % CRISES[e.kind].name.en.to_lower()}, "info")
	for e in gone:
		w.events.erase(e)


static func _ignite(w: World, e: Dictionary) -> bool:
	var cands := []
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == e.valley and Content.BUILDING[b.type].category == "production":
			cands.append(b)
	if cands.is_empty():
		return false
	var b: Dictionary = cands[w.rng.randi_range(0, cands.size() - 1)]
	b.burning = true
	e.building = b.id
	return true


static func _burn_down(w: World, e: Dictionary) -> void:
	var id: int = e.get("building", 0)
	if not w.buildings.has(id) or not w.buildings[id].get("burning", false):
		return
	var name: Dictionary = Content.BUILDING[w.buildings[id].type].name
	w.remove_building(id)
	w.notify({"de": "%s ist niedergebrannt." % name.de, "en": "%s burned down." % name.en}, "warn")


## Fever takes one person from a house that is not under the shaman's care.
static func _sicken(w: World, v: int) -> void:
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.valley == v and b.has("tier") and b.residents > 1.5:
			if w.coverage.get(b.id, {}).has("shaman") and w.rng.randf() < 0.7:
				continue
			b.residents -= 1.0
			w.stats.lost += 1
			return


## The player averts a crisis by paying its remedy.
static func resolve(w: World, id: int) -> Dictionary:
	for e in w.events:
		if e.id != id:
			continue
		var c: Dictionary = CRISES.get(e.kind, {})
		if c.get("fix", []).is_empty():
			return {"ok": false, "reason": {"de": "Dagegen hilft nur Abwarten", "en": "Only waiting helps against this"}}
		if e.state != "active":
			return {"ok": false, "reason": {"de": "Noch ist nichts geschehen", "en": "Nothing has happened yet"}}
		var st: Dictionary = w.valleys[e.valley].storage
		for fix in c.fix:
			if w.can_afford(fix, st):
				w.pay(fix, st)
				w.events.erase(e)
				if e.kind == "fire" and w.buildings.has(e.get("building", 0)):
					w.buildings[e.building].burning = false
				w.notify({"de": "%s abgewendet!" % c.name.de, "en": "%s averted!" % c.name.en}, "good")
				if e.kind == "wolves" and not w.flags.get("wolftooth", false):
					w.flags.wolftooth = true
					Story.give(w, {"items": ["wolftooth"]})
				return {"ok": true}
		return {"ok": false, "reason": {"de": "Nicht genug im Lager", "en": "Not enough in storage"}}
	return {"ok": false, "reason": {"de": "Unbekanntes Ereignis", "en": "Unknown event"}}


static func active_in(w: World, v: int) -> Array:
	return w.events.filter(func(e): return e.valley == v)
