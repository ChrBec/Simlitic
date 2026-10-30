extends Node
## Data-driven game content. Everything that defines *what* the game is lives in res://content/*.json
## and can be edited or modded without touching code.

var goods: Array = []
var tiers: Array = []
var buildings: Array = []
var fertilities: Array = []
var valleys: Array = []
var rivals: Array = []
var passes: Array = []
var obstacles: Array = []
var caravans: Array = []
var characters: Array = []
var quests: Array = []
var items: Array = []
var customs: Array = []
var festivals: Array = []
var spirits: Array = []

var GOOD := {}
var TIER := {}
var BUILDING := {}
var FERTILITY := {}
var RIVAL := {}
var OBSTACLE := {}
var CARAVAN := {}
var CHARACTER := {}
var QUEST := {}
var ITEM := {}
var CUSTOM := {}
var FESTIVAL := {}
var SPIRIT := {}
var service_ids := {}

var lang := "de"


func _init() -> void:
	goods = _load("goods")
	tiers = _load("tiers")
	buildings = _load("buildings")
	fertilities = _load("fertilities")
	valleys = _load("valleys")
	rivals = _load("rivals")
	passes = _load("passes")
	obstacles = _load("obstacles")
	caravans = _load("caravans")
	characters = _load("characters")
	quests = _load("quests")
	items = _load("items")
	customs = _load("customs")
	festivals = _load("festivals")
	spirits = _load("spirits")
	GOOD = _index(goods)
	TIER = _index(tiers)
	BUILDING = _index(buildings)
	FERTILITY = _index(fertilities)
	RIVAL = _index(rivals)
	OBSTACLE = _index(obstacles)
	CARAVAN = _index(caravans)
	CHARACTER = _index(characters)
	QUEST = _index(quests)
	ITEM = _index(items)
	CUSTOM = _index(customs)
	FESTIVAL = _index(festivals)
	SPIRIT = _index(spirits)
	for b in buildings:
		if b.has("service"):
			service_ids[b.service.id] = b.id


func _load(file: String) -> Array:
	# A mod folder in user:// may override any content file.
	var mod_path := "user://mods/content/%s.json" % file
	var path := mod_path if FileAccess.file_exists(mod_path) else "res://content/%s.json" % file
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(data is Array, "content file %s is broken" % path)
	return data


func _index(list: Array) -> Dictionary:
	var d := {}
	for x in list:
		d[x.id] = x
	return d


# ---------------------------------------------------------------- lookups

func tier_index(id: String) -> int:
	for i in tiers.size():
		if tiers[i].id == id:
			return i
	return -1


func next_tier(id: String):
	var i := tier_index(id)
	return tiers[i + 1] if i >= 0 and i + 1 < tiers.size() else null


func valley_def(id: String) -> Dictionary:
	for v in valleys:
		if v.id == id:
			return v
	return {}


func is_service(need_id: String) -> bool:
	return service_ids.has(need_id)


func need_name(need_id: String) -> String:
	if GOOD.has(need_id):
		return tx(GOOD[need_id].name)
	if service_ids.has(need_id):
		return tx(BUILDING[service_ids[need_id]].name)
	return need_id


func max_residents(tier_id: String) -> int:
	var t: Dictionary = TIER[tier_id]
	var n: int = t.baseResidents
	for need in t.needs:
		n += int(need.get("residents", 0))
	return n


func tier_house(house_type: String) -> String:
	for t in tiers:
		if t.house == house_type:
			return t.id
	return ""


func season_name(s: int) -> String:
	return [L("Frühling", "Spring"), L("Sommer", "Summer"), L("Herbst", "Autumn"), L("Winter", "Winter")][s]


# ---------------------------------------------------------------- language

## Picks the current language from a {de, en} text.
func tx(t) -> String:
	if t is Dictionary:
		return t.get(lang, t.get("de", ""))
	return str(t)


## Inline UI strings: L("Deutsch", "English").
func L(de: String, en: String) -> String:
	return de if lang == "de" else en
