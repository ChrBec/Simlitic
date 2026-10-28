extends Node
## Procedural placeholder audio: soft bone-flute melody over frame drums, wind, and UI sounds.
## Any cue can be replaced by dropping a file into res://assets/audio/ (e.g. music_main.ogg, sfx_build.wav).

const RATE := 22050

var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer


func _ready() -> void:
	for bus in ["Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_sfx = {
		"click": _custom("sfx_click", func(): return _knock(900, 0.06, 0.25)),
		"build": _custom("sfx_build", func(): return _mix([_knock(180, 0.12, 0.6), _delay(_knock(220, 0.1, 0.5), 0.12)])),
		"demolish": _custom("sfx_demolish", func(): return _knock(120, 0.25, 0.6)),
		"error": _custom("sfx_error", func(): return _tone(160, 0.18, 0.15, true)),
		"upgrade": _custom("sfx_upgrade", func(): return _mix([_tone(440, 0.3, 0.2), _delay(_tone(554, 0.3, 0.2), 0.09), _delay(_tone(659, 0.35, 0.2), 0.18)])),
		"tier": _custom("sfx_tier", func(): return _mix([_flute(294, 1.2), _delay(_flute(392, 1.2), 0.25), _delay(_flute(440, 1.2), 0.5), _delay(_flute(587, 1.6), 0.75), _knock(60, 0.6, 0.8)])),
	}
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	add_child(_ambience)
	Settings.changed.connect(_apply_volumes)
	_apply_volumes()
	if DisplayServer.get_name() != "headless":
		_music.stream = _custom("music_main", _make_music)
		_ambience.stream = _custom("ambience_wind", _make_wind)
		_music.play()
		_ambience.play()


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(Settings.data.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Settings.data.music_volume * 0.7))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(Settings.data.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), linear_to_db(Settings.data.ambience_volume * 0.5))


func play(kind: String) -> void:
	if not _sfx.has(kind):
		return
	for p in _players:
		if not p.playing:
			p.stream = _sfx[kind]
			p.play()
			return


## Uses res://assets/audio/<id>.ogg|.wav when present, otherwise the generated placeholder.
func _custom(id: String, make: Callable) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/audio/%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			return load(path)
	var samples: PackedFloat32Array = make.call()
	return _to_wav(samples, id.begins_with("music") or id.begins_with("ambience"))


func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w


func _tone(freq: float, dur: float, vol: float, square := false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * freq * t)
		if square:
			s = signf(s) * 0.6
		out[i] = s * vol * exp(-t * 6.0 / dur) * minf(1.0, t * 200.0)
	return out


func _knock(freq: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := freq * (1.6 - 0.6 * minf(1.0, t / dur))
		phase += TAU * f / RATE
		out[i] = sin(phase) * vol * exp(-t * 7.0 / dur)
	return out


func _flute(freq: float, dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * freq * (1.0 + 0.008 * sin(TAU * 5.0 * t)) / RATE
		var env := minf(1.0, t / 0.12) * clampf((dur - t) / (dur * 0.4), 0.0, 1.0)
		out[i] = (sin(phase) + 0.15 * sin(phase * 2.0)) * 0.12 * env + (randf() - 0.5) * 0.01 * env
	return out


func _delay(s: PackedFloat32Array, sec: float) -> PackedFloat32Array:
	var pad := PackedFloat32Array()
	pad.resize(int(sec * RATE))
	pad.append_array(s)
	return pad


func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, p.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out


## A 25 second loop: pentatonic flute phrases over a slow frame-drum pattern.
func _make_music() -> PackedFloat32Array:
	var beat := 0.42
	var beats := 60
	var out := PackedFloat32Array()
	out.resize(int(beat * beats * RATE) + RATE * 2)
	var scale := [0, 3, 5, 7, 10, 12, 15]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1996
	for b in beats:
		var at := int(b * beat * RATE)
		var hits := []
		if b % 4 == 0:
			hits.append(_knock(70, 0.5, 0.35))
		elif b % 4 == 2 and rng.randf() > 0.3:
			hits.append(_knock(110, 0.3, 0.18))
		if b % 2 == 0 and rng.randf() > 0.45:
			hits.append(_flute(293.66 * pow(2.0, scale[rng.randi_range(0, scale.size() - 1)] / 12.0), 0.6 + rng.randf() * 1.2))
		for h in hits:
			for i in h.size():
				if at + i < out.size():
					out[at + i] += h[i]
	out.resize(int(beat * beats * RATE))
	return out


func _make_wind() -> PackedFloat32Array:
	var n := RATE * 6
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	for i in n:
		last = (last + (randf() * 2.0 - 1.0) * 0.02) * 0.995
		out[i] = last * 1.5
	return out
