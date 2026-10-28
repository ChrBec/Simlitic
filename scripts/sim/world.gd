class_name World
extends RefCounted
## The complete simulation state plus spatial helpers. The simulation never touches nodes or
## rendering, so it runs headless (tests, balancing, future lockstep multiplayer peers).

const SAVE_VERSION := 2
const PLAYER := "player"
const TICK := 0.1 # seconds of game time per simulation step
const STORAGE_PER_YARD := 80
const SEASON_LENGTH := 150.0 # seconds per season; a year has four
const WINTER := 3

enum { MOUNTAIN = 0, GRASS = 1, WATER = 2, PASS = 3 }
enum { N_NONE = 0, N_TREE = 1, N_BUSH = 2, N_ROCK = 3 }

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
var upgrade_allowed := {}
var caravans: Array = []
var pass_ver := 0 # bumped when a pass opens or closes, so caravans re-plan their paths
var last_season := 0
var expedition = null
var trader := {"present": false, "timer": 150.0, "prices": {}}
var rivals: Array = []
var notifications: Array = []
var next_note := 1
var objectives: Array = []
var history: Array = []
var dirty := 1 # bumped whenever tiles or buildings change (render caches key on it)

# derived, not saved
var touched := PackedInt32Array() # tiles changed since the view last looked (incremental redraw)
var coverage := {}
var coverage_tick := -1


static func create(seed_value: int, difficulty := "normal") -> World:
	var w := World.new()
	w.seed = seed_value
	w.rng.seed = seed_value
	MapGen.generate(w, seed_value)
	w.shells = {"relaxed": 4000.0, "hard": 1500.0}.get(difficulty, 2500.0)
	w.unlocked_tiers = [Content.tiers[0].id]
	for t in Content.tiers:
		w.upgrade_allowed[t.id] = true
	w.objectives = []
	for o in Objectives.ORDER:
		w.objectives.append({"id": o, "done": false})
	var home := w.home_valley()
	var spot := w.find_free_spot(home.idx, 3, 3, home.cx, home.cy)
	if spot != Vector2i(-1, -1):
		w.place_building("storage", spot.x, spot.y, PLAYER)
	home.storage = {"wood": 40.0, "berries": 12.0}
	for r in Content.rivals:
		for v in w.valleys:
			if v.owner == r.id:
				w.rivals.append({"id": r.id, "valley": v.idx, "contacted": false, "relation": 50.0, "population": 0, "build_timer": 5.0})
				var rs := w.find_free_spot(v.idx, 3, 3, v.cx, v.cy)
				if rs != Vector2i(-1, -1):
					w.place_building("storage", rs.x, rs.y, r.id)
	w.notify({"de": "Dein Stamm hat ein fruchtbares Tal gefunden. Errichte Zelte und eine Feuerstelle.", "en": "Your tribe has found a fertile valley. Raise tents and a fire pit."}, "info")
	return w


# ---------------------------------------------------------------- simulation step

func step() -> void:
	tick += 1
	time += TICK
	Economy.tick(self)
	Logistics.tick(self)
	if tick % 10 == 0:
		Objectives.tick(self)
	if tick % 100 == 0:
		history.append([roundi(time), roundi(shells), total_population()])
		if history.size() > 360:
			history.pop_front()
	var s := season()
	if s != last_season:
		last_season = s
		pass_ver += 1
		if s == WINTER:
			notify({"de": "Der Winter kommt: Gletscherpässe sind gesperrt, Felder und Weiden ruhen.", "en": "Winter arrives: glacier passes close, fields and pastures rest."}, "warn")
		elif s == 0:
			notify({"de": "Frühling! Die Gletscherpässe tauen auf.", "en": "Spring! The glacier passes thaw."}, "info")
	if tick % 600 == 0 and shells < 0:
		notify({"de": "Die Muschelkasse ist leer! Senke den Unterhalt oder versorge deine Leute besser.", "en": "The shell purse is empty! Lower upkeep or supply your people better."}, "warn")


## 0 spring, 1 summer, 2 autumn, 3 winter
func season() -> int:
	return int(time / SEASON_LENGTH) % 4


func is_winter() -> bool:
	return season() == WINTER


func year() -> int:
	return int(time / (SEASON_LENGTH * 4.0)) + 1


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


func storage_cap(v: int) -> int:
	var yards := 0
	for b in buildings.values():
		if b.type == "storage" and b.valley == v:
			yards += 1
	return maxi(1, yards) * STORAGE_PER_YARD


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
			return _no("Entsteht nur durch Aufstieg", "Only obtained by upgrading")
		if not tier_unlocked(def.unlockTier):
			var tn: Dictionary = Content.TIER[def.unlockTier].name
			return _no("Benötigt Stufe " + tn.de, "Requires " + tn.en)
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
	elif vd.owner != owner:
		if owner == PLAYER and vd.owner == null:
			return _no("Gründe hier zuerst einen Lagerplatz", "Found a storage yard here first")
		return _no("Fremdes Tal", "Foreign valley")
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
		if req.get("nearMountain", false) and not _has_near(type, x, y, 1, MOUNTAIN):
			return _no("Muss direkt am Berg stehen", "Must touch a mountain")
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
		b.residents = float(Content.TIER[def.tier].baseResidents)
		b.needs = {}
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

func notify(text: Dictionary, kind := "info") -> void:
	notifications.append({"id": next_note, "t": time, "text": text, "kind": kind})
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


## Prestige ("Ansehen") – the equivalent of Anno's influence.
func prestige() -> int:
	var owned := 0
	for v in valleys:
		if v.owner == PLAYER:
			owned += 1
	var top := 0
	for t in unlocked_tiers:
		top = maxi(top, Content.tier_index(t))
	return total_population() / 10 + owned * 5 + top * 10


# ---------------------------------------------------------------- save / load

const SAVED_FIELDS := ["size", "terrain", "valley", "nature", "road", "pass_of", "deposit", "seed", "tick", "time", "valleys", "passes",
	"buildings", "next_id", "shells", "unlocked_tiers", "upgrade_allowed", "caravans", "pass_ver", "last_season", "expedition", "trader", "rivals",
	"notifications", "next_note", "objectives", "history"]


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
	w.bmap.resize(w.size * w.size)
	w.bmap.fill(0)
	for b in w.buildings.values():
		for p in w.footprint(b.type, b.x, b.y):
			w.bmap[w.idx(p.x, p.y)] = b.id
	w.dirty += 1
	return w


## Cheap checksum for desync detection in lockstep multiplayer.
func checksum() -> int:
	var h := tick * 31 + roundi(shells * 100)
	var ids := buildings.keys()
	ids.sort()
	for id in ids:
		var b: Dictionary = buildings[id]
		h = SimNoise.imul(h, 16777619) ^ (b.id * 7 + b.x * 13 + b.y * 17 + roundi(b.get("residents", 0.0) * 10))
	return h
