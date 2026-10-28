extends Node
## Dev tool: writes the generated map as a PNG and prints pass lengths and valley sizes.
## godot --headless --path . res://tools/mapdump.tscn  (SEED=n, OUT=path)
func _ready():
	_dump()

func _dump() -> void:
	var w := World.create(int(OS.get_environment("SEED") if OS.get_environment("SEED") != "" else "1"))
	var img := Image.create(w.size, w.size, false, Image.FORMAT_RGB8)
	for i in w.size * w.size:
		var c := Color(0.3, 0.3, 0.3)
		match w.terrain[i]:
			World.GRASS: c = Color(0.4, 0.7, 0.3).lerp(Color.WHITE, (w.valley[i] % 4) * 0.12)
			World.WATER: c = Color(0.2, 0.4, 0.8)
			World.PASS:
				var p = w.passes[w.pass_of[i]]
				c = {"none": Color(0.9, 0.8, 0.5), "scree": Color(0.6, 0.5, 0.4), "river": Color(0.3, 0.8, 0.9), "gorge": Color(0.1, 0.1, 0.1), "glacier": Color(1, 1, 1)}[p.obstacle]
		if w.nature[i] == World.N_TREE: c = c.darkened(0.3)
		img.set_pixel(i % w.size, i / w.size, c)
	img.resize(w.size * 3, w.size * 3, Image.INTERPOLATE_NEAREST)
	img.save_png(OS.get_environment("OUT") if OS.get_environment("OUT") != "" else "user://map.png")
	for p in w.passes:
		print(p.idx, " ", w.valleys[p.a].def, "-", w.valleys[p.b].def, " ", p.tiles.size(), " ", p.obstacle)
	for v in w.valleys:
		var n := 0
		for i in w.valley.size():
			if w.valley[i] == v.idx and w.terrain[i] == World.GRASS: n += 1
		print(v.def, " ", n)
	get_tree().quit()

