class_name World
extends RefCounted
## The complete simulation state plus spatial helpers. The simulation never touches nodes or
## rendering, so it runs headless (tests, balancing, future lockstep multiplayer peers).

const SAVE_VERSION := 3
const PLAYER := "player"
const TICK := 0.1 # seconds of game time per simulation step
const STORAGE_PER_YARD := 30
const SEASON_LENGTH := 150.0 # seconds per season; a year has four
const YEAR := SEASON_LENGTH * 4.0
const WINTER := 3
const NICHES := 3
const FOOD := ["berries", "meat", "nuts", "fish", "wildgrain", "porridge", "bread", "cheese", "honey", "milk"]

enum { MOUNTAIN = 0, GRASS = 1, WATER = 2, PASS = 3 }
enum { N_NONE = 0, N_TREE = 1, N_BUSH = 2, N_ROCK = 3, N_STUMP = 4 }

## Difficulty presets: immigration, spoilage, crises per valley and year, starting stock, shells, neighbours.
const DIFFICULTY := {
	"lagerfeuer": {"imm": 1.5, "spoil": 0.5, "crises": 0.5, "stock": 2.0, "shells": 4000, "rivals": 0.7},
	"talherz": {"imm": 1.0, "spoil": 1.0, "crises": 1.0, "stock": 1.0, "shells": 2500, "rivals": 1.0},
	"bergwinter": {"imm": 0.8, "spoil": 1.25, "crises": 1.5, "stock": 0.6, "shells": 1800, "rivals": 1.3},
	"eiszeit": {"imm": 0.6, "spoil": 1.5, "crises": 2.0, "stock": 0.6, "shells": 1500, "rivals": 1.6},
	"sandbox": {"imm": 1.5, "spoil": 0.5, "crises": 0.0, "stock": 3.0, "shells": 50000, "rivals": 0.7},
}

# --- map
var size := 0
var terrain := PackedByteArray()
var valley := PackedInt32Array()
var nature := PackedByteArray()
var road := PackedByteArray()
var bmap := PackedInt32Array() # building id per tile, 0 = none
var pass_of := PackedInt32Array()
var deposit := {} # tile index -> deposit id

# --- state
var seed := 0
var rng := RandomNumberGenerator.new()
var tick := 0
var time := 0.0
var valleys: Array = []
var passes: Array = []
var buildings := {} # id -> Dictionary
var next_id := 1
var shells := 0.0
var income := 0.0
var upkeep := 0.0
var unlocked_tiers: Array = []
var difficulty := "talherz"
var diff: Dictionary = DIFFICULTY.talherz
var sandbox := false
var unlocked := {} # building id -> true
var festivals_unlocked: Array = []
var chars := {} # character id -> {state: away|arriving|here, t}
var quests := {} # quest id -> {state: offered|active|done, base: {}, ok: {}}
var items: Array = [] # treasures not yet placed in a niche
var customs: Array = [] # adopted customs
var custom_slots := 0
var prestige_pts := 0.0
var spirit = null # {id, until}
var events: Array = [] # crises and good events: {id, kind, valley, state: announced|active, start, until, ...}
var regrow := {} # stump tile -> time the tree is back
var finds: Array = [] # things to click in the world: {id, x, y, found}
var flags := {}
var stats := {"produced": {}, "festivals": {}, "lost": 0, "upgrades": 0}
var cold = null # the Great Cold: {state: pending|active, pop}
var won := false
var caravans: Array = []
var pass_ver := 0 # bumped when a pass opens or closes, so caravans re-plan their paths
var last_season := 0
var expedition = null
var trader := {"present": false, "timer": 150.0, "prices": {}}
var rivals: Array = []
var notifications: Array = []
var next_note := 1
var history: Array = []
var dirty := 1 # bumped whenever tiles or buildings change (render caches key on it)

# derived, not saved
var touched := PackedInt32Array() # tiles changed since the view last looked (incremental redraw)
var coverage := {}
var coverage_tick := -1


static func create(seed_value: int, difficulty_id := "talherz") -> World:
	var w := World.new()
	w.seed = seed_value
	w.rng.seed = seed_value
	MapGen.generate(w, seed_value)
	w.difficulty = difficulty_id if DIFFICULTY.has(difficulty_id) else "talherz"
	w.diff = DIFFICULTY[w.difficulty]
	w.sandbox = w.difficulty == "sandbox"
	w.shells = float(w.diff.shells)
	w.unlocked_tiers = [Content.tiers[0].id]
	for v in w.valleys:
		v.niches = []
		v.niches.resize(NICHES)
		v.niches.fill("")
		v.festival = null
		v.fest_last = {}
		v.game = 1.0
		v.fish = 1.0
		v.mood = 50.0
		v.imm = 0.0
		v.food_short = ""
		v.freezing = false
	for b in Content.buildings:
		if b.get("unlock", {}).get("start", false) or w.sandbox:
			w.unlocked[b.id] = true
	if w.sandbox:
		for t in Content.tiers:
			if not t.id in w.unlocked_tiers:
				w.unlocked_tiers.append(t.id)
		for f in Content.festivals:
			w.festivals_unlocked.append(f.id)
		w.custom_slots = 3
		w.prestige_pts = 100.0
		w.flags.trade = true
	var home := w.home_valley()
	var spot := w.find_free_spot(home.idx, 3, 3, home.cx, home.cy)
	if spot != Vector2i(-1, -1):
		w.place_building("storage", spot.x, spot.y, PLAYER)
	var k: float = w.diff.stock
	home.storage = {"wood": roundf(35.0 * k), "berries": roundf(20.0 * k)}
	Story.setup(w)
	for r in Content.rivals:
		for v in w.valleys:
			if v.owner == r.id:
				w.rivals.append({"id": r.id, "valley": v.idx, "contacted": false, "relation": 50.0, "population": 0, "build_timer": 5.0})
				var rs := w.find_free_spot(v.idx, 3, 3, v.cx, v.cy)
				if rs != Vector2i(-1, -1):
					w.place_building("storage", rs.x, rs.y, r.id)
	return w


# ---------------------------------------------------------------- simulation step

func step() -> void:
	tick += 1
	time += TICK
	var s := season()
	if s != last_season:
		last_season = s
		pass_ver += 1
		Life.season_changed(self, s)
		Events.season_changed(self, s)
	Economy.tick(self)
	Life.tick(self)
	Logistics.tick(self)
	if tick % 10 == 0:
		Story.tick(self)
		Events.tick(self)
	if tick % 100 == 0:
		history.append([roundi(time), roundi(shells), total_population()])
		if history.size() > 360:
			history.pop_front()
	if tick % 600 == 0 and shells < 0:
		notify({"de": "Die Muschelkasse ist leer! Senke den Unterhalt oder versorge deine Leute besser.", "en": "The shell purse is empty! Lower upkeep or supply your people better."}, "warn")


## 0 spring, 1 summer, 2 autumn, 3 winter
func season() -> int:
	return int(time / SEASON_LENGTH) % 4


func is_winter() -> bool:
	return season() == WINTER


func year() -> int:
	return int(time / YEAR) + 1


## 0..1 progress through the current season.
func season_progress() -> float:
	return fmod(time, SEASON_LENGTH) / SEASON_LENGTH


# ---------------------------------------------------------------- tiles

func idx(x: int, y: int) -> int:
	return y * size + x


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < size and y < size


func footprint(type: String, x: int, y: int) -> Array:
	var s: Array = Content.BUILDING[type].size
	var out := []
	for yy in int(s[1]):
		for xx in int(s[0]):
			out.append(Vector2i(x + xx, y + yy))
	return out


## Tiles orthogonally adjacent to a building footprint.
func perimeter(type: String, x: int, y: int) -> Array:
	var s: Array = Content.BUILDING[type].size
	var w := int(s[0])
	var h := int(s[1])
	var out := []
	for i in w:
		out.append(Vector2i(x + i, y - 1))
		out.append(Vector2i(x + i, y + h))
	for j in h:
		out.append(Vector2i(x - 1, y + j))
		out.append(Vector2i(x + w, y + j))
	return out


func home_valley() -> Dictionary:
	for v in valleys:
		if Content.valley_def(v.def).get("home", false):
			return v
	return valleys[0]


func storage_of(v: int):
	for b in buildings.values():
		if b.type == "storage" and b.valley == v:
			return b
	return null


## Every storage yard holds 30 of each good; storage pits and granaries add 20 more.
func storage_cap(v: int) -> int:
	var cap := 0
	var yards := 0
	for b in buildings.values():
		if b.valley != v:
			continue
		if b.type == "storage":
			yards += 1
		elif b.owner == PLAYER:
			cap += int(Content.BUILDING[b.type].get("store", {}).get("cap", 0))
	return maxi(1, yards) * STORAGE_PER_YARD + cap


func is_unlocked(building: String) -> bool:
	return sandbox or unlocked.has(building)


## Owned buildings of a type (optionally only those connected by paths).
func count(type: String, connected := false, v := -1) -> int:
	var n := 0
	for b in buildings.values():
		if b.owner == PLAYER and b.type == type and (not connected or b.connected) and (v < 0 or b.valley == v):
			n += 1
	return n


func hearth_of(v: int):
	for b in buildings.values():
		if b.type == "hearth" and b.valley == v and b.owner == PLAYER:
			return b
	return null


## Prestige needed to found the next valley: it rises with every valley you hold.
func found_cost() -> int:
	var owned := 0
	for v in valleys:
		if v.owner == PLAYER:
			owned += 1
	return 0 if sandbox else 10 * owned


func can_afford(cost: Dictionary, store: Dictionary) -> bool:
	for k in cost:
		if k == "shells":
			if shells < cost[k]:
				return false
		elif store.get(k, 0.0) < cost[k]:
			return false
	return true


func pay(cost: Dictionary, store: Dictionary) -> void:
	for k in cost:
		if k == "shells":
			shells -= cost[k]
		else:
			store[k] = store.get(k, 0.0) - cost[k]


func caravan(id: int):
	for c in caravans:
		if c.id == id:
			return c
	return null


## Hands the changed tiles to the view and forgets them.
func take_touched() -> PackedInt32Array:
	var t := touched
	touched = PackedInt32Array()
	return t


func tier_unlocked(t: String) -> bool:
	return t in unlocked_tiers


# ---------------------------------------------------------------- placement

## Full placement check shared by the build command and the UI preview.
## Returns {ok, reason, valley, pay_from}.
func check_placement(type: String, x: int, y: int, owner := PLAYER) -> Dictionary:
	if not Content.BUILDING.has(type):
		return _no("Unbekanntes Gebäude", "Unknown building")
	var def: Dictionary = Content.BUILDING[type]
	if owner == PLAYER:
		if def.get("buildable", true) == false:
			return _no("Entsteht nur durch Aufwerten", "Only obtained by upgrading")
		if not is_unlocked(type):
			return {"ok": false, "reason": Story.unlock_hint(self, type)}
	var v := -1
	for p in footprint(type, x, y):
		if not inside(p.x, p.y):
			return _no("Außerhalb der Karte", "Outside the map")
		var i := idx(p.x, p.y)
		var t := terrain[i]
		if t == MOUNTAIN or t == PASS:
			return _no("Im Gebirge kann man nicht bauen", "Cannot build in the mountains")
		if t == WATER:
			return _no("Nicht auf dem Wasser", "Not on water")
		if bmap[i] != 0:
			return _no("Belegt", "Occupied")
		if road[i]:
			return _no("Auf dem Pfad", "On a path")
		if v == -1:
			v = valley[i]
		elif v != valley[i]:
			return _no("Muss in einem Tal liegen", "Must be inside one valley")
	var vd: Dictionary = valleys[v]
	if owner == PLAYER and not vd.discovered:
		return _no("Unerforschtes Tal", "Unexplored valley")
	var pay_from := v
	if type == "storage" and owner == PLAYER:
		if vd.owner != null and vd.owner != PLAYER:
			return _no("Dieses Tal gehört einem anderen Stamm", "This valley belongs to another tribe")
		if vd.owner == null:
			pay_from = -1
			for o in valleys:
				if o.owner == PLAYER and not Logistics.valley_route(self, o.idx, v, false, true).is_empty():
					pay_from = o.idx
					break
			if pay_from < 0:
				return _no("Kein offener Pass führt hierher – erst das Hindernis überwinden", "No open pass leads here – overcome the obstacle first")
			if prestige_pts < found_cost():
				return _no("Ein neues Tal zu gründen kostet %d Ansehen" % found_cost(), "Founding a new valley costs %d prestige" % found_cost())
	elif vd.owner != owner:
		if owner == PLAYER and vd.owner == null:
			return _no("Gründe hier zuerst einen Lagerplatz", "Found a storage yard here first")
		return _no("Fremdes Tal", "Foreign valley")
	if owner == PLAYER and def.get("unique", false) and hearth_of(v) != null:
		return _no("Jedes Tal hat nur ein Talherz", "Each valley has only one Valley Heart")
	var req: Dictionary = def.get("requires", {})
	if owner == PLAYER and not req.is_empty():
		if req.has("fertility") and not req.fertility in vd.fertilities:
			return _no("Dem Tal fehlt die nötige Fruchtbarkeit", "The valley lacks the required fertility")
		if req.has("deposit"):
			var on_dep := false
			for p in footprint(type, x, y):
				if deposit.get(idx(p.x, p.y), "") == req.deposit:
					on_dep = true
			if not on_dep:
				return _no("Muss auf einem Vorkommen stehen", "Must be placed on a deposit")
		if req.has("nearWater") and not _has_near(type, x, y, int(req.nearWater), WATER):
			return _no("Muss am Wasser stehen", "Must be next to water")
		if req.has("nearPass") and not _has_near(type, x, y, int(req.nearPass), PASS):
			return _no("Muss am Fuß eines Passes stehen", "Must stand at the foot of a pass")
		if req.has("nearMountain") and not _has_near(type, x, y, int(req.nearMountain), MOUNTAIN):
			return _no("Muss am Fuß der Berge stehen", "Must stand at the foot of the mountains")
	if owner == PLAYER and not can_afford(def.cost, valleys[pay_from].storage):
		return {"ok": false, "reason": {"de": "Nicht genug Rohstoffe", "en": "Not enough resources"}, "valley": v, "pay_from": pay_from}
	return {"ok": true, "valley": v, "pay_from": pay_from}


func _no(de: String, en: String) -> Dictionary:
	return {"ok": false, "reason": {"de": de, "en": en}}


func _has_near(type: String, x: int, y: int, r: int, kind: int) -> bool:
	var s: Array = Content.BUILDING[type].size
	for yy in range(y - r, y + int(s[1]) + r):
		for xx in range(x - r, x + int(s[0]) + r):
			if inside(xx, yy) and terrain[idx(xx, yy)] == kind:
				return true
	return false


## Counts trees/bushes around a building – drives gatherer productivity.
func nature_around(b: Dictionary, kind: int, r: int) -> int:
	var s: Array = Content.BUILDING[b.type].size
	var n := 0
	for yy in range(b.y - r, b.y + int(s[1]) + r):
		for xx in range(b.x - r, b.x + int(s[0]) + r):
			if inside(xx, yy):
				var i := idx(xx, yy)
				if nature[i] == kind and bmap[i] == 0 and not road[i]:
					n += 1
	return n


func place_building(type: String, x: int, y: int, owner: String) -> Dictionary:
	var def: Dictionary = Content.BUILDING[type]
	var id := next_id
	next_id += 1
	var v := valley[idx(x, y)]
	var b := {"id": id, "type": type, "x": x, "y": y, "owner": owner, "valley": v, "progress": 0.0, "working": false,
		"paused": false, "productivity": 0.0, "status": "ok", "connected": type == "storage", "nature": -1.0}
	if def.category == "residence":
		b.tier = def.tier
		b.residents = 1.0 if owner == PLAYER else float(Content.TIER[def.tier].baseResidents)
		b.needs = {}
		b.mood = 50.0
		b.locked = false
		b.grace = 0.0
		b.ready = false
	b.riverside = _has_near(type, x, y, 2, WATER)
	for p in footprint(type, x, y):
		var i := idx(p.x, p.y)
		bmap[i] = id
		nature[i] = N_NONE
		touched.append(i)
	buildings[id] = b
	if type == "storage" and owner == PLAYER and valleys[v].owner != PLAYER:
		valleys[v].owner = PLAYER
	dirty += 1
	return b


func remove_building(id: int) -> void:
	if not buildings.has(id):
		return
	var b: Dictionary = buildings[id]
	for p in footprint(b.type, b.x, b.y):
		bmap[idx(p.x, p.y)] = 0
		touched.append(idx(p.x, p.y))
	buildings.erase(id)
	dirty += 1


func find_free_spot(v: int, w: int, h: int, cx: float, cy: float) -> Vector2i:
	for r in 20:
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if maxi(absi(xx), absi(yy)) != r:
					continue
				var x := roundi(cx + xx - w / 2.0)
				var y := roundi(cy + yy - h / 2.0)
				var ok := true
				for j in h:
					for i in w:
						if not inside(x + i, y + j):
							ok = false
							continue
						var t := idx(x + i, y + j)
						if terrain[t] != GRASS or valley[t] != v or bmap[t] != 0 or road[t] or deposit.has(t):
							ok = false
				if ok:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- population & notifications

func notify(text: Dictionary, kind := "info", extra := {}) -> void:
	var n := {"id": next_note, "t": time, "text": text, "kind": kind}
	n.merge(extra)
	notifications.append(n)
	next_note += 1
	if notifications.size() > 40:
		notifications.pop_front()


func player_population() -> Dictionary:
	var out := {}
	for t in Content.tiers:
		out[t.id] = 0
	for b in buildings.values():
		if b.owner == PLAYER and b.has("tier"):
			out[b.tier] += roundi(b.residents)
	return out


func total_population() -> int:
	var n := 0
	for v in player_population().values():
		n += v
	return n


## Prestige ("Ansehen") – earned with festivals, quests and happy people, spent on new valleys and customs.
func prestige() -> int:
	return floori(prestige_pts)


## Total food in a valley's storage (used by Ama's winter test and the HUD).
func food_stock(v: int) -> float:
	var n := 0.0
	for g in FOOD:
		n += valleys[v].storage.get(g, 0.0)
	return n


func top_tier() -> String:
	return unlocked_tiers[-1]


# ---------------------------------------------------------------- save / load

const SAVED_FIELDS := ["size", "terrain", "valley", "nature", "road", "pass_of", "deposit", "seed", "tick", "time", "valleys", "passes",
	"buildings", "next_id", "shells", "unlocked_tiers", "difficulty", "sandbox", "unlocked", "festivals_unlocked", "chars", "quests", "items",
	"customs", "custom_slots", "prestige_pts", "spirit", "events", "regrow", "finds", "flags", "stats", "cold", "won",
	"caravans", "pass_ver", "last_season", "expedition", "trader", "rivals", "notifications", "next_note", "history"]


func to_dict() -> Dictionary:
	var d := {"version": SAVE_VERSION, "rng_state": rng.state}
	for f in SAVED_FIELDS:
		d[f] = get(f)
	return d


static func from_dict(d: Dictionary) -> World:
	assert(int(d.get("version", 0)) == SAVE_VERSION, "unsupported save version")
	var w := World.new()
	for f in SAVED_FIELDS:
		w.set(f, d[f])
	w.rng.state = d.rng_state
	w.diff = DIFFICULTY.get(w.difficulty, DIFFICULTY.talherz)
	w.bmap.resize(w.size * w.size)
	w.bmap.fill(0)
	for b in w.buildings.values():
		for p in w.footprint(b.type, b.x, b.y):
			w.bmap[w.idx(p.x, p.y)] = b.id
	w.dirty += 1
	return w


## Cheap checksum for desync detection in lockstep multiplayer.
func checksum() -> int:
	var h := tick * 31 + roundi(shells * 100) + roundi(prestige_pts * 10) + quests.size()
	var ids := buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = buildings[id]
		h = SimNoise.imul(h, 16777619) ^ (b.id * 7 + b.x * 13 + b.y * 17 + roundi(b.get("residents", 0.0) * 10))
	return h
