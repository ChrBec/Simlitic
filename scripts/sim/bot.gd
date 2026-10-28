class_name Bot
## A tiny scripted player: used by tests, balancing runs and the living main-menu backdrop.


## Lays a cross of paths with side streets around the valley's storage yard.
static func lay_roads(w: World, v: int, arm := 14) -> void:
	var st = w.storage_of(v)
	var cx: int = st.x + 1
	var cy: int = st.y + 1
	var tiles := []
	for d in range(2, arm + 1):
		tiles.append_array([Vector2i(cx + d, cy), Vector2i(cx - d, cy), Vector2i(cx, cy + d), Vector2i(cx, cy - d)])
	for off in [-6, 6]:
		for d in range(-arm, arm + 1):
			tiles.append_array([Vector2i(cx + off, cy + d), Vector2i(cx + d, cy + off)])
	Commands.apply(w, {"type": "path", "tiles": tiles})


## Places a building at the closest valid spot that touches a path.
static func build_near(w: World, v: int, type: String, min_dist := 0.0) -> bool:
	var st = w.storage_of(v)
	var cands := []
	for y in range(st.y - 20, st.y + 21):
		for x in range(st.x - 20, st.x + 21):
			var d := Vector2(x - st.x, y - st.y).length()
			if d >= min_dist:
				cands.append([d, x, y])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var req: Dictionary = Content.BUILDING[type].get("requires", {})
	for c in cands:
		var x: int = c[1]
		var y: int = c[2]
		if not w.check_placement(type, x, y).ok:
			continue
		var touches := false
		for p in w.perimeter(type, x, y):
			if w.inside(p.x, p.y) and w.road[w.idx(p.x, p.y)]:
				touches = true
				break
		if not touches:
			continue
		if req.has("nature"):
			# prefer spots that actually have trees/bushes around
			var probe := {"type": type, "x": x, "y": y}
			var kind := World.N_TREE if req.nature.kind == "tree" else World.N_BUSH
			if w.nature_around(probe, kind, int(req.nature.radius)) < int(req.nature.min):
				continue
		return Commands.apply(w, {"type": "build", "building": type, "x": x, "y": y}).ok
	return false


static func run_minutes(w: World, minutes: float) -> void:
	for i in int(minutes * 600):
		w.step()


## Places a building at the mouth of a pass leaving valley `v` (caravan camps must stand there).
static func build_near_pass(w: World, v: int, type: String) -> bool:
	for p in w.passes:
		if p.a != v and p.b != v:
			continue
		for t in p.tiles:
			var x: int = t % w.size
			var y: int = t / w.size
			for r in range(1, 7):
				for dy in range(-r, r + 1):
					for dx in range(-r, r + 1):
						if w.inside(x + dx, y + dy) and w.valley[w.idx(x + dx, y + dy)] == v and w.check_placement(type, x + dx, y + dy).ok:
							return Commands.apply(w, {"type": "build", "building": type, "x": x + dx, "y": y + dy}).ok
	return false
