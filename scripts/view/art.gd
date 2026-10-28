class_name Art
## Asset access by id. Every texture is a plain PNG under res://assets – replace a file to replace the art.
## Modders can also drop files into user://mods/assets/<same path> without rebuilding the game.

const TW := 64.0
const TH := 32.0
const SPRITE_SCALE := 0.5 # sprites are painted at 2x for crisp zooming

static var _tex := {}
static var _anchors := {}


static func tex(id: String) -> Texture2D:
	if _tex.has(id):
		return _tex[id]
	var t: Texture2D = null
	var mod := "user://mods/assets/%s.png" % id
	if FileAccess.file_exists(mod):
		var img := Image.load_from_file(mod)
		if img:
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
	if t == null and ResourceLoader.exists("res://assets/%s.png" % id):
		t = load("res://assets/%s.png" % id)
	_tex[id] = t
	return t


## Anchor in texture pixels (the point that sits on the ground).
static func anchor(id: String) -> Vector2:
	if _anchors.is_empty():
		var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites.json"))
		_anchors = data if data is Dictionary else {"_": {}}
	var a = _anchors.get(id, {}).get("anchor", null)
	if a == null:
		var t := tex(id)
		return Vector2(t.get_width() / 2.0, t.get_height()) if t else Vector2.ZERO
	return Vector2(a[0], a[1])


static func iso(x: float, y: float) -> Vector2:
	return Vector2((x - y) * TW / 2.0, (x + y) * TH / 2.0)


static func un_iso(p: Vector2) -> Vector2:
	var a := p.x / (TW / 2.0)
	var b := p.y / (TH / 2.0)
	return Vector2((a + b) / 2.0, (b - a) / 2.0)


## Configures a sprite so that `ground` (world px) carries the texture's anchor while the node itself
## sits at `sort` (used for y-sorting).
static func setup_sprite(s: Sprite2D, id: String, ground: Vector2, sort: Vector2) -> void:
	s.texture = tex(id)
	s.centered = false
	s.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	s.position = sort
	s.offset = -anchor(id) + (ground - sort) / SPRITE_SCALE


static func good_icon(id: String) -> Texture2D:
	return tex("goods/" + id)


static func building_icon(id: String) -> Texture2D:
	return tex("buildings/" + id)
