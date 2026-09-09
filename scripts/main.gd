extends Node3D

const BLOCKS_PATH := "res://assets/blocks.json"
const WORLDGEN_PATH := "res://assets/worldgen.json"
const SAVE_PATH := "user://blockforge_alpha_world.json"
const EYE_HEIGHT := 1.62
const PLAYER_RADIUS := 0.32
const PLAYER_HEIGHT := 1.82
const GRAVITY := 22.0
const WALK_SPEED := 5.2
const JUMP_SPEED := 8.4
const LOOK_SPEED := 0.0024
const FACE_RIGHT := 0
const FACE_LEFT := 1
const FACE_UP := 2
const FACE_DOWN := 3
const FACE_FORWARD := 4
const FACE_BACK := 5
const CHUNK_SIZE := 16
const HUD_REFRESH_TIME := 0.15

const AudioLibraryScript := preload("res://scripts/systems/audio_library.gd")
const BlockMaterialFactoryScript := preload("res://scripts/world/block_material_factory.gd")
const PatchNotesControllerScript := preload("res://scripts/ui/patch_notes_controller.gd")
const SelectionOutlineScript := preload("res://scripts/world/selection_outline.gd")
const TextureCacheScript := preload("res://scripts/utils/texture_cache.gd")
const VoxelMathScript := preload("res://scripts/world/voxel_math.gd")

var camera: Camera3D
var world_environment: WorldEnvironment
var title_layer: CanvasLayer
var hud_layer: CanvasLayer
var patch_notes_controller
var status_label: Label
var debug_label: Label
var hotbar_box: HBoxContainer
var crosshair: Control
var selected_outline: MeshInstance3D
var audio_library
var block_material_factory
var texture_loader

var blocks := {}
var hotbar := []
var world := {}
var chunk_blocks := {}
var chunk_nodes := {}
var chunk_face_counts := {}
var selected_slot := 0
var selected_target = null
var worldgen := {}
var world_seed := 1
var block_count := 0
var velocity := Vector3.ZERO
var grounded := false
var game_active := false
var retro_fog := false
var message := "Clique sur Jouer pour commencer."
var step_timer := 0.0
var hud_timer := 0.0


func _ready() -> void:
	randomize()
	texture_loader = TextureCacheScript.new()
	block_material_factory = BlockMaterialFactoryScript.new()
	block_material_factory.setup(texture_loader)
	_load_game_data()
	_setup_rendering()
	_setup_audio()
	_setup_ui()
	_generate_world()
	_rebuild_meshes()
	_spawn_player()
	_update_hud()


func _physics_process(delta: float) -> void:
	if not game_active:
		return
	_update_movement(delta)
	_update_target()
	hud_timer -= delta
	if hud_timer <= 0.0:
		hud_timer = HUD_REFRESH_TIME
		_update_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)

	if not game_active:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_break_target()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_place_target()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_slot(selected_slot - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_slot(selected_slot + 1)


func _load_game_data() -> void:
	var block_data = JSON.parse_string(FileAccess.get_file_as_string(BLOCKS_PATH))
	var world_data = JSON.parse_string(FileAccess.get_file_as_string(WORLDGEN_PATH))
	if typeof(block_data) != TYPE_DICTIONARY:
		push_error("Impossible de lire assets/blocks.json")
		return
	if typeof(world_data) != TYPE_DICTIONARY:
		push_error("Impossible de lire assets/worldgen.json")
		return

	worldgen = world_data
	world_seed = int(worldgen.get("seed", 1))
	hotbar = block_data.get("hotbar", [])

	for block in block_data.get("blocks", []):
		var id := String(block.get("id", ""))
		if id == "":
			continue
		block["materials"] = block_material_factory.create_block_materials(block)
		blocks[id] = block


func _setup_rendering() -> void:
	camera = Camera3D.new()
	camera.name = "PlayerCamera"
	camera.fov = 72.0
	camera.near = 0.04
	camera.far = 180.0
	camera.rotation_order = EULER_ORDER_YXZ
	add_child(camera)

	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.72, 0.95)
	sky_mat.sky_horizon_color = Color(0.86, 0.94, 0.86)
	sky_mat.ground_bottom_color = Color(0.27, 0.37, 0.22)
	sky_mat.ground_horizon_color = Color(0.62, 0.78, 0.54)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.58
	env.fog_enabled = false
	env.fog_light_color = Color(0.72, 0.82, 0.9)
	env.fog_density = 0.0012
	world_environment.environment = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.92, 0.72)
	sun.light_energy = 1.25
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-52, -38, 0)
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.name = "SkyFill"
	fill.light_color = Color(0.55, 0.68, 1.0)
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-20, 130, 0)
	add_child(fill)

	# Clouds are disabled in this pre-alpha patch because the old block strips made the sky look broken.
	selected_outline = MeshInstance3D.new()
	selected_outline.name = "SelectedBlockOutline"
	selected_outline.mesh = SelectionOutlineScript.create_mesh()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.018, 0.012, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = false
	selected_outline.material_override = mat
	selected_outline.visible = false
	add_child(selected_outline)


func _setup_audio() -> void:
	audio_library = AudioLibraryScript.new()
	audio_library.name = "AudioLibrary"
	add_child(audio_library)
	audio_library.setup(["break", "place", "jump", "menu", "step", "music"])


func _setup_ui() -> void:
	title_layer = CanvasLayer.new()
	title_layer.name = "TitleLayer"
	add_child(title_layer)

	var title_root := Control.new()
	title_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(title_root)

	var background := TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = _load_png_texture("res://assets/ui/title-panorama.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_root.add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.05, 0.04, 0.48)
	title_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 430)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var build := Label.new()
	build.text = "PRE-ALPHA DESKTOP 0.2.6"
	build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(build)

	var title := Label.new()
	title.text = "BlockForge\nAlpha"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 58)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Survie voxel locale, fichiers ouverts, modding prévu."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)

	var play_button := Button.new()
	play_button.text = "Jouer"
	play_button.custom_minimum_size = Vector2(210, 44)
	play_button.pressed.connect(_start_game)
	actions.add_child(play_button)

	var new_world_button := Button.new()
	new_world_button.text = "Nouveau monde"
	new_world_button.custom_minimum_size = Vector2(210, 44)
	new_world_button.pressed.connect(_new_world_from_menu)
	actions.add_child(new_world_button)

	var patch_button := Button.new()
	patch_button.text = "Patch Notes"
	patch_button.custom_minimum_size = Vector2(210, 44)
	patch_button.pressed.connect(_show_patch_notes)
	actions.add_child(patch_button)

	var quit_button := Button.new()
	quit_button.text = "Quitter"
	quit_button.custom_minimum_size = Vector2(210, 44)
	quit_button.pressed.connect(get_tree().quit)
	actions.add_child(quit_button)

	hud_layer = CanvasLayer.new()
	hud_layer.name = "HudLayer"
	add_child(hud_layer)

	status_label = Label.new()
	status_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_label.position = Vector2(14, 12)
	status_label.size = Vector2(780, 90)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_layer.add_child(status_label)

	debug_label = Label.new()
	debug_label.anchor_left = 1.0
	debug_label.anchor_right = 1.0
	debug_label.anchor_top = 0.0
	debug_label.anchor_bottom = 0.0
	debug_label.offset_left = -314.0
	debug_label.offset_top = 12.0
	debug_label.offset_right = -14.0
	debug_label.offset_bottom = 132.0
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	debug_label.add_theme_color_override("font_color", Color(0.85, 0.94, 0.72))
	debug_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	debug_label.add_theme_constant_override("shadow_offset_x", 2)
	debug_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_layer.add_child(debug_label)

	crosshair = Control.new()
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	hud_layer.add_child(crosshair)
	_add_crosshair_line(Vector2(-9, -1), Vector2(18, 2))
	_add_crosshair_line(Vector2(-1, -9), Vector2(2, 18))

	hotbar_box = HBoxContainer.new()
	hotbar_box.anchor_left = 0.5
	hotbar_box.anchor_right = 0.5
	hotbar_box.anchor_top = 1.0
	hotbar_box.anchor_bottom = 1.0
	hotbar_box.offset_left = -250.0
	hotbar_box.offset_top = -66.0
	hotbar_box.offset_right = 250.0
	hotbar_box.offset_bottom = -14.0
	hotbar_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_box.add_theme_constant_override("separation", 4)
	hud_layer.add_child(hotbar_box)
	_rebuild_hotbar()
	_setup_patch_notes_ui()


func _add_crosshair_line(pos: Vector2, size: Vector2) -> void:
	var line := ColorRect.new()
	line.position = pos
	line.size = size
	line.color = Color(1, 1, 1, 0.82)
	crosshair.add_child(line)


func _setup_patch_notes_ui() -> void:
	patch_notes_controller = PatchNotesControllerScript.new()
	patch_notes_controller.name = "PatchNotesController"
	patch_notes_controller.closed.connect(_on_patch_notes_closed)
	add_child(patch_notes_controller)
	patch_notes_controller.setup()


func _load_png_texture(path: String) -> Texture2D:
	return texture_loader.load_png(path) as Texture2D


func _generate_world() -> void:
	world.clear()
	chunk_blocks.clear()
	world_seed = int(worldgen.get("seed", 1))
	if bool(worldgen.get("randomSeedOnStart", false)):
		world_seed += randi_range(0, 999999)
	var size := int(worldgen.get("size", 44))
	var half: int = int(size / 2)
	var water_level := int(worldgen.get("waterLevel", 8))
	var water_enabled := bool(worldgen.get("waterEnabled", false))
	var tree_spots := []

	for x in range(-half, half + 1):
		for z in range(-half, half + 1):
			var height := _terrain_height(x, z)
			for y in range(0, height + 1):
				var id := "stone"
				if y == height:
					id = "sand" if height <= water_level + 1 else "grass"
				elif y > height - 4:
					id = "sand" if height <= water_level + 1 else "dirt"
				elif VoxelMathScript.hash3(x, y, z, world_seed) < float(worldgen.get("oreChance", 0.016)):
					id = "cobble"
				_set_block(x, y, z, id)

			if water_enabled and height < water_level:
				for y in range(height + 1, water_level + 1):
					_set_block(x, y, z, "water")

			if height > water_level + 2 and (abs(x) > 20 or abs(z) > 20) and VoxelMathScript.hash2(x * 3, z * 3, world_seed) < float(worldgen.get("treeChance", 0.006)):
				tree_spots.append(Vector3i(x, height + 1, z))

	for spot in tree_spots:
		_grow_tree(spot.x, spot.y, spot.z)

	_clear_spawn_area()
	_add_showcase_details()
	message = "Nouveau monde généré."


func _terrain_height(x: int, z: int) -> int:
	var water_level := int(worldgen.get("waterLevel", 8))
	var max_height := int(worldgen.get("maxHeight", 24))
	var plateau_radius := int(worldgen.get("spawnPlateauRadius", 13))
	var plateau_height := int(worldgen.get("spawnPlateauHeight", water_level + 4))
	if String(worldgen.get("terrainMode", "")) == "showcase_flat":
		return plateau_height
	var dist: int = maxi(abs(x), abs(z))
	if dist <= plateau_radius:
		return plateau_height
	var n: float = VoxelMathScript.value_noise(x * 0.07, z * 0.07, world_seed)
	n += VoxelMathScript.value_noise(x * 0.16 + 80.0, z * 0.16 - 31.0, world_seed) * 0.45
	var natural: float = float(plateau_height) + n * 3.0 - 1.0
	var blend: float = clampf(float(dist - plateau_radius) / 6.0, 0.0, 1.0)
	return clampi(roundi(lerpf(float(plateau_height), natural, blend)), 2, max_height)


func _add_showcase_details() -> void:
	if String(worldgen.get("terrainMode", "")) != "showcase_flat":
		return
	var ground_y := int(worldgen.get("spawnPlateauHeight", int(worldgen.get("waterLevel", 6)) + 4))
	for x in range(-22, 23):
		for z in range(-22, 23):
			var border := maxi(abs(x), abs(z))
			if border > 20:
				if VoxelMathScript.hash2(x, z, world_seed + 19) < 0.33:
					_set_block(x, ground_y, z, "stone")
				continue
			if border > 9 and VoxelMathScript.hash2(x * 5, z * 5, world_seed + 31) < 0.012:
				_set_block(x, ground_y + 1, z, "log")
			elif border > 7 and VoxelMathScript.hash2(x * 7, z * 7, world_seed + 53) < 0.018:
				_set_block(x, ground_y + 1, z, "cobble")
	for spot in [Vector2i(-14, -12), Vector2i(15, -10), Vector2i(-16, 13), Vector2i(13, 15)]:
		_grow_tree(spot.x, ground_y + 1, spot.y)


func _grow_tree(x: int, y: int, z: int) -> void:
	var height := 4 + int(VoxelMathScript.hash2(x, z, world_seed + 77) * 3.0)
	for i in range(height):
		_set_block(x, y + i, z, "log")
	var crown_y := y + height
	for ox in range(-2, 3):
		for oy in range(-2, 2):
			for oz in range(-2, 3):
				var distance: float = abs(ox) + abs(oy) * 0.8 + abs(oz)
				if distance < 4.1 and VoxelMathScript.hash3(x + ox, crown_y + oy, z + oz, world_seed) > 0.13:
					if _get_block(x + ox, crown_y + oy, z + oz) == "":
						_set_block(x + ox, crown_y + oy, z + oz, "leaves")


func _clear_spawn_area() -> void:
	var water_level := int(worldgen.get("waterLevel", 6))
	var max_y := int(worldgen.get("maxHeight", 20)) + 12
	var radius := int(worldgen.get("spawnPlateauRadius", 13))
	var plateau_height := int(worldgen.get("spawnPlateauHeight", water_level + 4))
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			var ground_y := _highest_ground_y(x, z)
			if maxi(abs(x), abs(z)) <= radius:
				for y in range(0, max_y + 1):
					if y < plateau_height - 3:
						_set_block(x, y, z, "stone")
					elif y < plateau_height:
						_set_block(x, y, z, "dirt")
					elif y == plateau_height:
						_set_block(x, y, z, "grass")
					else:
						_set_block(x, y, z, "")
				continue
			for y in range(max(water_level + 1, ground_y + 1), max_y + 1):
				var id := _get_block(x, y, z)
				if id == "leaves" or id == "log" or id == "water":
					_set_block(x, y, z, "")


func _rebuild_meshes() -> void:
	for chunk_key in chunk_nodes.keys():
		_clear_chunk_meshes(chunk_key)
	chunk_nodes.clear()
	chunk_face_counts.clear()
	block_count = 0

	var chunks_to_build := {}
	for key in world.keys():
		var p := _parse_key(key)
		chunks_to_build[VoxelMathScript.chunk_key_for_block(p, CHUNK_SIZE)] = true

	for chunk_key in chunks_to_build.keys():
		_rebuild_chunk(chunk_key)


func _rebuild_nearby_chunks(pos: Vector3i) -> void:
	var chunks_to_build := {}
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.RIGHT, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.LEFT, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.FORWARD, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.BACK, CHUNK_SIZE)] = true
	for chunk_key in chunks_to_build.keys():
		_rebuild_chunk(chunk_key)
	_update_hud()


func _clear_chunk_meshes(chunk_key: String) -> void:
	for node in chunk_nodes.get(chunk_key, []):
		if is_instance_valid(node):
			node.queue_free()
	block_count -= int(chunk_face_counts.get(chunk_key, 0))
	chunk_nodes.erase(chunk_key)
	chunk_face_counts.erase(chunk_key)


func _rebuild_chunk(chunk_key: String) -> void:
	_clear_chunk_meshes(chunk_key)
	var keys: Array = chunk_blocks.get(chunk_key, {}).keys()
	if keys.is_empty():
		return

	var face_groups := {}
	for key in keys:
		var id: String = world[key]
		var p := _parse_key(key)
		if not blocks.has(id):
			continue
		var block: Dictionary = blocks[id]
		for face in range(6):
			var d := VoxelMathScript.face_dir(face)
			var neighbor_id := _get_block(p.x + d.x, p.y + d.y, p.z + d.z)
			var neighbor: Dictionary = blocks.get(neighbor_id, {})
			if _should_render_face(id, neighbor_id, face):
				_append_face(face_groups, id, face, p)

	for group_key in face_groups.keys():
		var group: Dictionary = face_groups[group_key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = group["vertices"]
		arrays[Mesh.ARRAY_NORMAL] = group["normals"]
		arrays[Mesh.ARRAY_TEX_UV] = group["uvs"]
		arrays[Mesh.ARRAY_INDEX] = group["indices"]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, group["material"])

		var instance := MeshInstance3D.new()
		instance.name = "VoxelFaces_" + group_key
		instance.mesh = mesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
		if not chunk_nodes.has(chunk_key):
			chunk_nodes[chunk_key] = []
		chunk_nodes[chunk_key].append(instance)
		chunk_face_counts[chunk_key] = int(chunk_face_counts.get(chunk_key, 0)) + int(group["face_count"])
	block_count += int(chunk_face_counts.get(chunk_key, 0))


func _append_face(face_groups: Dictionary, id: String, face: int, pos: Vector3i) -> void:
	var group_key := "%s_%d" % [id, face]
	if not face_groups.has(group_key):
		var block: Dictionary = blocks[id]
		var materials: Array = block["materials"]
		face_groups[group_key] = {
			"vertices": PackedVector3Array(),
			"normals": PackedVector3Array(),
			"uvs": PackedVector2Array(),
			"indices": PackedInt32Array(),
			"material": materials[face],
			"face_count": 0
		}

	var group: Dictionary = face_groups[group_key]
	var vertices: PackedVector3Array = group["vertices"]
	var normals: PackedVector3Array = group["normals"]
	var uvs: PackedVector2Array = group["uvs"]
	var indices: PackedInt32Array = group["indices"]
	var base_index := vertices.size()
	var normal := Vector3(VoxelMathScript.face_dir(face))
	var corners := VoxelMathScript.face_vertices(face)
	var offset := Vector3(pos)

	for corner in corners:
		vertices.append(corner + offset)
		normals.append(normal)

	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(0, 0))
	indices.append_array(PackedInt32Array([base_index, base_index + 1, base_index + 2, base_index, base_index + 2, base_index + 3]))

	group["vertices"] = vertices
	group["normals"] = normals
	group["uvs"] = uvs
	group["indices"] = indices
	group["face_count"] = int(group["face_count"]) + 1
	face_groups[group_key] = group


func _should_render_face(id: String, neighbor_id: String, face: int) -> bool:
	var block: Dictionary = blocks.get(id, {})
	if bool(block.get("liquid", false)):
		return face == FACE_UP and neighbor_id != id
	if neighbor_id == "":
		return true
	if neighbor_id == id:
		return false
	var neighbor: Dictionary = blocks.get(neighbor_id, {})
	var block_is_clear := bool(block.get("transparent", false)) or bool(block.get("liquid", false))
	var neighbor_is_clear := bool(neighbor.get("transparent", false)) or bool(neighbor.get("liquid", false))
	if block_is_clear:
		return neighbor_is_clear or not bool(neighbor.get("solid", false))
	return neighbor_is_clear


func _is_visible_block(x: int, y: int, z: int, id: String) -> bool:
	var block: Dictionary = blocks.get(id, {})
	var dirs := [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.UP, Vector3i.DOWN, Vector3i.FORWARD, Vector3i.BACK]
	for face in range(dirs.size()):
		var d: Vector3i = dirs[face]
		var neighbor_id := _get_block(x + d.x, y + d.y, z + d.z)
		var neighbor: Dictionary = blocks.get(neighbor_id, {})
		if _should_render_face(id, neighbor_id, face):
			return true
	return false


func _spawn_player() -> void:
	var spawn := _find_spawn_position()
	camera.position = spawn
	camera.rotation = Vector3(-0.04, -0.65, 0.0)
	velocity = Vector3.ZERO


func _find_spawn_position() -> Vector3:
	var plateau_height := int(worldgen.get("spawnPlateauHeight", int(worldgen.get("waterLevel", 8)) + 4))
	if _get_block(0, plateau_height, 0) == "grass":
		return Vector3(0, plateau_height + 0.58 + EYE_HEIGHT, 0)
	var best := Vector3i.ZERO
	var best_score := 999999
	var water_level := int(worldgen.get("waterLevel", 8))
	for radius in range(0, 14):
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				if abs(x) != radius and abs(z) != radius:
					continue
				var y := _highest_ground_y(x, z)
				if y <= water_level:
					continue
				var id := _get_block(x, y, z)
				if id != "grass" and id != "sand":
					continue
				if _get_block(x, y + 1, z) != "" or _get_block(x, y + 2, z) != "":
					continue
				var score: int = abs(x) + abs(z)
				if score < best_score:
					best = Vector3i(x, y, z)
					best_score = score
		if best_score < 999999:
			break
	return Vector3(best.x, best.y + 0.58 + EYE_HEIGHT, best.z)


func _highest_ground_y(x: int, z: int) -> int:
	for y in range(int(worldgen.get("maxHeight", 24)) + 16, -3, -1):
		var id := _get_block(x, y, z)
		if id == "grass" or id == "sand" or id == "dirt" or id == "stone":
			return y
	return int(worldgen.get("waterLevel", 8)) + 4


func _highest_solid_y(x: int, z: int) -> int:
	for y in range(int(worldgen.get("maxHeight", 24)) + 16, -3, -1):
		var id := _get_block(x, y, z)
		if bool(blocks.get(id, {}).get("solid", false)):
			return y
	return int(worldgen.get("waterLevel", 8)) + 4


func _update_movement(delta: float) -> void:
	var input_x := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q))
	var input_z := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z)) - float(Input.is_key_pressed(KEY_S))
	var forward := -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := camera.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var wish := (forward * input_z + right * input_x)
	if wish.length_squared() > 0:
		wish = wish.normalized()

	var damp := clampf(13.0 * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, wish.x * WALK_SPEED, damp)
	velocity.z = lerpf(velocity.z, wish.z * WALK_SPEED, damp)
	velocity.y = maxf(velocity.y - GRAVITY * delta, -28.0)

	_move_player(Vector3(velocity.x * delta, velocity.y * delta, velocity.z * delta))

	step_timer -= delta
	if grounded and Vector2(velocity.x, velocity.z).length() > 1.4 and step_timer <= 0.0:
		_play_sfx("step")
		step_timer = 0.38


func _move_player(delta: Vector3) -> void:
	grounded = false
	for axis in ["x", "z", "y"]:
		var candidate := camera.position
		candidate[axis] += delta[axis]
		if _can_occupy(candidate):
			camera.position = candidate
		else:
			if axis == "y":
				if velocity.y < 0:
					grounded = true
				velocity.y = 0
			else:
				velocity[axis] = 0


func _can_occupy(pos: Vector3) -> bool:
	var foot_y := pos.y - EYE_HEIGHT
	var sample_ys := [foot_y + 0.05, foot_y + PLAYER_HEIGHT * 0.5, foot_y + PLAYER_HEIGHT - 0.08]
	for sy in sample_ys:
		for sx in [pos.x - PLAYER_RADIUS, pos.x + PLAYER_RADIUS]:
			for sz in [pos.z - PLAYER_RADIUS, pos.z + PLAYER_RADIUS]:
				var id := _get_block_at_point(Vector3(sx, sy, sz))
				if bool(blocks.get(id, {}).get("solid", false)):
					return false
	return true


func _update_target() -> void:
	selected_target = _voxel_raycast(6.2)
	if selected_target == null:
		selected_outline.visible = false
		return
	selected_outline.position = Vector3(selected_target["pos"])
	selected_outline.visible = true


func _voxel_raycast(max_distance: float):
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z.normalized()
	var previous = null
	var distance: float = 0.08
	while distance <= max_distance:
		var sample := origin + direction * distance
		var pos := Vector3i(floori(sample.x + 0.5), floori(sample.y + 0.5), floori(sample.z + 0.5))
		if previous != null and previous == pos:
			distance += 0.035
			continue
		var id := _get_block(pos.x, pos.y, pos.z)
		if id != "" and not bool(blocks.get(id, {}).get("liquid", false)):
			var normal := Vector3i.ZERO
			if previous != null:
				normal = previous - pos
			else:
				normal = _fallback_normal(direction)
			return {"id": id, "pos": pos, "normal": normal}
		previous = pos
		distance += 0.035
	return null


func _fallback_normal(direction: Vector3) -> Vector3i:
	var ax: float = abs(direction.x)
	var ay: float = abs(direction.y)
	var az: float = abs(direction.z)
	if ax >= ay and ax >= az:
		return Vector3i(-VoxelMathScript.signi(direction.x), 0, 0)
	if ay >= ax and ay >= az:
		return Vector3i(0, -VoxelMathScript.signi(direction.y), 0)
	return Vector3i(0, 0, -VoxelMathScript.signi(direction.z))


func _break_target() -> void:
	if selected_target == null:
		message = "Aucun bloc à portée."
		return
	var pos: Vector3i = selected_target["pos"]
	var id: String = selected_target["id"]
	_set_block(pos.x, pos.y, pos.z, "")
	_play_sfx("break")
	message = "%s cassé." % String(blocks.get(id, {}).get("name", id))
	_rebuild_nearby_chunks(pos)


func _place_target() -> void:
	if selected_target == null:
		message = "Vise une face de bloc pour construire."
		return
	var id := String(hotbar[selected_slot])
	var pos: Vector3i = selected_target["pos"] + selected_target["normal"]
	if _would_intersect_player(pos):
		message = "Impossible de poser un bloc ici."
		return
	_set_block(pos.x, pos.y, pos.z, id)
	_play_sfx("place")
	message = "%s posé." % String(blocks.get(id, {}).get("name", id))
	_rebuild_nearby_chunks(pos)


func _would_intersect_player(block_pos: Vector3i) -> bool:
	var p := camera.position
	var foot_y := p.y - EYE_HEIGHT
	return absf(p.x - block_pos.x) < PLAYER_RADIUS + 0.55 and absf(p.z - block_pos.z) < PLAYER_RADIUS + 0.55 and foot_y < block_pos.y + 0.5 and foot_y + PLAYER_HEIGHT > block_pos.y - 0.5


func _start_game() -> void:
	game_active = true
	title_layer.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_play_sfx("menu")
	audio_library.play_music()
	message = "Bienvenue dans la pré-alpha desktop."


func _pause_game() -> void:
	game_active = false
	title_layer.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	message = "Pause."


func _show_patch_notes() -> void:
	patch_notes_controller.open_panel()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sfx("menu")


func _hide_patch_notes() -> void:
	_play_sfx("menu")
	patch_notes_controller.close_panel()


func _on_patch_notes_closed() -> void:
	if game_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _new_world_from_menu() -> void:
	_generate_world()
	_rebuild_meshes()
	_spawn_player()
	_play_sfx("menu")
	_update_hud()


func _handle_key(keycode: int) -> void:
	if keycode == KEY_ESCAPE and patch_notes_controller != null and patch_notes_controller.is_open():
		_hide_patch_notes()
		return
	if keycode == KEY_ESCAPE and game_active:
		_pause_game()
		return
	if keycode >= KEY_1 and keycode <= KEY_9:
		_select_slot(keycode - KEY_1)
	elif keycode == KEY_SPACE and game_active and grounded:
		velocity.y = JUMP_SPEED
		grounded = false
		_play_sfx("jump")
	elif keycode == KEY_F:
		retro_fog = not retro_fog
		world_environment.environment.fog_enabled = retro_fog
		world_environment.environment.fog_density = 0.0012
		message = "Brume douce activée." if retro_fog else "Vue nette activée."
	elif keycode == KEY_R:
		_new_world_from_menu()


func _rotate_view(relative: Vector2) -> void:
	camera.rotation.y -= relative.x * LOOK_SPEED
	camera.rotation.x -= relative.y * LOOK_SPEED
	camera.rotation.x = clampf(camera.rotation.x, -PI / 2 + 0.02, PI / 2 - 0.02)


func _select_slot(index: int) -> void:
	selected_slot = posmod(index, min(hotbar.size(), 9))
	_rebuild_hotbar()


func _rebuild_hotbar() -> void:
	for child in hotbar_box.get_children():
		child.queue_free()
	for i in range(min(hotbar.size(), 9)):
		var id := String(hotbar[i])
		var block: Dictionary = blocks.get(id, {})
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(50, 50)
		var label := Label.new()
		label.text = "%d\n%s" % [i + 1, String(block.get("name", id)).left(6)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if i == selected_slot:
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42))
		slot.add_child(label)
		hotbar_box.add_child(slot)


func _update_hud() -> void:
	var block_name := "?"
	if selected_slot < hotbar.size():
		block_name = String(blocks.get(String(hotbar[selected_slot]), {}).get("name", hotbar[selected_slot]))
	status_label.text = "%s\nBloc: %s\nZQSD/WASD marcher | clic gauche/droit casser/poser | 1-9 blocs" % [message, block_name]
	debug_label.text = "BlockForge 0.2.6\nx %.1f y %.1f z %.1f\nseed %d\nfaces visibles %d\n%s" % [camera.position.x, camera.position.y, camera.position.z, world_seed, block_count, "brume douce" if retro_fog else "vue nette"]


func _play_sfx(id: String) -> void:
	audio_library.play_sfx(id)


func _set_block(x: int, y: int, z: int, id: String) -> void:
	var key := _block_key(x, y, z)
	var chunk_key := VoxelMathScript.chunk_key_for_block(Vector3i(x, y, z), CHUNK_SIZE)
	if id == "":
		world.erase(key)
		if chunk_blocks.has(chunk_key):
			chunk_blocks[chunk_key].erase(key)
			if chunk_blocks[chunk_key].is_empty():
				chunk_blocks.erase(chunk_key)
	else:
		world[key] = id
		if not chunk_blocks.has(chunk_key):
			chunk_blocks[chunk_key] = {}
		chunk_blocks[chunk_key][key] = true


func _get_block(x: int, y: int, z: int) -> String:
	return String(world.get(_block_key(x, y, z), ""))


func _get_block_at_point(point: Vector3) -> String:
	return _get_block(floori(point.x + 0.5), floori(point.y + 0.5), floori(point.z + 0.5))


func _block_key(x: int, y: int, z: int) -> String:
	return "%d,%d,%d" % [x, y, z]


func _parse_key(key: String) -> Vector3i:
	var parts := key.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
