class_name IconBaker
## Renders every building's 3D model once into a small transparent picture for the build bar and
## panels, so the interface always shows the same models as the world (also swapped .glb models).

const SIZE := 192

static var icons := {}


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
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	for id in ports:
		var img: Image = ports[id].get_texture().get_image()
		if img and not img.is_empty():
			img.generate_mipmaps()
			icons[id] = ImageTexture.create_from_image(img)
		ports[id].queue_free()


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
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe9c8")
	sun.light_energy = 1.1
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-20.0), 0.0)
	vp.add_child(sun)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9cdd6")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
