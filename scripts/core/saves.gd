class_name Saves
## Save slots in user://saves (Steam Cloud can sync this folder). Compressed binary Variant files.

const DIR := "user://saves"


static func _path(slot: String) -> String:
	return "%s/%s.sav" % [DIR, slot]


static func save(slot: String, name: String, w: World) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open_compressed(_path(slot), FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return false
	f.store_var({"meta": {"name": name, "time": w.time, "saved_at": Time.get_unix_time_from_system(), "population": w.total_population()}, "world": w.to_dict()})
	f.close()
	return true


static func load_world(slot: String) -> World:
	var f := FileAccess.open_compressed(_path(slot), FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return null
	var d = f.get_var()
	f.close()
	if not d is Dictionary or not d.has("world"):
		return null
	return World.from_dict(d.world)


static func list() -> Array:
	var out := []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	for file in dir.get_files():
		if not file.ends_with(".sav"):
			continue
		var f := FileAccess.open_compressed("%s/%s" % [DIR, file], FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
		if f == null:
			continue
		var d = f.get_var()
		f.close()
		if d is Dictionary and d.has("meta"):
			var m: Dictionary = d.meta
			m.slot = file.get_basename()
			out.append(m)
	out.sort_custom(func(a, b): return a.saved_at > b.saved_at)
	return out


static func delete(slot: String) -> void:
	DirAccess.remove_absolute(_path(slot))


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(_path(slot))
