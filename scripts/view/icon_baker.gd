class_name IconBaker
## Renders every building's 3D model once into a small transparent picture for the build bar and
## panels, so the interface always shows the same models as the world (also swapped .glb models).

const SIZE := 192

static var icons := {}
static var portraits := {}


static func bake(host: Node) -> void:
	if DisplayServer.get_name() == "headless" or not icons.is_empty():
		return
	var ports := {}
	for def in Content.buildings:
		if def.style == "path":
			continue
		var vp := SubViewport.new()
		vp.size = Vector2i(SIZE, SIZE)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		host.add_child(vp)
		_stage(vp, def)
		ports[def.id] = vp
	var faces := {}
	for c in Content.characters:
		var vp := SubViewport.new()
		vp.size = Vector2i(SIZE, SIZE)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		host.add_child(vp)
		_stage_face(vp, c.id)
		faces[c.id] = vp
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	for id in ports:
		var img: Image = ports[id].get_texture().get_image()
		if img and not img.is_empty():
			img.generate_mipmaps()
			icons[id] = ImageTexture.create_from_image(img)
		ports[id].queue_free()
	for id in faces:
		var img: Image = faces[id].get_texture().get_image()
		if img and not img.is_empty():
			img.generate_mipmaps()
			portraits[id] = ImageTexture.create_from_image(img)
		faces[id].queue_free()


## Head-and-shoulders portrait of a character, lit like the world.
static func _stage_face(vp: SubViewport, id: String) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.mesh("chars/" + id)
	vp.add_child(mi)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.42
	var look := Vector3(0, 0.47, 0)
	cam.position = look + Vector3(0.35, 0.12, 1.2)
	vp.add_child(cam)
	cam.look_at(look, Vector3.UP)
	_light(vp)


static func _stage(vp: SubViewport, def: Dictionary) -> void:
	var s := float(def.size[0])
	var model := Models.building_node(def.id)
	model.rotation.y = PI
	vp.add_child(model)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = s * 1.05 + 0.9
	var yaw := deg_to_rad(45.0)
	var pitch := deg_to_rad(32.0)
	var look := Vector3(0, 0.55, 0)
	cam.position = look - Vector3(sin(yaw), 0, cos(yaw)) * 20.0 * cos(pitch) + Vector3.UP * 20.0 * sin(pitch)
	vp.add_child(cam)
	cam.look_at(look, Vector3.UP)
	_light(vp)


static func _light(vp: SubViewport) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe9c8")
	sun.light_energy = 1.1
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-20.0), 0.0)
	vp.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4b8d8")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
