class_name Objectives
## Guided objectives – the tutorial thread through the first hours (Anno-style quest chain).

const ORDER := ["tents", "fireplace", "berries", "wood", "gatherers40", "hunters", "scout", "explore", "settle", "route", "settlers", "artisans", "farmers"]

const TEXT := {
	"tents": {"de": "Errichte 4 Fellzelte und verbinde sie mit Pfaden zum Lagerplatz", "en": "Raise 4 hide tents and connect them to the storage yard with paths"},
	"fireplace": {"de": "Entzünde eine Feuerstelle in der Nähe der Zelte", "en": "Light a fire pit near the tents"},
	"berries": {"de": "Baue einen Beerensammler bei den Sträuchern", "en": "Build a berry gatherer near the bushes"},
	"wood": {"de": "Baue einen Holzfäller am Waldrand", "en": "Build a woodcutter at the forest edge"},
	"gatherers40": {"de": "Wachse auf 40 Sammler, um die Zeit der Jäger einzuläuten", "en": "Grow to 40 gatherers to herald the age of hunters"},
	"hunters": {"de": "Lass ein Zelt zur Rindenhütte aufsteigen (Häute + Holz)", "en": "Upgrade a tent to a bark hut (hides + wood)"},
	"scout": {"de": "Baue ein Kundschafterlager", "en": "Build a scout camp"},
	"explore": {"de": "Erkunde einen Bergpfad (Täler-Fenster: M)", "en": "Explore a mountain path (valleys window: M)"},
	"settle": {"de": "Gründe mit einem Lagerplatz ein zweites Tal", "en": "Found a second valley with a storage yard"},
	"route": {"de": "Richte eine Trägerroute zum Haupttal ein", "en": "Set up a porter route to the main valley"},
	"settlers": {"de": "Erreiche die Stufe der Siedler", "en": "Reach the settler tier"},
	"artisans": {"de": "Erreiche die Stufe der Handwerker", "en": "Reach the artisan tier"},
	"farmers": {"de": "Vollende die Neolithische Revolution: Bauern!", "en": "Complete the Neolithic Revolution: farmers!"},
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
		"gatherers40": return w.tier_unlocked("hunters")
		"hunters": return pop.hunters > 0
		"scout": return _count(w, "scout", false) >= 1
		"explore": return w.passes.any(func(p): return p.discovered)
		"settle": return w.valleys.filter(func(v): return v.owner == World.PLAYER).size() >= 2
		"route": return w.routes.size() >= 1
		"settlers": return pop.settlers > 0
		"artisans": return pop.artisans > 0
		"farmers": return pop.farmers > 0
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
