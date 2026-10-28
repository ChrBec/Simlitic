class_name Objectives
## Guided objectives – the tutorial thread through the first hours (Anno-style quest chain).

const ORDER := ["tents", "fireplace", "berries", "wood", "sedentary_unlock", "hut", "fisher", "scout", "explore", "settle",
	"caravanpost", "caravan", "tools", "clear_pass", "farmers", "bread", "villagers", "pottery", "crossing", "chieftains", "copper", "plank", "bronze"]

const TEXT := {
	"tents": {"de": "Errichte 4 Fellzelte und verbinde sie mit Pfaden zum Lagerplatz", "en": "Raise 4 hide tents and connect them to the storage yard with paths"},
	"fireplace": {"de": "Entzünde eine Feuerstelle in der Nähe der Zelte", "en": "Light a fire pit near the tents"},
	"berries": {"de": "Baue einen Beerensammler bei den Sträuchern", "en": "Build a berry gatherer near the bushes"},
	"wood": {"de": "Baue einen Holzfäller am Waldrand", "en": "Build a woodcutter at the forest edge"},
	"sedentary_unlock": {"de": "Wachse auf 60 Wildbeuter – dann werden deine Leute sesshaft", "en": "Grow to 60 foragers – then your people settle down"},
	"hut": {"de": "Lass ein Zelt zur Grubenhütte aufsteigen (Holz + Häute)", "en": "Upgrade a tent to a pit house (wood + hides)"},
	"fisher": {"de": "Versorge die Sesshaften mit Fisch und Wildgetreide-Brei", "en": "Supply the settled folk with fish and wild-grain porridge"},
	"scout": {"de": "Baue ein Kundschafterlager", "en": "Build a scout camp"},
	"explore": {"de": "Erkunde einen Bergpfad (Täler-Fenster: M)", "en": "Explore a mountain path (valleys window: M)"},
	"settle": {"de": "Gründe mit einem Lagerplatz ein zweites Tal (z. B. die Feuersteinschlucht)", "en": "Found a second valley with a storage yard (e.g. Flint Gorge)"},
	"caravanpost": {"de": "Baue einen Rastplatz am Fuß eines Passes", "en": "Build a caravan camp at the foot of a pass"},
	"caravan": {"de": "Stelle einen Trägertrupp auf und gib ihm eine Route mit zwei Halten", "en": "Hire a porter team and give it a route with two stops"},
	"tools": {"de": "Stelle Steinwerkzeug her (Feuerstein + Holz)", "en": "Make stone tools (flint + wood)"},
	"clear_pass": {"de": "Überwinde ein Hindernis auf einem Pass", "en": "Overcome an obstacle on a pass"},
	"farmers": {"de": "Die Neolithische Revolution: Erreiche die Bauern", "en": "The Neolithic Revolution: reach the farmers"},
	"bread": {"de": "Backe Brot: Emmerfeld → Mühle → Backofen", "en": "Bake bread: emmer field → mill → bake oven"},
	"villagers": {"de": "Wachse zum Dorf: Erreiche die Dörfler", "en": "Grow into a village: reach the villagers"},
	"pottery": {"de": "Brenne Keramik in einem Töpferofen", "en": "Fire pottery in a kiln"},
	"crossing": {"de": "Baue eine Floßfähre oder Seilbrücke", "en": "Build a raft ferry or a rope bridge"},
	"chieftains": {"de": "Der Aufstieg der Häuptlinge: Erreiche die Kupferzeit", "en": "Rise of the chieftains: reach the Copper Age"},
	"copper": {"de": "Schmelze Kupfer (Erz + Holzkohle)", "en": "Smelt copper (ore + charcoal)"},
	"plank": {"de": "Lege einen Bohlenweg für Ochsenkarren über einen Pass", "en": "Lay a plank road over a pass for ox carts"},
	"bronze": {"de": "Gieße Bronze – das Ende der Steinzeit", "en": "Cast bronze – the end of the Stone Age"},
}


static func _count(w: World, type: String, need_connection := true) -> int:
	var n := 0
	for b in w.buildings.values():
		if b.owner == World.PLAYER and b.type == type and (not need_connection or b.connected):
			n += 1
	return n


static func check(w: World, id: String) -> bool:
	var pop := w.player_population()
	match id:
		"tents": return _count(w, "tent") + _count(w, "hut") >= 4
		"fireplace": return _count(w, "fireplace") >= 1
		"berries": return _count(w, "berrygatherer") >= 1
		"wood": return _count(w, "woodcutter") >= 1
		"sedentary_unlock": return w.tier_unlocked("sedentary")
		"hut": return pop.sedentary > 0
		"fisher": return _count(w, "fisher") >= 1 and _count(w, "grinder") >= 1
		"scout": return _count(w, "scout", false) >= 1
		"explore": return w.passes.any(func(p): return p.discovered)
		"settle": return w.valleys.filter(func(v): return v.owner == World.PLAYER).size() >= 2
		"caravanpost": return _count(w, "caravanpost", false) >= 1
		"caravan": return w.caravans.any(func(c): return c.stops.size() >= 2)
		"tools": return _count(w, "toolmaker") >= 1
		"clear_pass": return w.passes.any(func(p): return p.cleared and p.obstacle != "none")
		"farmers": return pop.farmers > 0
		"bread": return _count(w, "bakery") >= 1
		"villagers": return pop.villagers > 0
		"pottery": return _count(w, "potter") >= 1
		"crossing": return w.passes.any(func(p): return p.cleared and (p.obstacle == "river" or p.obstacle == "gorge"))
		"chieftains": return pop.chieftains > 0
		"copper": return _count(w, "smelter") >= 1
		"plank": return w.passes.any(func(p): return p.plank)
		"bronze": return _count(w, "bronzesmith") >= 1
	return false


## Objectives are sequential – only the current one is checked.
static func tick(w: World) -> void:
	for o in w.objectives:
		if o.done:
			continue
		if check(w, o.id):
			o.done = true
			w.notify({"de": "Ziel erreicht: " + TEXT[o.id].de, "en": "Objective complete: " + TEXT[o.id].en}, "good")
		return


static func current(w: World) -> String:
	for o in w.objectives:
		if not o.done:
			return o.id
	return ""
