extends Node
## Player settings, persisted per machine in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"

var data := {
	"language": "de",
	"master_volume": 0.8, "music_volume": 0.5, "sfx_volume": 0.7, "ambience_volume": 0.5,
	"ui_scale": 1.0, "fullscreen": false, "vsync": true, "quality": "high",
	"edge_scroll": false, "scroll_speed": 1.0, "invert_zoom": false,
	"autosave_minutes": 5, "tutorial_hints": true,
}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in data:
			data[k] = cfg.get_value("settings", k, data[k])
	apply()


func get_value(key: String):
	return data[key]


func set_value(key: String, value) -> void:
	data[key] = value
	apply()
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	for k in data:
		cfg.set_value("settings", k, data[k])
	cfg.save(PATH)


func apply() -> void:
	Content.lang = data.language
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if data.vsync else DisplayServer.VSYNC_DISABLED)
		get_tree().root.content_scale_factor = data.ui_scale
	changed.emit()
