extends Node3D

const BLOCKS_PATH := "res://assets/blocks.json"
const WORLDGEN_PATH := "res://assets/worldgen.json"
const SAVE_PATH := "user://blockforge_alpha_world.json"
const VERSION_LABEL := "0.3.5"
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
const CHUNK_STREAM_CHECK_TIME := 0.25
const CHUNK_REBUILDS_PER_TICK := 1
const CHUNK_GENERATIONS_PER_TICK := 1
const CHUNK_GENERATION_COLUMNS_PER_TICK := 10
const TARGET_REFRESH_TIME := 0.06
const TARGET_RAY_STEP := 0.08
const DROPPED_ITEM_REFRESH_TIME := 0.08
const BLOCK_ACTION_COOLDOWN := 0.09
const MODE_SURVIVAL := "survival"
const MODE_CREATIVE := "creative"
const MAX_HEALTH := 20
const FALL_SAFE_HEIGHT := 4.0

const AudioLibraryScript := preload("res://scripts/systems/audio_library.gd")
const BlockMaterialFactoryScript := preload("res://scripts/world/block_material_factory.gd")
const CraftingBookScript := preload("res://scripts/systems/crafting_book.gd")
const PatchNotesControllerScript := preload("res://scripts/ui/patch_notes_controller.gd")
const PlayerInventoryScript := preload("res://scripts/systems/player_inventory.gd")
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
var health_label: Label
var hotbar_box: HBoxContainer
var inventory_layer: CanvasLayer
var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var recipes_list: VBoxContainer
var game_over_layer: CanvasLayer
var crosshair: Control
var selected_outline: MeshInstance3D
var audio_library
var block_material_factory
var texture_loader
var player_inventory
var crafting_book
var dropped_items_parent: Node3D

var blocks := {}
var placeable_blocks := []
var hotbar := []
var world := {}
var chunk_blocks := {}
var chunk_visible_blocks := {}
var generated_chunk_keys := {}
var chunk_nodes := {}
var chunk_face_counts := {}
var visible_chunk_keys := {}
var chunk_generation_queue := []
var queued_chunk_generations := {}
var active_chunk_generation := {}
var chunk_rebuild_queue := []
var queued_chunk_rebuilds := {}
var selected_slot := 0
var selected_target = null
var worldgen := {}
var world_seed := 1
var block_count := 0
var render_distance_chunks := 1
var last_stream_chunk := Vector2i(999999, 999999)
var velocity := Vector3.ZERO
var grounded := false
var game_active := false
var game_mode := MODE_SURVIVAL
var health := MAX_HEALTH
var fall_start_y := 0.0
var was_grounded := false
var retro_fog := false
var message := "Clique sur Jouer pour commencer."
var step_timer := 0.0
var hud_timer := 0.0
var chunk_stream_timer := 0.0
var target_timer := 0.0
var target_dirty := true
var dropped_item_timer := 0.0
var block_action_timer := 0.0
var bulk_world_update := false
var hotbar_labels := []
var hotbar_last_texts := []
var last_status_text := ""
var last_health_text := ""
var last_debug_text := ""


func _ready() -> void:
	randomize()
	texture_loader = TextureCacheScript.new()
	block_material_factory = BlockMaterialFactoryScript.new()
	block_material_factory.setup(texture_loader)
	player_inventory = PlayerInventoryScript.new()
	crafting_book = CraftingBookScript.new()
	crafting_book.load_recipes()
	_load_game_data()
	_setup_rendering()
	_setup_audio()
	_setup_ui()
	_setup_world_nodes()
	_generate_world()
	_spawn_player()
	_rebuild_meshes()
	_update_hud()


func _physics_process(delta: float) -> void:
	_process_chunk_generation_queue(CHUNK_GENERATIONS_PER_TICK)
	_process_chunk_rebuild_queue(CHUNK_REBUILDS_PER_TICK)
	if not game_active:
		return
	block_action_timer = maxf(0.0, block_action_timer - delta)
	was_grounded = grounded
	_update_movement(delta)
	chunk_stream_timer -= delta
	if chunk_stream_timer <= 0.0:
		chunk_stream_timer = CHUNK_STREAM_CHECK_TIME
		_update_streamed_chunks()
	_update_fall_damage()
	dropped_item_timer -= delta
	if dropped_item_timer <= 0.0:
		dropped_item_timer = DROPPED_ITEM_REFRESH_TIME
		_update_dropped_items(DROPPED_ITEM_REFRESH_TIME)
	target_timer -= delta
	if target_dirty or target_timer <= 0.0:
		target_timer = TARGET_REFRESH_TIME
		target_dirty = false
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
	render_distance_chunks = maxi(0, int(worldgen.get("renderDistanceChunks", 1)))
	hotbar = block_data.get("hotbar", [])
	placeable_blocks.clear()

	for block in block_data.get("blocks", []):
		var id := String(block.get("id", ""))
		if id == "":
			continue
		if bool(block.get("placeable", true)):
			block["materials"] = block_material_factory.create_block_materials(block)
			var texture_paths: Dictionary = block.get("textures", {})
			block["singleMaterial"] = texture_paths.has("all")
			placeable_blocks.append(id)
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


func _setup_world_nodes() -> void:
	dropped_items_parent = Node3D.new()
	dropped_items_parent.name = "DroppedItems"
	add_child(dropped_items_parent)


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
	build.text = "PRE-ALPHA DESKTOP " + VERSION_LABEL
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

	var survival_button := Button.new()
	survival_button.text = "Survie"
	survival_button.custom_minimum_size = Vector2(210, 44)
	survival_button.pressed.connect(_start_survival)
	actions.add_child(survival_button)

	var creative_button := Button.new()
	creative_button.text = "Créatif"
	creative_button.custom_minimum_size = Vector2(210, 44)
	creative_button.pressed.connect(_start_creative)
	actions.add_child(creative_button)

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

	health_label = Label.new()
	health_label.anchor_left = 0.0
	health_label.anchor_right = 0.0
	health_label.anchor_top = 1.0
	health_label.anchor_bottom = 1.0
	health_label.offset_left = 14.0
	health_label.offset_top = -64.0
	health_label.offset_right = 360.0
	health_label.offset_bottom = -20.0
	health_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.34))
	health_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	health_label.add_theme_constant_override("shadow_offset_x", 2)
	health_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_layer.add_child(health_label)

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
	_setup_inventory_ui()
	_setup_game_over_ui()
	_setup_patch_notes_ui()
	_sync_hud_visibility()


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


func _setup_inventory_ui() -> void:
	inventory_layer = CanvasLayer.new()
	inventory_layer.name = "InventoryLayer"
	inventory_layer.visible = false
	add_child(inventory_layer)

	var root := CenterContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	inventory_layer.add_child(root)

	inventory_panel = PanelContainer.new()
	inventory_panel.custom_minimum_size = Vector2(700, 480)
	root.add_child(inventory_panel)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	inventory_panel.add_child(columns)

	var inventory_column := VBoxContainer.new()
	inventory_column.custom_minimum_size = Vector2(320, 430)
	columns.add_child(inventory_column)

	var inventory_title := Label.new()
	inventory_title.text = "Inventaire"
	inventory_title.add_theme_font_size_override("font_size", 24)
	inventory_column.add_child(inventory_title)

	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 6)
	inventory_column.add_child(inventory_list)

	var recipes_column := VBoxContainer.new()
	recipes_column.custom_minimum_size = Vector2(320, 430)
	columns.add_child(recipes_column)

	var recipes_title := Label.new()
	recipes_title.text = "Craft"
	recipes_title.add_theme_font_size_override("font_size", 24)
	recipes_column.add_child(recipes_title)

	recipes_list = VBoxContainer.new()
	recipes_list.add_theme_constant_override("separation", 6)
	recipes_column.add_child(recipes_list)


func _setup_game_over_ui() -> void:
	game_over_layer = CanvasLayer.new()
	game_over_layer.name = "GameOverLayer"
	game_over_layer.visible = false
	add_child(game_over_layer)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.0, 0.0, 0.72)
	game_over_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 280)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	box.add_child(title)

	var info := Label.new()
	info.text = "Tu peux réapparaître. Ton inventaire est tombé au sol."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)

	var respawn := Button.new()
	respawn.text = "Réapparaître"
	respawn.custom_minimum_size = Vector2(220, 46)
	respawn.pressed.connect(_respawn_after_death)
	box.add_child(respawn)


func _toggle_inventory() -> void:
	if not game_active:
		return
	inventory_layer.visible = not inventory_layer.visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if inventory_layer.visible else Input.MOUSE_MODE_CAPTURED)
	_sync_hud_visibility()
	if inventory_layer.visible:
		_refresh_inventory_ui()
	else:
		_update_hud()


func _refresh_inventory_ui() -> void:
	for child in inventory_list.get_children():
		child.queue_free()
	for child in recipes_list.get_children():
		child.queue_free()

	var item_ids: Array = player_inventory.copy_items().keys()
	item_ids.sort()
	if item_ids.is_empty():
		var empty := Label.new()
		empty.text = "Vide"
		inventory_list.add_child(empty)
	else:
		for id in item_ids:
			var label := Label.new()
			label.text = "%s x%d" % [_block_name(String(id)), player_inventory.count(String(id))]
			inventory_list.add_child(label)

	for recipe in crafting_book.get_recipes():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var button := Button.new()
		button.text = "Fabriquer"
		button.disabled = not crafting_book.can_craft(recipe, player_inventory)
		button.pressed.connect(_craft_recipe.bind(recipe))
		row.add_child(button)
		var text := Label.new()
		text.text = "%s  (%s -> %s)" % [
			String(recipe.get("name", recipe.get("id", "Recette"))),
			_format_item_map(recipe.get("input", {})),
			_format_item_map(recipe.get("output", {}))
		]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size = Vector2(220, 0)
		row.add_child(text)
		recipes_list.add_child(row)


func _craft_recipe(recipe: Dictionary) -> void:
	if crafting_book.craft(recipe, player_inventory):
		message = "Craft réussi: %s." % String(recipe.get("name", recipe.get("id", "recette")))
	else:
		message = "Il manque des matériaux."
	_refresh_inventory_ui()
	_rebuild_hotbar()
	_update_hud()


func _format_item_map(items: Dictionary) -> String:
	var parts := []
	for id in items.keys():
		parts.append("%s x%d" % [_block_name(String(id)), int(items[id])])
	return ", ".join(parts)


func _load_png_texture(path: String) -> Texture2D:
	return texture_loader.load_png(path) as Texture2D


func _generate_world() -> void:
	world.clear()
	chunk_blocks.clear()
	chunk_visible_blocks.clear()
	generated_chunk_keys.clear()
	chunk_generation_queue.clear()
	queued_chunk_generations.clear()
	active_chunk_generation.clear()
	world_seed = int(worldgen.get("seed", 1))
	if bool(worldgen.get("randomSeedOnStart", false)):
		world_seed += randi_range(0, 999999)
	bulk_world_update = true
	_clear_spawn_area()
	_add_showcase_details()
	bulk_world_update = false
	for chunk_key in chunk_blocks.keys():
		_rebuild_visible_block_cache(chunk_key)
	for chunk_key in _desired_chunk_keys(Vector2i.ZERO).keys():
		_queue_chunk_generation(chunk_key)
	message = "Nouveau monde généré."


func _ensure_chunk_generated(chunk_key: String) -> void:
	if generated_chunk_keys.has(chunk_key):
		return
	var job := _create_chunk_generation_job(chunk_key)
	if job.is_empty():
		return
	while not job.is_empty():
		_process_chunk_generation_job(job, 999999)


func _create_chunk_generation_job(chunk_key: String) -> Dictionary:
	var coords := _parse_chunk_key(chunk_key)
	var size := int(worldgen.get("size", 44))
	var half: int = int(size / 2)
	var start_x := coords.x * CHUNK_SIZE
	var start_z := coords.y * CHUNK_SIZE
	var end_x := start_x + CHUNK_SIZE - 1
	var end_z := start_z + CHUNK_SIZE - 1
	if end_x < -half or start_x > half or end_z < -half or start_z > half:
		generated_chunk_keys[chunk_key] = true
		return {}

	var min_x: int = maxi(-half, start_x)
	var max_x: int = mini(half, end_x)
	var min_z: int = maxi(-half, start_z)
	var max_z: int = mini(half, end_z)
	return {
		"chunk_key": chunk_key,
		"min_x": min_x,
		"max_x": max_x,
		"min_z": min_z,
		"max_z": max_z,
		"x": min_x,
		"z": min_z,
		"tree_spots": [],
		"min_y": int(worldgen.get("minHeight", -16)),
		"water_level": int(worldgen.get("waterLevel", 8)),
		"water_enabled": bool(worldgen.get("waterEnabled", false))
	}


func _process_chunk_generation_job(job: Dictionary, max_columns: int) -> bool:
	var count := 0
	bulk_world_update = true
	while count < max_columns and not job.is_empty():
		var x := int(job["x"])
		var z := int(job["z"])
		_generate_chunk_column(job, x, z)
		count += 1
		z += 1
		if z > int(job["max_z"]):
			z = int(job["min_z"])
			x += 1
		job["x"] = x
		job["z"] = z
		if x > int(job["max_x"]):
			bulk_world_update = false
			var chunk_key := String(job["chunk_key"])
			var tree_spots: Array = job["tree_spots"]
			for i in range(tree_spots.size()):
				var spot: Vector3i = tree_spots[i]
				_grow_tree(spot.x, spot.y, spot.z)
			generated_chunk_keys[chunk_key] = true
			_rebuild_visible_block_cache(chunk_key)
			job.clear()
			return true
	bulk_world_update = false
	return false


func _generate_chunk_column(job: Dictionary, x: int, z: int) -> void:
	var height := _terrain_height(x, z)
	var min_y := int(job["min_y"])
	var water_level := int(job["water_level"])
	var water_enabled := bool(job["water_enabled"])
	for y in range(min_y, height + 1):
		if _is_cave_air(x, y, z, height):
			continue
		_set_block(x, y, z, _natural_block_id(x, y, z, height, water_level))

	if water_enabled and height < water_level:
		for y in range(height + 1, water_level + 1):
			_set_block(x, y, z, "water")

	if height > water_level + 2 and (abs(x) > 8 or abs(z) > 8) and VoxelMathScript.hash2(x * 3, z * 3, world_seed) < float(worldgen.get("treeChance", 0.006)):
		var tree_spots: Array = job["tree_spots"]
		tree_spots.append(Vector3i(x, height + 1, z))
		job["tree_spots"] = tree_spots


func _terrain_height(x: int, z: int) -> int:
	var water_level := int(worldgen.get("waterLevel", 8))
	var max_height := int(worldgen.get("maxHeight", 24))
	var plateau_radius := int(worldgen.get("spawnPlateauRadius", 13))
	var plateau_height := int(worldgen.get("spawnPlateauHeight", water_level + 4))
	if String(worldgen.get("terrainMode", "")) == "showcase_flat":
		return plateau_height
	var dist: int = maxi(abs(x), abs(z))
	var hill_strength := float(worldgen.get("hillStrength", 7.0))
	var mountain_strength := float(worldgen.get("mountainStrength", 16.0))
	var broad: float = VoxelMathScript.value_noise(x * 0.026, z * 0.026, world_seed)
	var hills: float = VoxelMathScript.value_noise(x * 0.075 + 90.0, z * 0.075 - 27.0, world_seed)
	var detail: float = VoxelMathScript.value_noise(x * 0.18 - 18.0, z * 0.18 + 44.0, world_seed) - 0.5
	var mountains: float = pow(maxf(0.0, broad - 0.56), 1.55) * mountain_strength
	var natural: float = float(water_level + 5) + (hills - 0.48) * hill_strength + detail * 3.0 + mountains
	if dist <= plateau_radius:
		return plateau_height
	var blend: float = clampf(float(dist - plateau_radius) / 10.0, 0.0, 1.0)
	return clampi(roundi(lerpf(float(plateau_height), natural, blend)), 3, max_height)


func _natural_block_id(x: int, y: int, z: int, height: int, water_level: int) -> String:
	if y == height:
		if height <= water_level + 1:
			return "sand" if VoxelMathScript.hash2(x, z, world_seed + 41) > 0.18 else "clay"
		return "grass"
	if y > height - 4:
		if height <= water_level + 2:
			return "sand" if VoxelMathScript.hash3(x, y, z, world_seed + 82) > 0.18 else "clay"
		return "dirt"
	var ore := _ore_block_id(x, y, z)
	if ore != "":
		return ore
	if y < int(worldgen.get("minHeight", -16)) + 7 and VoxelMathScript.hash3(x, y, z, world_seed + 17) < 0.34:
		return "granite"
	if VoxelMathScript.hash3(x, y, z, world_seed + 99) < 0.018:
		return "marble"
	return "stone"


func _ore_block_id(x: int, y: int, z: int) -> String:
	var chance := float(worldgen.get("oreChance", 0.016))
	var roll := VoxelMathScript.hash3(x, y, z, world_seed + 301)
	if y < 8 and roll < chance * 0.45:
		return "iron_ore"
	if y < 24 and roll < chance:
		return "coal_ore"
	return ""


func _is_cave_air(x: int, y: int, z: int, surface_y: int) -> bool:
	var min_y := int(worldgen.get("minHeight", -16))
	if y <= min_y + 2 or y >= surface_y - 4:
		return false
	var cave_chance := float(worldgen.get("caveChance", 0.14))
	var tunnel := VoxelMathScript.value_noise(x * 0.095 + 7.0, z * 0.095 - 11.0, world_seed + y * 13)
	var pocket := VoxelMathScript.value_noise((x + y) * 0.055, (z - y) * 0.055, world_seed + 511)
	var depth_bonus := clampf(float(surface_y - y) / 38.0, 0.0, 0.18)
	return tunnel > 0.72 - cave_chance * 0.15 or pocket > 0.82 - depth_bonus


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
	var min_y := int(worldgen.get("minHeight", -16))
	var radius := int(worldgen.get("spawnPlateauRadius", 13))
	var plateau_height := int(worldgen.get("spawnPlateauHeight", int(worldgen.get("waterLevel", 6)) + 4))
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			for y in range(min_y, plateau_height + 1):
				if y < plateau_height - 3:
					_set_block(x, y, z, "stone")
				elif y < plateau_height:
					_set_block(x, y, z, "dirt")
				else:
					_set_block(x, y, z, "grass")


func _rebuild_meshes() -> void:
	for chunk_key in chunk_nodes.keys():
		_clear_chunk_meshes(chunk_key)
	chunk_nodes.clear()
	chunk_face_counts.clear()
	visible_chunk_keys.clear()
	chunk_rebuild_queue.clear()
	queued_chunk_rebuilds.clear()
	block_count = 0
	last_stream_chunk = Vector2i(999999, 999999)
	_update_streamed_chunks(true)


func _update_streamed_chunks(force: bool = false) -> void:
	if camera == null:
		return
	var center := _chunk_coords_for_world_position(camera.position)
	if not force and center == last_stream_chunk:
		return
	last_stream_chunk = center
	var desired := _desired_chunk_keys(center)

	for chunk_key in desired.keys():
		if not generated_chunk_keys.has(chunk_key):
			visible_chunk_keys[chunk_key] = true
			_queue_chunk_generation(chunk_key)
			if chunk_blocks.has(chunk_key):
				_queue_chunk_rebuild(chunk_key)
		elif not visible_chunk_keys.has(chunk_key):
			_queue_chunk_rebuild(chunk_key)


func _desired_chunk_keys(center: Vector2i, extra_distance: int = 0) -> Dictionary:
	var desired := {}
	var distance := render_distance_chunks + extra_distance
	for cx in range(center.x - distance, center.x + distance + 1):
		for cz in range(center.y - distance, center.y + distance + 1):
			desired[_chunk_key_from_coords(cx, cz)] = true
	return desired


func _rebuild_nearby_chunks(pos: Vector3i) -> void:
	var chunks_to_build := {}
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.RIGHT, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.LEFT, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.FORWARD, CHUNK_SIZE)] = true
	chunks_to_build[VoxelMathScript.chunk_key_for_block(pos + Vector3i.BACK, CHUNK_SIZE)] = true
	for chunk_key in chunks_to_build.keys():
		if visible_chunk_keys.has(chunk_key):
			_queue_chunk_rebuild(chunk_key, true)
	_mark_target_dirty()
	_update_hud()


func _clear_chunk_meshes(chunk_key: String, forget_visible: bool = true) -> void:
	for node in chunk_nodes.get(chunk_key, []):
		if is_instance_valid(node):
			node.queue_free()
	block_count -= int(chunk_face_counts.get(chunk_key, 0))
	chunk_nodes.erase(chunk_key)
	chunk_face_counts.erase(chunk_key)
	if forget_visible:
		visible_chunk_keys.erase(chunk_key)
		queued_chunk_rebuilds.erase(chunk_key)
		queued_chunk_generations.erase(chunk_key)


func _queue_chunk_rebuild(chunk_key: String, front: bool = false) -> void:
	if chunk_key == "":
		return
	if queued_chunk_rebuilds.has(chunk_key):
		if front:
			chunk_rebuild_queue.erase(chunk_key)
			chunk_rebuild_queue.push_front(chunk_key)
		return
	visible_chunk_keys[chunk_key] = true
	queued_chunk_rebuilds[chunk_key] = true
	if front:
		chunk_rebuild_queue.push_front(chunk_key)
	else:
		chunk_rebuild_queue.append(chunk_key)


func _queue_chunk_generation(chunk_key: String) -> void:
	if chunk_key == "" or generated_chunk_keys.has(chunk_key) or queued_chunk_generations.has(chunk_key):
		return
	queued_chunk_generations[chunk_key] = true
	chunk_generation_queue.append(chunk_key)


func _process_chunk_generation_queue(max_count: int) -> void:
	var finished := 0
	while finished < max_count:
		if active_chunk_generation.is_empty():
			if chunk_generation_queue.is_empty():
				return
			var chunk_key := String(chunk_generation_queue.pop_front())
			queued_chunk_generations.erase(chunk_key)
			if generated_chunk_keys.has(chunk_key):
				continue
			active_chunk_generation = _create_chunk_generation_job(chunk_key)
			if active_chunk_generation.is_empty():
				continue
		var active_key := String(active_chunk_generation.get("chunk_key", ""))
		if _process_chunk_generation_job(active_chunk_generation, CHUNK_GENERATION_COLUMNS_PER_TICK):
			if active_key != "":
				_queue_chunk_rebuild(active_key)
			finished += 1
		else:
			return


func _process_chunk_rebuild_queue(max_count: int) -> void:
	var built := 0
	while built < max_count and not chunk_rebuild_queue.is_empty():
		var chunk_key := String(chunk_rebuild_queue.pop_front())
		queued_chunk_rebuilds.erase(chunk_key)
		if not visible_chunk_keys.has(chunk_key):
			continue
		_rebuild_chunk(chunk_key)
		built += 1


func _rebuild_chunk(chunk_key: String) -> void:
	_clear_chunk_meshes(chunk_key, false)
	visible_chunk_keys[chunk_key] = true
	var keys: Array = _visible_keys_for_chunk(chunk_key)
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
	var block: Dictionary = blocks[id]
	var single_material := bool(block.get("singleMaterial", false))
	var group_key := id if single_material else "%s_%d" % [id, face]
	if not face_groups.has(group_key):
		var materials: Array = block["materials"]
		var material_index := 0 if single_material else face
		face_groups[group_key] = {
			"vertices": PackedVector3Array(),
			"normals": PackedVector3Array(),
			"uvs": PackedVector2Array(),
			"indices": PackedInt32Array(),
			"material": materials[material_index],
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


func _visible_keys_for_chunk(chunk_key: String) -> Array:
	if not chunk_visible_blocks.has(chunk_key):
		_rebuild_visible_block_cache(chunk_key)
	return chunk_visible_blocks.get(chunk_key, {}).keys()


func _rebuild_visible_block_cache(chunk_key: String) -> void:
	var visible := {}
	for key in chunk_blocks.get(chunk_key, {}).keys():
		var id := String(world.get(key, ""))
		if id == "":
			continue
		var p := _parse_key(String(key))
		if _is_visible_block(p.x, p.y, p.z, id):
			visible[key] = true
	if visible.is_empty():
		chunk_visible_blocks.erase(chunk_key)
	else:
		chunk_visible_blocks[chunk_key] = visible


func _refresh_visibility_around(pos: Vector3i) -> void:
	_refresh_single_block_visibility(pos)
	_refresh_single_block_visibility(pos + Vector3i.RIGHT)
	_refresh_single_block_visibility(pos + Vector3i.LEFT)
	_refresh_single_block_visibility(pos + Vector3i.UP)
	_refresh_single_block_visibility(pos + Vector3i.DOWN)
	_refresh_single_block_visibility(pos + Vector3i.FORWARD)
	_refresh_single_block_visibility(pos + Vector3i.BACK)


func _refresh_single_block_visibility(pos: Vector3i) -> void:
	var key := _block_key(pos.x, pos.y, pos.z)
	var chunk_key := VoxelMathScript.chunk_key_for_block(pos, CHUNK_SIZE)
	var id := String(world.get(key, ""))
	if id != "" and _is_visible_block(pos.x, pos.y, pos.z, id):
		if not chunk_visible_blocks.has(chunk_key):
			chunk_visible_blocks[chunk_key] = {}
		chunk_visible_blocks[chunk_key][key] = true
		return
	if chunk_visible_blocks.has(chunk_key):
		chunk_visible_blocks[chunk_key].erase(key)
		if chunk_visible_blocks[chunk_key].is_empty():
			chunk_visible_blocks.erase(chunk_key)


func _spawn_player() -> void:
	var spawn := _find_spawn_position()
	camera.position = spawn
	camera.rotation = Vector3(-0.04, -0.65, 0.0)
	velocity = Vector3.ZERO
	grounded = false
	was_grounded = false
	fall_start_y = camera.position.y


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
	for y in range(int(worldgen.get("maxHeight", 24)) + 16, int(worldgen.get("minHeight", -16)) - 2, -1):
		var id := _get_block(x, y, z)
		if id == "grass" or id == "sand" or id == "dirt" or id == "stone" or id == "clay" or id == "granite":
			return y
	return int(worldgen.get("waterLevel", 8)) + 4


func _highest_solid_y(x: int, z: int) -> int:
	for y in range(int(worldgen.get("maxHeight", 24)) + 16, int(worldgen.get("minHeight", -16)) - 2, -1):
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


func _update_fall_damage() -> void:
	if game_mode != MODE_SURVIVAL:
		return
	if was_grounded and not grounded:
		fall_start_y = camera.position.y
	if not was_grounded and grounded:
		var fallen := fall_start_y - camera.position.y
		if fallen > FALL_SAFE_HEIGHT:
			var damage := int(ceil((fallen - FALL_SAFE_HEIGHT) * 2.0))
			_apply_damage(damage, "chute")


func _apply_damage(amount: int, reason: String) -> void:
	if game_mode != MODE_SURVIVAL or amount <= 0 or game_over_layer.visible:
		return
	health = max(0, health - amount)
	message = "Dégâts de %s: -%d." % [reason, amount]
	_play_sfx("break")
	if health <= 0:
		_die()
	_update_hud()


func _die() -> void:
	game_active = false
	_drop_inventory_on_death()
	player_inventory.clear()
	_refresh_inventory_ui()
	game_over_layer.visible = true
	_update_hud()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _respawn_after_death() -> void:
	health = MAX_HEALTH
	game_over_layer.visible = false
	_spawn_player()
	game_active = true
	message = "Réapparition. Tes objets sont encore au sol."
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_update_hud()


func _drop_inventory_on_death() -> void:
	var origin := camera.position - Vector3(0, EYE_HEIGHT - 0.5, 0)
	var index := 0
	for id in player_inventory.copy_items().keys():
		var amount: int = player_inventory.count(String(id))
		if amount <= 0:
			continue
		var angle := float(index) * 0.83
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (0.7 + float(index % 3) * 0.25)
		_spawn_item_drop(String(id), amount, origin + offset)
		index += 1


func _spawn_item_drop(id: String, amount: int, position: Vector3) -> void:
	if amount <= 0:
		return
	var item := MeshInstance3D.new()
	item.name = "Drop_%s_%d" % [id, amount]
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.32, 0.32, 0.32)
	item.mesh = mesh
	item.position = position
	item.set_meta("item_id", id)
	item.set_meta("amount", amount)
	item.set_meta("base_y", position.y)
	item.set_meta("phase", randf() * TAU)
	item.material_override = _item_drop_material(id)
	dropped_items_parent.add_child(item)


func _item_drop_material(id: String) -> Material:
	var block: Dictionary = blocks.get(id, {})
	if block.has("materials"):
		var materials: Array = block["materials"]
		return materials[FACE_UP]
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	mat.albedo_color = Color(0.12, 0.1, 0.08) if id == "coal" else Color(0.86, 0.48, 0.27)
	return mat


func _update_dropped_items(delta: float) -> void:
	if dropped_items_parent == null:
		return
	for item in dropped_items_parent.get_children():
		if not is_instance_valid(item):
			continue
		item.rotation_degrees.y += delta * 80.0
		var base_y := float(item.get_meta("base_y", item.position.y))
		var phase := float(item.get_meta("phase", 0.0))
		item.position.y = base_y + sin(Time.get_ticks_msec() * 0.004 + phase) * 0.08
		if item.global_position.distance_to(camera.global_position) < 1.45:
			var id := String(item.get_meta("item_id", ""))
			var amount := int(item.get_meta("amount", 1))
			player_inventory.add_item(id, amount)
			message = "Ramassé: %s x%d." % [_block_name(id), amount]
			item.queue_free()
			_refresh_inventory_if_open()
			_rebuild_hotbar()
			_update_hud()


func _clear_dropped_items() -> void:
	if dropped_items_parent == null:
		return
	for item in dropped_items_parent.get_children():
		item.queue_free()


func _can_occupy(pos: Vector3) -> bool:
	var foot_y := pos.y - EYE_HEIGHT
	var x0 := pos.x - PLAYER_RADIUS
	var x1 := pos.x + PLAYER_RADIUS
	var z0 := pos.z - PLAYER_RADIUS
	var z1 := pos.z + PLAYER_RADIUS
	var y0 := foot_y + 0.05
	var y1 := foot_y + PLAYER_HEIGHT * 0.5
	var y2 := foot_y + PLAYER_HEIGHT - 0.08
	return not (
		_is_solid_at_point(x0, y0, z0) or _is_solid_at_point(x0, y0, z1) or _is_solid_at_point(x1, y0, z0) or _is_solid_at_point(x1, y0, z1)
		or _is_solid_at_point(x0, y1, z0) or _is_solid_at_point(x0, y1, z1) or _is_solid_at_point(x1, y1, z0) or _is_solid_at_point(x1, y1, z1)
		or _is_solid_at_point(x0, y2, z0) or _is_solid_at_point(x0, y2, z1) or _is_solid_at_point(x1, y2, z0) or _is_solid_at_point(x1, y2, z1)
	)


func _is_solid_at_point(x: float, y: float, z: float) -> bool:
	var id := _get_block(floori(x + 0.5), floori(y + 0.5), floori(z + 0.5))
	return bool(blocks.get(id, {}).get("solid", false))


func _update_target() -> void:
	selected_target = _voxel_raycast(6.2)
	if selected_target == null:
		if selected_outline.visible:
			selected_outline.visible = false
		return
	var target_position := Vector3(selected_target["pos"])
	if selected_outline.position != target_position:
		selected_outline.position = target_position
	if not selected_outline.visible:
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
			distance += TARGET_RAY_STEP
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
		distance += TARGET_RAY_STEP
	return null


func _mark_target_dirty() -> void:
	target_dirty = true
	target_timer = 0.0


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
	if block_action_timer > 0.0:
		return
	if target_dirty:
		_update_target()
		target_dirty = false
	if selected_target == null:
		message = "Aucun bloc à portée."
		return
	var pos: Vector3i = selected_target["pos"]
	var id: String = selected_target["id"]
	var drop_id := String(blocks.get(id, {}).get("drops", id))
	_set_block(pos.x, pos.y, pos.z, "")
	block_action_timer = BLOCK_ACTION_COOLDOWN
	if game_mode == MODE_SURVIVAL:
		player_inventory.add_item(drop_id, 1)
		_rebuild_hotbar()
	_play_sfx("break")
	message = "%s récupéré." % _block_name(drop_id)
	_rebuild_nearby_chunks(pos)
	_mark_target_dirty()
	_refresh_inventory_if_open()


func _place_target() -> void:
	if block_action_timer > 0.0:
		return
	if target_dirty:
		_update_target()
		target_dirty = false
	if selected_target == null:
		message = "Vise une face de bloc pour construire."
		return
	var id := _selected_block_id()
	if id == "":
		return
	if game_mode == MODE_SURVIVAL and player_inventory.count(id) <= 0:
		message = "Tu n'as plus de %s." % _block_name(id)
		_update_hud()
		return
	var pos: Vector3i = selected_target["pos"] + selected_target["normal"]
	if _would_intersect_player(pos):
		message = "Impossible de poser un bloc ici."
		return
	_set_block(pos.x, pos.y, pos.z, id)
	block_action_timer = BLOCK_ACTION_COOLDOWN
	if game_mode == MODE_SURVIVAL:
		player_inventory.remove_item(id, 1)
		_rebuild_hotbar()
	_play_sfx("place")
	message = "%s posé." % _block_name(id)
	_rebuild_nearby_chunks(pos)
	_mark_target_dirty()
	_refresh_inventory_if_open()


func _would_intersect_player(block_pos: Vector3i) -> bool:
	var p := camera.position
	var foot_y := p.y - EYE_HEIGHT
	return absf(p.x - block_pos.x) < PLAYER_RADIUS + 0.55 and absf(p.z - block_pos.z) < PLAYER_RADIUS + 0.55 and foot_y < block_pos.y + 0.5 and foot_y + PLAYER_HEIGHT > block_pos.y - 0.5


func _start_survival() -> void:
	_start_game(MODE_SURVIVAL)


func _start_creative() -> void:
	_start_game(MODE_CREATIVE)


func _start_game(mode: String = MODE_SURVIVAL) -> void:
	game_mode = mode
	health = MAX_HEALTH
	game_active = true
	title_layer.visible = false
	game_over_layer.visible = false
	inventory_layer.visible = false
	_sync_hud_visibility()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_play_sfx("menu")
	audio_library.play_music()
	message = "Mode survie lancé." if game_mode == MODE_SURVIVAL else "Mode créatif lancé."
	_rebuild_hotbar()
	_update_hud()


func _pause_game() -> void:
	game_active = false
	title_layer.visible = true
	inventory_layer.visible = false
	_sync_hud_visibility()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	message = "Pause."


func _show_patch_notes() -> void:
	patch_notes_controller.open_panel()
	_sync_hud_visibility()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sfx("menu")


func _hide_patch_notes() -> void:
	_play_sfx("menu")
	patch_notes_controller.close_panel()
	_sync_hud_visibility()


func _on_patch_notes_closed() -> void:
	_sync_hud_visibility()
	if game_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _new_world_from_menu() -> void:
	_clear_dropped_items()
	player_inventory.clear()
	health = MAX_HEALTH
	_generate_world()
	_spawn_player()
	_rebuild_meshes()
	_play_sfx("menu")
	_update_hud()


func _handle_key(keycode: int) -> void:
	if keycode == KEY_ESCAPE and patch_notes_controller != null and patch_notes_controller.is_open():
		_hide_patch_notes()
		return
	if keycode == KEY_ESCAPE and inventory_layer != null and inventory_layer.visible:
		_toggle_inventory()
		return
	if keycode == KEY_ESCAPE and game_active:
		_pause_game()
		return
	if keycode == KEY_E or keycode == KEY_I:
		_toggle_inventory()
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
	_mark_target_dirty()


func _select_slot(index: int) -> void:
	selected_slot = posmod(index, min(hotbar.size(), 9))
	_rebuild_hotbar()


func _selected_block_id() -> String:
	if hotbar.is_empty() or selected_slot >= hotbar.size():
		return ""
	var id := String(hotbar[selected_slot])
	if not bool(blocks.get(id, {}).get("placeable", true)):
		message = "%s ne se pose pas comme bloc." % _block_name(id)
		_update_hud()
		return ""
	return id


func _block_name(id: String) -> String:
	return String(blocks.get(id, {}).get("name", id))


func _refresh_inventory_if_open() -> void:
	if inventory_layer != null and inventory_layer.visible:
		_refresh_inventory_ui()


func _rebuild_hotbar() -> void:
	var slot_count: int = min(hotbar.size(), 9)
	if hotbar_labels.size() != slot_count or hotbar_box.get_child_count() != slot_count:
		for child in hotbar_box.get_children():
			child.queue_free()
		hotbar_labels.clear()
		hotbar_last_texts.clear()
		for i in range(slot_count):
			var slot := PanelContainer.new()
			slot.custom_minimum_size = Vector2(50, 50)
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			slot.add_child(label)
			hotbar_box.add_child(slot)
			hotbar_labels.append(label)
			hotbar_last_texts.append("")
	_refresh_hotbar_labels()


func _refresh_hotbar_labels() -> void:
	for i in range(min(hotbar.size(), hotbar_labels.size())):
		var id := String(hotbar[i])
		var block: Dictionary = blocks.get(id, {})
		var count_text := ""
		if game_mode == MODE_SURVIVAL:
			count_text = " x%d" % player_inventory.count(id)
		var text := "%d\n%s%s" % [i + 1, String(block.get("name", id)).left(6), count_text]
		var label: Label = hotbar_labels[i]
		if i >= hotbar_last_texts.size():
			hotbar_last_texts.append("")
		if hotbar_last_texts[i] != text:
			label.text = text
			hotbar_last_texts[i] = text
		if i == selected_slot:
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.42))
		else:
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))


func _update_hud() -> void:
	_sync_hud_visibility()
	if not hud_layer.visible:
		return
	var block_name := "?"
	if selected_slot < hotbar.size():
		block_name = String(blocks.get(String(hotbar[selected_slot]), {}).get("name", hotbar[selected_slot]))
	var status_text := "%s\nMode: %s | Bloc: %s\nZQSD/WASD marcher | clic gauche/droit casser/poser | E inventaire/craft | 1-9 blocs" % [
		message,
		"Survie" if game_mode == MODE_SURVIVAL else "Créatif",
		block_name
	]
	if status_text != last_status_text:
		status_label.text = status_text
		last_status_text = status_text

	health_label.visible = game_mode == MODE_SURVIVAL
	if health_label.visible:
		var health_text := "Vie: %s" % _health_bar_text()
		if health_text != last_health_text:
			health_label.text = health_text
			last_health_text = health_text

	var debug_text := "BlockForge %s\nx %.1f y %.1f z %.1f\nseed %d\nfaces visibles %d\n%s" % [VERSION_LABEL, camera.position.x, camera.position.y, camera.position.z, world_seed, block_count, "brume douce" if retro_fog else "vue nette"]
	if debug_text != last_debug_text:
		debug_label.text = debug_text
		last_debug_text = debug_text


func _sync_hud_visibility() -> void:
	if hud_layer == null:
		return
	var overlays_open := false
	overlays_open = overlays_open or (title_layer != null and title_layer.visible)
	overlays_open = overlays_open or (inventory_layer != null and inventory_layer.visible)
	overlays_open = overlays_open or (game_over_layer != null and game_over_layer.visible)
	overlays_open = overlays_open or (patch_notes_controller != null and patch_notes_controller.is_open())
	var should_show := game_active and not overlays_open
	if hud_layer.visible != should_show:
		hud_layer.visible = should_show
	if not should_show and selected_outline != null:
		selected_outline.visible = false


func _health_bar_text() -> String:
	var full := int(ceil(float(health) / 2.0))
	var empty := 10 - full
	return "%s%s %d/%d" % ["♥".repeat(full), "♡".repeat(empty), health, MAX_HEALTH]


func _play_sfx(id: String) -> void:
	audio_library.play_sfx(id)


func _set_block(x: int, y: int, z: int, id: String) -> void:
	var key := _block_key(x, y, z)
	if String(world.get(key, "")) == id:
		return
	var pos := Vector3i(x, y, z)
	var chunk_key := VoxelMathScript.chunk_key_for_block(pos, CHUNK_SIZE)
	if id == "":
		world.erase(key)
		if chunk_blocks.has(chunk_key):
			chunk_blocks[chunk_key].erase(key)
			if chunk_blocks[chunk_key].is_empty():
				chunk_blocks.erase(chunk_key)
		if chunk_visible_blocks.has(chunk_key):
			chunk_visible_blocks[chunk_key].erase(key)
			if chunk_visible_blocks[chunk_key].is_empty():
				chunk_visible_blocks.erase(chunk_key)
	else:
		world[key] = id
		if not chunk_blocks.has(chunk_key):
			chunk_blocks[chunk_key] = {}
		chunk_blocks[chunk_key][key] = true
	if not bulk_world_update:
		_refresh_visibility_around(pos)


func _get_block(x: int, y: int, z: int) -> String:
	return String(world.get(_block_key(x, y, z), ""))


func _get_block_at_point(point: Vector3) -> String:
	return _get_block(floori(point.x + 0.5), floori(point.y + 0.5), floori(point.z + 0.5))


func _block_key(x: int, y: int, z: int) -> String:
	return "%d,%d,%d" % [x, y, z]


func _chunk_key_from_coords(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]


func _parse_chunk_key(key: String) -> Vector2i:
	var parts := key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


func _chunk_coords_for_world_position(pos: Vector3) -> Vector2i:
	return Vector2i(floori(pos.x / float(CHUNK_SIZE)), floori(pos.z / float(CHUNK_SIZE)))


func _parse_key(key: String) -> Vector3i:
	var parts := key.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))
