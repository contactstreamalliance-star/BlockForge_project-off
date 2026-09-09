extends Node3D

const PlayerController = preload("res://scripts/player_controller.gd")
const EnemyBasic = preload("res://scripts/enemy_basic.gd")
const ResourceNode = preload("res://scripts/resource_node.gd")
const InteractableStation = preload("res://scripts/interactable_station.gd")
const CHARACTERS_PATH := "res://data/characters.json"
const MODEL_ROBERT := "res://assets/models/characters/robert_knight_base.glb"
const MODEL_SOREN := "res://assets/models/characters/soren_archer_base.glb"
const MODEL_AUGUSTIN := "res://assets/models/characters/augustin_merchant_base.glb"
const MODEL_MEDIC := "res://assets/models/characters/medic_student_base.glb"
const CITY_MODEL_PATH := "res://assets/models/city/"
const SCIFI_MODEL_PATH := "res://assets/models/scifi/glTF/"
const NATURE_MODEL_PATH := "res://assets/models/nature/glTF/"
const SCIFI_VISUAL_SCALE := 0.55
const NATURE_VISUAL_SCALE := 0.88
const BEAUTY_PASS_CLEAN_SCENE := true
const USE_IMPORTED_PLAYER_MODEL := false

var selected_character_id := "robert"
var player: CharacterBody3D
var status_label: Label
var quest_label: Label
var prompt_label: Label
var log_label: Label
var cinematic_label: Label
var objective_marker: Label3D
var world_environment: WorldEnvironment
var degradation_wave: MeshInstance3D

var resource_counts: Dictionary = {}
var unlocked_rewards: Dictionary = {}
var combat_log_lines: Array[String] = []
var alpha_tokens := 3
var duplicate_points := 0
var harvested_samples := 0
var destroyed_machines := 0
var defeated_organics := 0
var quest_stage := 0
var boss_defeated := false
var cinematic_timer := 0.0
var selected_character_data: Dictionary = {}
var ambient_audio: AudioStreamPlayer
var ambient_motes: Array[MeshInstance3D] = []


func _ready() -> void:
	randomize()
	_create_lighting()
	_create_environment()
	_create_player()
	_spawn_gameplay_objects()
	_create_ui()
	_load_character_preview()
	_push_log("Bienvenue dans BlockForge Alpha : prototype local Minecraft-like open source.")
	_push_log("Objectif actuel : explorer, recolter et preparer la base voxel.")


func _process(delta: float) -> void:
	_update_ui()
	_update_cinematic(delta)
	_animate_ambient_motes()


func _create_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-38.0, -58.0, 0.0)
	sun.light_energy = 1.65
	sun.light_color = Color(1.0, 0.78, 0.55)
	sun.shadow_enabled = true
	add_child(sun)

	var secondary := DirectionalLight3D.new()
	secondary.name = "Cold_City_Bounce"
	secondary.rotation_degrees = Vector3(-16.0, 145.0, 0.0)
	secondary.light_energy = 0.38
	secondary.light_color = Color(0.40, 0.82, 1.0)
	add_child(secondary)

	world_environment = WorldEnvironment.new()
	world_environment.name = "World_Atmosphere"
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.025, 0.055, 0.095)
	sky_material.sky_horizon_color = Color(0.86, 0.58, 0.34)
	sky_material.ground_horizon_color = Color(0.13, 0.20, 0.19)
	sky_material.ground_bottom_color = Color(0.025, 0.035, 0.035)
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.34, 0.36)
	environment.ambient_light_energy = 0.62
	environment.glow_enabled = true
	environment.glow_intensity = 0.44
	environment.glow_bloom = 0.13
	environment.fog_enabled = true
	environment.fog_density = 0.0055
	environment.fog_light_color = Color(0.73, 0.84, 0.79)
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.22
	environment.adjustment_saturation = 1.14
	world_environment.environment = environment
	add_child(world_environment)


func _create_environment() -> void:
	if BEAUTY_PASS_CLEAN_SCENE:
		_create_beauty_pass_environment()
		return

	_create_ground()
	_create_roads()
	_create_veyr_station()
	_create_buffer_zone()
	_create_dying_forest()
	_create_degradation_wave()
	_create_signal_beam()
	_create_background_skyline()
	_create_atmosphere_particles()
	_create_audio()

	_create_label_3d("Atelier BlockForge", Vector3(-20, 5.0, -3), Color(0.45, 0.95, 1.0), 34)
	_create_label_3d("Zone tampon agricole", Vector3(0, 3.1, 4), Color(0.95, 0.78, 0.35), 28)
	_create_label_3d("Foret mourante", Vector3(21, 3.9, -8), Color(0.68, 1.0, 0.32), 28)

	objective_marker = _create_label_3d("Signal inconnu", Vector3(25, 2.8, -9), Color(1.0, 0.38, 0.18), 24)


func _create_beauty_pass_environment() -> void:
	_create_beauty_ground()
	_create_beauty_veyr_gate()
	_create_beauty_blueprint_plaza()
	_create_beauty_research_field()
	_create_beauty_forest_vista()
	_create_beauty_midground_props()
	_create_beauty_skyline()
	_create_degradation_wave()
	_create_signal_beam()
	_create_atmosphere_particles()
	_create_audio()

	_create_label_3d("VEY-R STATION", Vector3(-14.6, 3.75, 4.5), Color(0.45, 0.95, 1.0), 18)
	_create_label_3d("Cultures silencieuses", Vector3(6.8, 2.25, 9.0), Color(1.0, 0.76, 0.36), 16)
	_create_label_3d("Foret mourante", Vector3(21.8, 3.1, -8.5), Color(0.76, 1.0, 0.34), 17)
	objective_marker = _create_label_3d("Signal inconnu", Vector3(26.0, 3.2, -10.0), Color(1.0, 0.36, 0.12), 18)


func _create_beauty_ground() -> void:
	var collision_mat := _mat(Color(0.04, 0.05, 0.045))
	_create_static_box("Alpha_Ground_Collision", Vector3(0.0, -0.56, 0.0), Vector3(88.0, 1.0, 88.0), collision_mat, false)

	var plaza_mat := _mat(Color(0.075, 0.105, 0.115), Color(0.0, 0.035, 0.045), 0.0)
	var plaza_panel_a := _mat(Color(0.12, 0.16, 0.17), Color(0.0, 0.035, 0.045), 0.0, true)
	var plaza_panel_b := _mat(Color(0.080, 0.112, 0.125), Color(0.0, 0.030, 0.040), 0.0, true)
	var path_mat := _mat(Color(0.11, 0.15, 0.155), Color(0.0, 0.04, 0.055), 0.0)
	var path_panel_mat := _mat(Color(0.16, 0.21, 0.21), Color(0.02, 0.09, 0.10), 0.0, true)
	var soil_mat := _mat(Color(0.115, 0.100, 0.070), Color(0.08, 0.05, 0.015), 0.0, true)
	var field_mat := _mat(Color(0.20, 0.28, 0.19), Color(0.08, 0.16, 0.045), 0.0, true)
	var forest_mat := _mat(Color(0.075, 0.095, 0.064), Color(0.12, 0.06, 0.02), 0.0, true)
	var forest_vein_mat := _mat(Color(0.16, 0.065, 0.035), Color(0.36, 0.09, 0.025), 0.52)
	var cyan_mat := _mat(Color(0.30, 0.95, 1.0), Color(0.18, 0.92, 1.0), 1.05)
	var amber_mat := _mat(Color(1.0, 0.66, 0.25), Color(1.0, 0.42, 0.10), 0.72)
	var edge_mat := _mat(Color(0.025, 0.04, 0.045), Color(0.0, 0.015, 0.02), 0.0)

	_create_decor_box("Hero_Terrace_Dark_Mass", Vector3(-18.8, 0.00, 4.5), Vector3(12.5, 0.12, 11.0), plaza_mat)
	_create_static_box("Hero_Terrace_Front_Lip_Solid", Vector3(-18.8, 0.18, 10.15), Vector3(12.9, 0.36, 0.34), edge_mat, true)
	_create_static_box("Hero_Terrace_Back_Lip_Solid", Vector3(-18.8, 0.18, -1.15), Vector3(12.9, 0.36, 0.34), edge_mat, true)
	_create_static_box("Hero_Terrace_Left_Lip_Solid", Vector3(-25.25, 0.18, 4.5), Vector3(0.34, 0.36, 11.2), edge_mat, true)
	_create_decor_box("Main_Sightline_Path", Vector3(-5.7, 0.035, 4.5), Vector3(25.0, 0.08, 4.9), path_mat)
	_create_decor_box_rotated("Broken_Agriculture_Slab_A", Vector3(5.8, 0.025, 7.9), Vector3(13.5, 0.07, 8.5), field_mat, Vector3(0.0, -7.0, 0.0))
	_create_decor_box_rotated("Broken_Agriculture_Slab_B", Vector3(11.0, 0.018, 0.3), Vector3(9.5, 0.06, 6.0), field_mat, Vector3(0.0, 12.0, 0.0))
	_create_decor_box("Forest_Dark_Soil_Composition", Vector3(23.5, 0.012, -8.0), Vector3(30.0, 0.06, 25.0), forest_mat)

	for x_index in range(4):
		for z_index in range(3):
			var panel_position := Vector3(-23.3 + float(x_index) * 3.0, 0.075, 1.25 + float(z_index) * 3.15)
			var panel_mat := plaza_panel_a if (x_index + z_index) % 2 == 0 else plaza_panel_b
			_create_decor_box("Terrace_Floor_Panel_%02d_%02d" % [x_index, z_index], panel_position, Vector3(2.72, 0.035, 2.82), panel_mat)

	for index in range(5):
		_create_decor_box("Terrace_Long_Seam_%02d" % index, Vector3(-23.4 + float(index) * 2.4, 0.105, 4.45), Vector3(1.1, 0.03, 0.045), cyan_mat)
	for index in range(4):
		_create_decor_box("Terrace_Short_Seam_%02d" % index, Vector3(-19.2, 0.106, 1.35 + float(index) * 2.0), Vector3(0.045, 0.03, 0.92), cyan_mat)

	for index in range(7):
		var x := -13.7 + float(index) * 3.35
		var plate_width := 2.55 + float(index % 2) * 0.36
		_create_decor_box_rotated("Path_Armored_Floor_Plate_%02d" % index, Vector3(x, 0.095, 4.5), Vector3(plate_width, 0.035, 4.15), path_panel_mat, Vector3(0.0, randf_range(-2.5, 2.5), 0.0))
		if index % 2 == 0:
			_create_decor_box("Path_Side_Cyan_L_%02d" % index, Vector3(x, 0.13, 2.22), Vector3(1.18, 0.035, 0.055), cyan_mat)
		else:
			_create_decor_box("Path_Side_Cyan_R_%02d" % index, Vector3(x, 0.13, 6.78), Vector3(1.18, 0.035, 0.055), cyan_mat)

	for index in range(6):
		var x := -17.8 + float(index) * 4.0
		_create_decor_box("Terrace_Cyan_Line_%02d" % index, Vector3(x, 0.105, 1.6), Vector3(1.6, 0.035, 0.06), cyan_mat)
		_create_decor_box("Terrace_Cyan_Line_B_%02d" % index, Vector3(x, 0.105, 7.4), Vector3(1.6, 0.035, 0.06), cyan_mat)

	for index in range(5):
		var x := -8.0 + float(index) * 4.2
		_create_decor_box("Path_Amber_Beat_%02d" % index, Vector3(x, 0.11, 4.5), Vector3(0.68, 0.035, 0.09), amber_mat)

	for index in range(6):
		var z := 5.65 + float(index) * 1.22
		_create_decor_box_rotated("Agriculture_Soil_Furrow_%02d" % index, Vector3(7.0, 0.105, z), Vector3(10.6, 0.04, 0.20), soil_mat, Vector3(0.0, -7.0, 0.0))

	for index in range(9):
		var patch_x := 13.0 + float(index % 3) * 4.8
		var patch_z: float = -1.5 - floorf(float(index) / 3.0) * 4.6
		_create_decor_box_rotated("Forest_Painterly_Decay_%02d" % index, Vector3(patch_x, 0.052, patch_z), Vector3(2.8, 0.035, 1.25), _mat(Color(0.12, 0.15, 0.075), Color(0.16, 0.07, 0.02), 0.0, true), Vector3(0.0, randf_range(-26.0, 26.0), 0.0))

	for index in range(10):
		var vein_x := 15.0 + float(index % 5) * 3.7
		var vein_z := -2.7 - floorf(float(index) / 5.0) * 7.3
		_create_decor_box_rotated("Forest_Orange_Vein_%02d" % index, Vector3(vein_x, 0.125, vein_z), Vector3(2.6, 0.032, 0.075), forest_vein_mat, Vector3(0.0, randf_range(-36.0, 36.0), 0.0))


func _create_beauty_veyr_gate() -> void:
	var dark_mat := _mat(Color(0.025, 0.035, 0.045), Color(0.0, 0.02, 0.03), 0.0)
	var metal_mat := _mat(Color(0.18, 0.24, 0.25), Color(0.02, 0.09, 0.10), 0.0)
	var cyan_mat := _mat(Color(0.25, 0.90, 1.0), Color(0.16, 0.88, 1.0), 1.15)
	var glass_mat := _holo_mat(Color(0.18, 0.56, 0.66, 0.38), Color(0.14, 0.90, 1.0), 0.5)

	_create_static_box("Veyr_Gate_Left_Clean_Collision", Vector3(-14.8, 1.55, 1.6), Vector3(0.72, 3.1, 0.72), dark_mat, true)
	_create_static_box("Veyr_Gate_Right_Clean_Collision", Vector3(-14.8, 1.55, 7.4), Vector3(0.72, 3.1, 0.72), dark_mat, true)
	_create_static_box("Veyr_Gate_Top_Clean_Collision", Vector3(-14.8, 3.25, 4.5), Vector3(0.82, 0.44, 6.45), metal_mat, true)
	_create_decor_box("Veyr_Gate_Cyan_Core_Left", Vector3(-15.18, 1.72, 1.6), Vector3(0.055, 1.9, 0.18), cyan_mat)
	_create_decor_box("Veyr_Gate_Cyan_Core_Right", Vector3(-15.18, 1.72, 7.4), Vector3(0.055, 1.9, 0.18), cyan_mat)
	_create_decor_box("Veyr_Gate_Cyan_Top", Vector3(-15.18, 3.27, 4.5), Vector3(0.06, 0.16, 5.05), cyan_mat)
	_create_decor_box("Veyr_Glass_Observation_Sheet", Vector3(-18.8, 1.55, -0.7), Vector3(6.8, 2.6, 0.08), glass_mat)
	_create_static_box("Veyr_Command_Table_Base_Solid", Vector3(-17.0, 0.42, 4.6), Vector3(1.9, 0.32, 1.15), metal_mat, true)
	_create_decor_box("Veyr_Command_Table_Holo", Vector3(-17.0, 1.04, 4.6), Vector3(1.55, 0.08, 0.82), cyan_mat)
	_create_scifi_prop("Veyr_Command_Access_Point", "Props/Prop_AccessPoint.gltf", Vector3(-16.2, 0.11, 3.65), Vector3.ONE * 1.1, Vector3(0.0, -35.0, 0.0))
	_create_scifi_prop("Veyr_Ceiling_Light", "Props/Prop_Light_Wide.gltf", Vector3(-15.05, 3.02, 4.5), Vector3.ONE * 1.15, Vector3(0.0, 90.0, 0.0))

	for z in [0.2, 8.8]:
		_create_lamp(Vector3(-20.8, 0.0, z), Color(0.32, 0.92, 1.0))


func _create_beauty_blueprint_plaza() -> void:
	var base := Vector3(-9.2, 0.0, 8.8)
	var dark_mat := _mat(Color(0.035, 0.032, 0.055), Color(0.02, 0.0, 0.04), 0.0)
	var magenta := _holo_mat(Color(0.95, 0.24, 1.0, 0.62), Color(0.95, 0.18, 1.0), 1.3)
	var gold := _holo_mat(Color(1.0, 0.68, 0.24, 0.66), Color(1.0, 0.40, 0.08), 0.85)
	var cyan := _mat(Color(0.28, 0.92, 1.0), Color(0.16, 0.88, 1.0), 1.0)

	_create_scifi_prop("Beauty_Blueprint_Round_Platform", "Platforms/Platform_Round1.gltf", base + Vector3(0.0, 0.08, 0.0), Vector3.ONE * 2.25, Vector3.ZERO)
	_create_scifi_prop("Beauty_Blueprint_Item_Holder", "Props/Prop_ItemHolder.gltf", base + Vector3(0.0, 0.12, -0.12), Vector3.ONE * 1.52, Vector3(0.0, 180.0, 0.0))
	_create_scifi_prop("Beauty_Blueprint_Chest", "Props/Prop_Chest.gltf", base + Vector3(-1.05, 0.10, -0.70), Vector3.ONE * 0.92, Vector3(0.0, 25.0, 0.0))
	_create_scifi_prop("Beauty_Blueprint_Terminal", "Props/Prop_Computer.gltf", base + Vector3(1.10, 0.10, -0.58), Vector3.ONE * 0.98, Vector3(0.0, -38.0, 0.0))
	_create_decor_box("Beauty_Blueprint_Backdrop", base + Vector3(0.0, 1.05, 1.25), Vector3(3.8, 2.1, 0.14), dark_mat)
	_create_static_box("Beauty_Blueprint_Backdrop_Solid", base + Vector3(0.0, 1.05, 1.25), Vector3(3.9, 2.05, 0.20), dark_mat, false)
	_create_static_box("Beauty_Blueprint_Terminal_Solid", base + Vector3(1.10, 0.55, -0.58), Vector3(0.90, 1.10, 0.72), dark_mat, false)
	_create_static_box("Beauty_Blueprint_Chest_Solid", base + Vector3(-1.05, 0.34, -0.70), Vector3(0.90, 0.68, 0.90), dark_mat, false)
	_create_decor_box_rotated("Beauty_Blueprint_Main_Card", base + Vector3(0.0, 2.25, 0.78), Vector3(1.08, 1.55, 0.055), magenta, Vector3(0.0, 0.0, -2.0))
	_create_decor_box_rotated("Beauty_Blueprint_Left_Card", base + Vector3(-1.08, 1.72, 0.82), Vector3(0.76, 1.03, 0.05), gold, Vector3(0.0, 0.0, 8.0))
	_create_decor_box_rotated("Beauty_Blueprint_Right_Card", base + Vector3(1.08, 1.62, 0.82), Vector3(0.68, 0.92, 0.05), cyan, Vector3(0.0, 0.0, -8.0))
	_create_label_3d("ATELIER DE PLANS", base + Vector3(0.0, 3.25, 0.15), Color(1.0, 0.48, 1.0), 18)

	var card_specs := [
		{"name": "Mineur", "color": Color(0.34, 0.95, 1.0)},
		{"name": "Bucheronne", "color": Color(0.60, 1.0, 0.45)},
		{"name": "Artisan", "color": Color(1.0, 0.72, 0.28)},
		{"name": "Exploratrice", "color": Color(0.78, 0.66, 1.0)}
	]
	for index in range(card_specs.size()):
		var spec: Dictionary = card_specs[index]
		var accent: Color = spec["color"]
		var card_pos := Vector3(-12.0 + float(index) * 1.55, 0.0, 11.0)
		_create_decor_box("HoloRoster_Pedestal_%02d" % index, card_pos + Vector3(0.0, 0.12, 0.0), Vector3(0.92, 0.20, 0.92), _mat(Color(0.055, 0.066, 0.075), accent, 0.18))
		_create_decor_box("HoloRoster_Card_%02d" % index, card_pos + Vector3(0.0, 1.10, 0.0), Vector3(0.58, 1.32, 0.045), _holo_mat(Color(accent.r, accent.g, accent.b, 0.44), accent, 0.72))
		_create_label_3d(str(spec["name"]), card_pos + Vector3(0.0, 2.05, 0.0), accent, 13)


func _create_beauty_research_field() -> void:
	var crop_mat := _mat(Color(0.24, 0.34, 0.19), Color(0.07, 0.18, 0.04), 0.0, true)
	var warning_mat := _mat(Color(1.0, 0.58, 0.14), Color(1.0, 0.32, 0.04), 0.8)
	var lab_mat := _mat(Color(0.16, 0.21, 0.21), Color(0.02, 0.09, 0.09), 0.0)
	var cyan_mat := _mat(Color(0.32, 0.88, 1.0), Color(0.14, 0.78, 1.0), 0.8)

	_create_static_box("Field_Lab_Clean_Collision", Vector3(2.2, 0.82, -0.6), Vector3(3.6, 1.64, 2.3), lab_mat, true)
	_create_decor_box("Field_Lab_Warning_Bar", Vector3(2.2, 1.85, -1.78), Vector3(3.35, 0.12, 0.08), warning_mat)
	_create_scifi_prop("Field_Lab_Door_Frame", "Platforms/Door_Frame_Square.gltf", Vector3(2.2, 0.09, -1.86), Vector3.ONE * 1.24, Vector3.ZERO)
	_create_scifi_prop("Field_Lab_Cable", "Props/Prop_Cable_3.gltf", Vector3(4.0, 0.14, 0.75), Vector3.ONE * 1.1, Vector3(0.0, 26.0, 0.0))

	for index in range(5):
		var row_x := 2.8 + float(index) * 2.05
		_create_decor_box("Curated_Crop_Row_%02d" % index, Vector3(row_x, 0.125, 8.75), Vector3(1.12, 0.16, 6.2), crop_mat)
		_create_sick_plant_cluster(Vector3(row_x, 0.20, 8.2))
		if index % 2 == 0:
			_create_nature_prop("Curated_Crop_Grass_%02d" % index, "Grass_Common_Tall.gltf", Vector3(row_x - 0.25, 0.08, 10.65), Vector3.ONE * 1.0, Vector3(0.0, float(index) * 40.0, 0.0))
		else:
			_create_nature_prop("Curated_Crop_Fern_%02d" % index, "Fern_1.gltf", Vector3(row_x + 0.25, 0.08, 6.95), Vector3.ONE * 0.95, Vector3(0.0, float(index) * 51.0, 0.0))

	_create_decor_box("Field_Scan_Ring_A", Vector3(7.0, 0.14, 8.75), Vector3(9.0, 0.035, 0.08), cyan_mat)
	_create_decor_box("Field_Scan_Ring_B", Vector3(7.0, 0.14, 11.95), Vector3(9.0, 0.035, 0.08), cyan_mat)
	_create_lamp(Vector3(0.4, 0.0, 4.1), Color(1.0, 0.62, 0.22))
	_create_lamp(Vector3(12.4, 0.0, 4.1), Color(1.0, 0.62, 0.22))


func _create_beauty_midground_props() -> void:
	var dark_mat := _mat(Color(0.035, 0.050, 0.058), Color(0.0, 0.018, 0.026), 0.0)
	var metal_mat := _mat(Color(0.17, 0.21, 0.22), Color(0.02, 0.075, 0.080), 0.0)
	var cyan_mat := _mat(Color(0.27, 0.91, 1.0), Color(0.16, 0.86, 1.0), 0.95)
	var amber_mat := _mat(Color(1.0, 0.62, 0.20), Color(1.0, 0.34, 0.05), 0.75)
	var glass_mat := _holo_mat(Color(0.16, 0.50, 0.60, 0.32), Color(0.12, 0.86, 1.0), 0.45)
	var crate_mat := _mat(Color(0.18, 0.20, 0.19), Color(0.04, 0.09, 0.08), 0.0, true)
	var planter_mat := _mat(Color(0.10, 0.13, 0.10), Color(0.05, 0.12, 0.04), 0.0, true)

	_create_static_box("Terrace_Observation_Bench_A_Solid", Vector3(-22.5, 0.34, 0.62), Vector3(2.4, 0.34, 0.52), metal_mat, true)
	_create_decor_box("Terrace_Observation_Bench_A_Light", Vector3(-22.5, 0.56, 0.34), Vector3(2.15, 0.05, 0.055), cyan_mat)
	_create_static_box("Terrace_Observation_Bench_B_Solid", Vector3(-22.5, 0.34, 8.38), Vector3(2.4, 0.34, 0.52), metal_mat, true)
	_create_decor_box("Terrace_Observation_Bench_B_Light", Vector3(-22.5, 0.56, 8.66), Vector3(2.15, 0.05, 0.055), cyan_mat)

	_create_static_box("Repair_Kiosk_Shell_Solid", Vector3(-8.2, 0.72, 1.55), Vector3(2.2, 1.44, 1.25), dark_mat, true)
	_create_decor_box("Repair_Kiosk_Cyan_Cross_H", Vector3(-8.2, 1.63, 0.91), Vector3(1.10, 0.08, 0.055), cyan_mat)
	_create_decor_box("Repair_Kiosk_Cyan_Cross_V", Vector3(-8.2, 1.63, 0.90), Vector3(0.09, 0.74, 0.055), cyan_mat)
	_create_scifi_prop("Repair_Kiosk_Computer_Model", "Props/Prop_Computer.gltf", Vector3(-7.38, 0.10, 1.18), Vector3.ONE * 0.92, Vector3(0.0, -118.0, 0.0))

	_create_static_box("Cargo_Crate_A_Solid", Vector3(-4.6, 0.42, 2.2), Vector3(1.05, 0.84, 1.10), crate_mat, true)
	_create_decor_box("Cargo_Crate_A_Mark", Vector3(-4.6, 0.88, 1.63), Vector3(0.74, 0.06, 0.055), amber_mat)
	_create_static_box("Cargo_Crate_B_Solid", Vector3(-2.3, 0.32, 6.72), Vector3(1.25, 0.64, 0.88), crate_mat, true)
	_create_decor_box("Cargo_Crate_B_Mark", Vector3(-2.3, 0.69, 7.18), Vector3(0.78, 0.055, 0.055), cyan_mat)
	_create_scifi_prop("Cargo_Crate_A_Model_Detail", "Props/Prop_Crate3.gltf", Vector3(-4.6, 0.11, 2.2), Vector3.ONE * 0.72, Vector3(0.0, 16.0, 0.0))
	_create_scifi_prop("Cargo_Barrel_Detail", "Props/Prop_Barrel_Large.gltf", Vector3(-1.0, 0.10, 6.9), Vector3.ONE * 0.78, Vector3.ZERO)
	_create_static_box("Cargo_Barrel_Detail_Solid", Vector3(-1.0, 0.46, 6.9), Vector3(0.70, 0.92, 0.70), crate_mat, false)

	_create_static_box("Field_Front_Planter_Rail_Solid", Vector3(7.0, 0.34, 5.05), Vector3(10.8, 0.62, 0.32), planter_mat, true)
	_create_static_box("Field_Back_Planter_Rail_Solid", Vector3(7.0, 0.34, 12.45), Vector3(10.8, 0.62, 0.32), planter_mat, true)
	_create_decor_box("Field_Front_Planter_Light", Vector3(7.0, 0.72, 4.84), Vector3(9.8, 0.055, 0.045), amber_mat)
	_create_decor_box("Field_Back_Planter_Light", Vector3(7.0, 0.72, 12.66), Vector3(9.8, 0.055, 0.045), amber_mat)
	for index in range(6):
		var grass_x := 2.2 + float(index) * 1.9
		_create_nature_prop("Planter_Grass_Detail_%02d" % index, "Grass_Wispy_Tall.gltf", Vector3(grass_x, 0.70, 12.42), Vector3.ONE * 0.70, Vector3(0.0, float(index) * 43.0, 0.0))

	_create_static_box("Path_Safety_Barrier_Left_Solid", Vector3(-5.5, 0.44, 1.92), Vector3(3.4, 0.58, 0.24), metal_mat, true)
	_create_static_box("Path_Safety_Barrier_Right_Solid", Vector3(-0.6, 0.44, 7.08), Vector3(3.1, 0.58, 0.24), metal_mat, true)
	_create_decor_box("Path_Safety_Barrier_Left_Glow", Vector3(-5.5, 0.80, 1.78), Vector3(2.8, 0.045, 0.045), cyan_mat)
	_create_decor_box("Path_Safety_Barrier_Right_Glow", Vector3(-0.6, 0.80, 7.22), Vector3(2.5, 0.045, 0.045), cyan_mat)

	_create_decor_box("Floating_Scan_Panel_Field", Vector3(4.2, 1.95, 4.9), Vector3(1.35, 0.82, 0.045), glass_mat)
	_create_decor_box("Floating_Scan_Panel_Forest", Vector3(14.0, 2.15, -1.0), Vector3(1.1, 1.20, 0.045), glass_mat)
	_create_scifi_prop("Midground_Vent_Detail_A", "Props/Prop_Vent_Wide.gltf", Vector3(-12.8, 0.11, 2.1), Vector3.ONE * 0.95, Vector3(0.0, 90.0, 0.0))
	_create_scifi_prop("Midground_Cable_Detail_A", "Props/Prop_Cable_1.gltf", Vector3(-6.4, 0.14, 5.7), Vector3.ONE * 1.05, Vector3(0.0, 18.0, 0.0))
	_create_scifi_prop("Midground_Cable_Detail_B", "Props/Prop_Cable_3.gltf", Vector3(1.6, 0.14, 3.2), Vector3.ONE * 1.00, Vector3(0.0, -28.0, 0.0))


func _create_beauty_forest_vista() -> void:
	var infection_mat := _mat(Color(0.95, 0.32, 0.10), Color(1.0, 0.16, 0.03), 1.0)
	var root_mat := _mat(Color(0.075, 0.055, 0.035), Color(0.14, 0.04, 0.0), 0.12)
	var dead_trees := ["DeadTree_1.gltf", "DeadTree_2.gltf", "DeadTree_3.gltf", "TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_5.gltf"]
	var rocks := ["Rock_Medium_1.gltf", "Rock_Medium_2.gltf", "Rock_Medium_3.gltf", "RockPath_Round_Wide.gltf"]
	var tree_points := [
		Vector3(16.0, 0.02, -6.5),
		Vector3(18.2, 0.02, -13.0),
		Vector3(20.5, 0.02, -2.8),
		Vector3(22.8, 0.02, -16.4),
		Vector3(24.2, 0.02, -7.8),
		Vector3(27.4, 0.02, -14.6),
		Vector3(30.5, 0.02, -5.4),
		Vector3(32.6, 0.02, -18.0)
	]
	for index in range(tree_points.size()):
		var pos: Vector3 = tree_points[index]
		var model: String = dead_trees[index % dead_trees.size()]
		_create_nature_prop("Composed_Dying_Tree_%02d" % index, model, pos, Vector3.ONE * (1.25 + float(index % 3) * 0.25), Vector3(0.0, -35.0 + float(index) * 47.0, 0.0))

	for index in range(12):
		var x := 15.5 + float(index % 4) * 4.2
		var z: float = -3.5 - floorf(float(index) / 4.0) * 5.2
		var ground_model: String = rocks[index % rocks.size()]
		_create_nature_prop("Composed_Forest_Rock_%02d" % index, ground_model, Vector3(x, 0.05, z), Vector3.ONE * (0.80 + randf() * 0.45), Vector3(0.0, randf_range(0.0, 360.0), 0.0))

	for index in range(9):
		var pod := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.18 + float(index % 3) * 0.055
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		pod.mesh = mesh
		pod.position = Vector3(17.5 + float(index % 3) * 4.2, mesh.radius + 0.04, -5.0 - floorf(float(index) / 3.0) * 4.5)
		pod.material_override = infection_mat
		add_child(pod)

	for index in range(6):
		var root := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.06
		mesh.bottom_radius = 0.12
		mesh.height = 5.0 + float(index % 3)
		mesh.radial_segments = 8
		root.mesh = mesh
		root.position = Vector3(18.0 + float(index) * 2.1, 0.24, -2.2 - float(index % 3) * 4.3)
		root.rotation_degrees = Vector3(82.0, -22.0 + float(index) * 33.0, 90.0)
		root.material_override = root_mat
		add_child(root)

	_create_nature_prop("Boss_Arena_Composed_Tree_Left", "DeadTree_5.gltf", Vector3(23.6, 0.02, -13.2), Vector3.ONE * 2.0, Vector3(0.0, -35.0, 0.0))
	_create_nature_prop("Boss_Arena_Composed_Tree_Right", "TwistedTree_5.gltf", Vector3(29.2, 0.02, -9.2), Vector3.ONE * 1.9, Vector3(0.0, 128.0, 0.0))
	_create_scifi_prop("Signal_Broken_Access_Composed", "Props/Prop_AccessPoint.gltf", Vector3(25.7, 0.09, -9.4), Vector3.ONE * 1.05, Vector3(0.0, 110.0, 0.0))


func _create_beauty_skyline() -> void:
	var far_mat := _mat(Color(0.018, 0.033, 0.042), Color(0.0, 0.012, 0.018), 0.0)
	var neon_mat := _mat(Color(0.22, 0.88, 1.0), Color(0.12, 0.80, 1.0), 0.65)
	for index in range(7):
		var height := 4.5 + float((index * 19) % 6) * 1.15
		var z := -21.0 + float(index) * 6.6
		_create_decor_box("Distant_City_Silhouette_Clean_%02d" % index, Vector3(41.0, height * 0.5 - 0.12, z), Vector3(2.1, height, 2.0), far_mat)
		if index % 2 == 0:
			_create_decor_box("Distant_City_Antenna_Clean_%02d" % index, Vector3(41.0, height + 0.95, z), Vector3(0.13, 1.6, 0.13), neon_mat)


func _create_ground() -> void:
	var ground := StaticBody3D.new()
	ground.name = "Alpha_Ground"
	add_child(ground)

	var ground_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(84.0, 1.0, 84.0)
	ground_mesh.mesh = box_mesh
	ground_mesh.material_override = _mat(Color(0.145, 0.18, 0.15), Color(0.01, 0.04, 0.025), 0.0, true)
	ground_mesh.position.y = -0.55
	ground.add_child(ground_mesh)

	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(84.0, 1.0, 84.0)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -0.55
	ground.add_child(ground_collision)

	_create_decor_box("City_Clean_Plaza_Base", Vector3(-17, -0.032, 4), Vector3(25, 0.08, 25), _mat(Color(0.25, 0.34, 0.35), Color(0.02, 0.08, 0.09), 0.0))
	_create_decor_box("Forest_Sick_Soil", Vector3(22, -0.025, -8), Vector3(31, 0.08, 32), _mat(Color(0.10, 0.115, 0.075), Color(0.08, 0.14, 0.03), 0.0, true))

	var plaza_a := _mat(Color(0.31, 0.40, 0.40), Color(0.02, 0.08, 0.09), 0.0)
	var plaza_b := _mat(Color(0.20, 0.28, 0.29), Color(0.02, 0.07, 0.08), 0.0)
	var seam_mat := _mat(Color(0.27, 0.92, 1.0), Color(0.18, 0.88, 1.0), 0.85)
	for x_index in range(5):
		for z_index in range(5):
			var tile_position := Vector3(-27.0 + x_index * 5.0, 0.025, -6.0 + z_index * 5.0)
			var tile_mat := plaza_a if (x_index + z_index) % 2 == 0 else plaza_b
			_create_decor_box("Plaza_Ceramic_Tile_%d_%d" % [x_index, z_index], tile_position, Vector3(4.72, 0.035, 4.72), tile_mat)
	for index in range(9):
		_create_decor_box("Plaza_Neon_Seam_A_%d" % index, Vector3(-27.0 + index * 3.0, 0.072, -18.2), Vector3(1.8, 0.035, 0.08), seam_mat)
		_create_decor_box("Plaza_Neon_Seam_B_%d" % index, Vector3(-27.0 + index * 3.0, 0.072, 15.2), Vector3(1.8, 0.035, 0.08), seam_mat)
	for index in range(12):
		var patch_mat := _mat(Color(0.07 + randf() * 0.04, 0.10 + randf() * 0.03, 0.055), Color(0.05, 0.13, 0.02), 0.0, true)
		_create_decor_box("Forest_Decay_Patch_%d" % index, Vector3(randf_range(10.0, 34.0), 0.015, randf_range(-24.0, 6.0)), Vector3(randf_range(2.0, 5.2), 0.03, randf_range(1.6, 4.6)), patch_mat)


func _create_roads() -> void:
	var road_mat := _mat(Color(0.17, 0.205, 0.205), Color(0.01, 0.04, 0.045), 0.0)
	_create_decor_box("Main_Road_Shadow", Vector3(-6, 0.012, 6), Vector3(43, 0.045, 5.0), road_mat)
	_create_decor_box("Forest_Road_Shadow", Vector3(13, 0.018, -1), Vector3(5.2, 0.045, 21), road_mat)

	for index in range(10):
		var x := -24.0 + index * 4.0
		var platform := "Platforms/Platform_Metal.gltf" if index % 2 == 0 else "Platforms/Platform_DarkPlates.gltf"
		_create_scifi_prop("Main_Platform_%02d" % index, platform, Vector3(x, 0.05, 6.0), Vector3.ONE * 1.55, Vector3(0.0, 90.0, 0.0))
		if index % 2 == 0:
			_create_scifi_prop("Main_Rail_Left_%02d" % index, "Props/Prop_Rail_4.gltf", Vector3(x, 0.36, 3.15), Vector3.ONE * 1.35, Vector3(0.0, 90.0, 0.0))
			_create_scifi_prop("Main_Rail_Right_%02d" % index, "Props/Prop_Rail_4.gltf", Vector3(x, 0.36, 8.85), Vector3.ONE * 1.35, Vector3(0.0, -90.0, 0.0))

	for index in range(6):
		var z := -14.0 + index * 4.0
		_create_scifi_prop("Forest_Service_Platform_%02d" % index, "Platforms/Platform_Metal2.gltf", Vector3(13.0, 0.05, z), Vector3.ONE * 1.48, Vector3.ZERO)
		if index % 2 == 1:
			_create_scifi_prop("Forest_Service_Light_%02d" % index, "Props/Prop_Light_Floor.gltf", Vector3(15.4, 0.18, z), Vector3.ONE * 1.25, Vector3(0.0, 180.0, 0.0))

	var stripe_mat := _mat(Color(0.55, 0.92, 0.88), Color(0.24, 0.95, 0.88), 0.55)
	for index in range(10):
		_create_decor_box("Road_Light_%d" % index, Vector3(-24 + index * 4.0, 0.08, 3.35), Vector3(1.1, 0.06, 0.08), stripe_mat)
		_create_decor_box("Road_Light_B_%d" % index, Vector3(-24 + index * 4.0, 0.08, 8.65), Vector3(1.1, 0.06, 0.08), stripe_mat)


func _create_veyr_station() -> void:
	var white_mat := _mat(Color(0.48, 0.62, 0.63), Color(0.08, 0.22, 0.24), 0.0)
	var glass_mat := _mat(Color(0.20, 0.58, 0.62, 0.70), Color(0.13, 0.88, 1.0), 0.35)
	var dark_mat := _mat(Color(0.12, 0.16, 0.18), Color(0.02, 0.05, 0.06), 0.0)
	var neon_mat := _mat(Color(0.26, 0.92, 1.0), Color(0.2, 0.9, 1.0), 1.1)

	_create_static_box("Veyr_Wall_Back_Collision", Vector3(-27.8, 1.0, -8), Vector3(1.2, 2.0, 29.0), white_mat, false)
	_create_static_box("Veyr_Wall_Left_Collision", Vector3(-16, 0.9, -23), Vector3(22.0, 1.8, 1.0), white_mat, false)
	_create_static_box("Veyr_Gate_Left_Collision", Vector3(-14.6, 2.0, 16), Vector3(0.8, 4.0, 1.0), white_mat, false)
	_create_static_box("Veyr_Gate_Right_Collision", Vector3(-5.4, 2.0, 16), Vector3(0.8, 4.0, 1.0), white_mat, false)
	_create_static_box("Veyr_Gate_Top_Collision", Vector3(-10, 4.2, 16), Vector3(9.4, 0.7, 1.0), white_mat, false)
	_create_static_box("Command_Tower_Collision", Vector3(-25.5, 4.4, 12.5), Vector3(2.8, 8.8, 2.8), dark_mat, false)
	_create_decor_box("Command_Tower_Light", Vector3(-25.5, 11.4, 12.5), Vector3(3.7, 0.25, 3.7), neon_mat)

	for index in range(7):
		var z := -20.0 + index * 4.0
		_create_scifi_prop("Veyr_Back_Wall_Astra_%02d" % index, "Walls/WallAstra_Straight.gltf", Vector3(-27.4, 0.05, z), Vector3.ONE * 1.52, Vector3(0.0, 90.0, 0.0))
		_create_scifi_prop("Veyr_Back_Top_Cables_%02d" % index, "Walls/TopCables_Straight.gltf", Vector3(-27.4, 2.7, z), Vector3.ONE * 1.52, Vector3(0.0, 90.0, 0.0))
	for index in range(5):
		var x := -24.0 + index * 4.0
		_create_scifi_prop("Veyr_North_Wall_%02d" % index, "Walls/WallWindow_Straight.gltf", Vector3(x, 0.05, -22.6), Vector3.ONE * 1.52, Vector3.ZERO)
		_create_scifi_prop("Veyr_North_Top_%02d" % index, "Walls/TopWindow_Straight.gltf", Vector3(x, 2.7, -22.6), Vector3.ONE * 1.52, Vector3.ZERO)
	_create_scifi_prop("Veyr_Gate_Frame", "Platforms/Door_Frame_SquareTall.gltf", Vector3(-10.0, 0.08, 16.0), Vector3.ONE * 2.6, Vector3(0.0, 180.0, 0.0))
	_create_scifi_prop("Veyr_Gate_Door_Left", "Platforms/Door_Metal.gltf", Vector3(-13.0, 0.08, 15.7), Vector3.ONE * 1.55, Vector3(0.0, 180.0, 0.0))
	_create_scifi_prop("Veyr_Gate_Door_Right", "Platforms/Door_DarkMetal.gltf", Vector3(-7.0, 0.08, 15.7), Vector3.ONE * 1.55, Vector3(0.0, 180.0, 0.0))
	for index in range(3):
		_create_scifi_prop("Command_Tower_Column_%02d" % index, "Columns/Column_Large_Straight.gltf", Vector3(-25.5, 0.05 + index * 3.1, 12.5), Vector3.ONE * 1.55, Vector3(0.0, float(index) * 32.0, 0.0))
	_create_scifi_prop("Command_Tower_Antenna", "Columns/Column_Pipes.gltf", Vector3(-25.5, 9.5, 12.5), Vector3.ONE * 1.25, Vector3.ZERO)
	_create_scifi_prop("Command_Tower_Terminal", "Props/Prop_AccessPoint.gltf", Vector3(-24.1, 0.08, 11.0), Vector3.ONE * 1.35, Vector3(0.0, 90.0, 0.0))

	_create_static_box("Greenhouse_Block", Vector3(-15, 0.85, 6), Vector3(7.6, 1.7, 4.8), glass_mat, false)
	_create_decor_box("Greenhouse_Rib_A", Vector3(-15, 2.4, 3.4), Vector3(8.4, 0.16, 0.18), neon_mat)
	_create_decor_box("Greenhouse_Rib_B", Vector3(-15, 2.4, 8.6), Vector3(8.4, 0.16, 0.18), neon_mat)
	for index in range(2):
		_create_scifi_prop("Greenhouse_Window_%02d" % index, "Platforms/Platform_Window_Wide.gltf", Vector3(-17.0 + index * 4.0, 0.14, 6.0), Vector3.ONE * 1.6, Vector3(0.0, 90.0, 0.0))
	_create_scifi_prop("Greenhouse_Door", "Platforms/Door_Frame_A.gltf", Vector3(-10.5, 0.08, 6.0), Vector3.ONE * 1.55, Vector3(0.0, 90.0, 0.0))

	_create_static_box("Med_Bay_Collision", Vector3(-7, 0.9, -6), Vector3(4.8, 1.8, 3.8), white_mat, false)
	_create_decor_box("Med_Bay_Cross_H", Vector3(-7, 2.6, -8.35), Vector3(2.2, 0.16, 0.12), neon_mat)
	_create_decor_box("Med_Bay_Cross_V", Vector3(-7, 2.6, -8.36), Vector3(0.18, 1.5, 0.12), neon_mat)
	_create_scifi_prop("Med_Bay_Door", "Platforms/Door_Frame_Square.gltf", Vector3(-7.0, 0.08, -8.55), Vector3.ONE * 1.7, Vector3.ZERO)
	_create_scifi_prop("Med_Bay_Computer", "Props/Prop_Computer.gltf", Vector3(-4.2, 0.08, -5.0), Vector3.ONE * 1.25, Vector3(0.0, -90.0, 0.0))
	_create_scifi_prop("Med_Bay_Light_Wide", "Props/Prop_Light_Wide.gltf", Vector3(-7.0, 2.48, -4.2), Vector3.ONE * 1.35, Vector3.ZERO)

	_create_static_box("Market_Kiosk_Collision", Vector3(-10, 0.65, 13.5), Vector3(3.2, 1.3, 1.8), dark_mat, false)
	_create_static_box("Repair_Kiosk_Collision", Vector3(-3, 0.65, 13.5), Vector3(3.2, 1.3, 1.8), dark_mat, false)
	_create_blueprint_chamber()
	_create_scifi_prop("Repair_Kiosk_Frame", "Props/Prop_ItemHolder.gltf", Vector3(-3.0, 0.08, 13.45), Vector3.ONE * 1.55, Vector3(0.0, 180.0, 0.0))
	_create_scifi_prop("Repair_Kiosk_Computer", "Props/Prop_Computer.gltf", Vector3(-3.8, 0.08, 12.25), Vector3.ONE * 1.2, Vector3(0.0, 20.0, 0.0))

	_create_scifi_prop("Command_Access_Platform", "Platforms/Platform_Round1.gltf", Vector3(-20.5, 0.06, -4.5), Vector3.ONE * 1.9, Vector3.ZERO)
	_create_scifi_prop("Command_Access_Point", "Props/Prop_AccessPoint.gltf", Vector3(-20.3, 0.08, -4.9), Vector3.ONE * 1.4, Vector3(0.0, 90.0, 0.0))
	_create_glb_prop("Old_Fountain_Repurposed", CITY_MODEL_PATH + "pavement-fountain.glb", Vector3(-17.0, 0.08, 4.5), Vector3.ONE * 1.75, Vector3.ZERO)
	_create_scifi_prop("Fountain_Energy_Ring", "Platforms/Platform_Round1.gltf", Vector3(-17.0, 0.12, 4.5), Vector3.ONE * 1.95, Vector3.ZERO)
	_create_character_preview_lineup()

	for index in range(7):
		_create_lamp(Vector3(-22 + index * 3.6, 0.0, 15.0), Color(0.35, 0.9, 1.0))


func _create_buffer_zone() -> void:
	var lab_mat := _mat(Color(0.62, 0.66, 0.60), Color(0.05, 0.08, 0.06), 0.0)
	var farm_mat := _mat(Color(0.34, 0.45, 0.28), Color(0.08, 0.14, 0.04), 0.0)
	var warning_mat := _mat(Color(0.95, 0.63, 0.13), Color(0.9, 0.35, 0.02), 0.65)

	_create_static_box("Field_Lab_Collision", Vector3(4, 1.2, 0), Vector3(5.2, 2.4, 4.0), lab_mat, false)
	_create_static_box("Guard_Post_Collision", Vector3(11.5, 1.4, 10), Vector3(3.2, 2.8, 3.2), lab_mat, false)
	_create_decor_box("Warning_Bar", Vector3(4, 2.55, -2.05), Vector3(4.7, 0.18, 0.12), warning_mat)
	_create_scifi_prop("Buffer_Lab_Frame", "Platforms/Door_Frame_SquareTall.gltf", Vector3(4.0, 0.08, -2.2), Vector3.ONE * 1.85, Vector3.ZERO)
	_create_scifi_prop("Buffer_Lab_Platform", "Platforms/Platform_3Plates.gltf", Vector3(4.0, 0.08, 0.8), Vector3.ONE * 1.65, Vector3.ZERO)
	_create_scifi_prop("Buffer_Lab_Cable", "Props/Prop_Cable_3.gltf", Vector3(6.2, 0.18, 0.6), Vector3.ONE * 1.45, Vector3(0.0, 30.0, 0.0))
	_create_scifi_prop("Guard_Post_Access", "Props/Prop_AccessPoint.gltf", Vector3(11.5, 0.08, 10.0), Vector3.ONE * 1.45, Vector3(0.0, -90.0, 0.0))
	_create_scifi_prop("Guard_Post_Column", "Columns/Column_MetalSupport.gltf", Vector3(11.5, 0.08, 10.0), Vector3.ONE * 1.55, Vector3.ZERO)

	for index in range(5):
		_create_decor_box("Crop_Row_%d" % index, Vector3(-1 + index * 2.0, 0.12, 10.5), Vector3(1.1, 0.18, 7.5), farm_mat)
		_create_sick_plant_cluster(Vector3(-1 + index * 2.0, 0.2, 9.0))
		_create_nature_prop("Crop_Grass_Tall_%d" % index, "Grass_Common_Tall.gltf", Vector3(-1 + index * 2.0, 0.08, 8.6), Vector3.ONE * 1.2, Vector3(0.0, float(index) * 37.0, 0.0))
		_create_nature_prop("Crop_Sick_Fern_%d" % index, "Fern_1.gltf", Vector3(-0.6 + index * 2.0, 0.08, 12.4), Vector3.ONE * 1.05, Vector3(0.0, float(index) * 61.0, 0.0))

	for index in range(4):
		_create_lamp(Vector3(3 + index * 4.0, 0.0, 5.2), Color(1.0, 0.62, 0.22))


func _create_dying_forest() -> void:
	var root_mat := _mat(Color(0.08, 0.10, 0.07), Color(0.02, 0.05, 0.01), 0.0)
	var infection_mat := _mat(Color(0.50, 0.95, 0.22), Color(0.35, 1.0, 0.15), 1.0)
	var dead_trees := ["DeadTree_1.gltf", "DeadTree_2.gltf", "DeadTree_3.gltf", "DeadTree_4.gltf", "DeadTree_5.gltf", "TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_3.gltf"]
	var rocks := ["Rock_Medium_1.gltf", "Rock_Medium_2.gltf", "Rock_Medium_3.gltf", "Pebble_Round_3.gltf", "Pebble_Square_4.gltf"]
	var grasses := ["Grass_Wispy_Tall.gltf", "Grass_Common_Short.gltf", "Plant_1_Big.gltf", "Plant_7_Big.gltf", "Fern_1.gltf"]

	for index in range(30):
		var x := randf_range(12.0, 34.0)
		var z := randf_range(-24.0, 7.0)
		var tree_model: String = dead_trees[index % dead_trees.size()]
		_create_nature_prop("Quaternius_Decay_Tree_%02d" % index, tree_model, Vector3(x, 0.02, z), Vector3.ONE * randf_range(1.05, 1.85), Vector3(0.0, randf_range(0.0, 360.0), 0.0))
		if index % 4 == 0:
			_create_dead_tree(Vector3(x + randf_range(-0.8, 0.8), 1.2, z + randf_range(-0.8, 0.8)), randf_range(0.55, 0.95))

	for index in range(32):
		var ground_model: String = rocks[index % rocks.size()] if index % 3 == 0 else grasses[index % grasses.size()]
		_create_nature_prop("Forest_Ground_Detail_%02d" % index, ground_model, Vector3(randf_range(12.0, 34.0), 0.05, randf_range(-24.0, 7.0)), Vector3.ONE * randf_range(0.75, 1.45), Vector3(0.0, randf_range(0.0, 360.0), 0.0))

	for index in range(16):
		var pod := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.22, 0.42)
		mesh.height = mesh.radius * 2.0
		pod.mesh = mesh
		pod.position = Vector3(randf_range(13.0, 34.0), mesh.radius, randf_range(-24.0, 4.0))
		pod.material_override = infection_mat
		add_child(pod)

	for index in range(11):
		var root := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.08
		mesh.bottom_radius = 0.14
		mesh.height = randf_range(4.0, 7.0)
		mesh.radial_segments = 8
		root.mesh = mesh
		root.position = Vector3(randf_range(14.0, 31.0), 0.22, randf_range(-22.0, 1.0))
		root.rotation_degrees = Vector3(80.0, randf_range(0.0, 360.0), 90.0)
		root.material_override = root_mat
		add_child(root)

	_create_nature_prop("Boss_Arena_DeadTree_Left", "DeadTree_5.gltf", Vector3(24.0, 0.02, -13.8), Vector3.ONE * 2.2, Vector3(0.0, -35.0, 0.0))
	_create_nature_prop("Boss_Arena_DeadTree_Right", "TwistedTree_5.gltf", Vector3(29.5, 0.02, -10.0), Vector3.ONE * 2.0, Vector3(0.0, 130.0, 0.0))
	_create_nature_prop("Boss_Arena_Rock_Path", "RockPath_Round_Wide.gltf", Vector3(27.0, 0.04, -12.0), Vector3.ONE * 1.8, Vector3.ZERO)
	_create_scifi_prop("Signal_Crashed_Access", "Props/Prop_AccessPoint.gltf", Vector3(25.8, 0.08, -9.5), Vector3.ONE * 1.2, Vector3(0.0, 110.0, 0.0))
	_create_scifi_prop("Signal_Broken_Crate", "Props/Prop_Crate4.gltf", Vector3(28.9, 0.08, -14.2), Vector3.ONE * 1.0, Vector3(0.0, 22.0, 0.0))


func _create_degradation_wave() -> void:
	degradation_wave = MeshInstance3D.new()
	degradation_wave.name = "Narrative_Degradation_Wave"
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 32
	mesh.rings = 16
	degradation_wave.mesh = mesh
	degradation_wave.position = Vector3(26.0, 0.2, -10.0)
	degradation_wave.scale = Vector3.ONE * 0.1
	degradation_wave.visible = false

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.04, 0.02, 0.01, 0.22)
	material.emission_enabled = true
	material.emission = Color(0.32, 0.06, 0.0)
	material.emission_energy_multiplier = 0.7
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	degradation_wave.material_override = material
	add_child(degradation_wave)


func _create_signal_beam() -> void:
	var beam_mat := _mat(Color(1.0, 0.34, 0.08, 0.34), Color(1.0, 0.20, 0.04), 1.45)
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var beam := MeshInstance3D.new()
	beam.name = "Orange_Signal_Beam"
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.22
	beam_mesh.bottom_radius = 0.62
	beam_mesh.height = 22.0
	beam_mesh.radial_segments = 18
	beam.mesh = beam_mesh
	beam.position = Vector3(26.0, 11.0, -10.0)
	beam.material_override = beam_mat
	add_child(beam)

	var ring_mat := _mat(Color(1.0, 0.50, 0.15), Color(1.0, 0.24, 0.05), 1.2)
	for index in range(4):
		var ring := MeshInstance3D.new()
		ring.name = "Signal_Ring_%02d" % index
		var torus := TorusMesh.new()
		torus.inner_radius = 0.86 + index * 0.34
		torus.outer_radius = 0.92 + index * 0.34
		torus.ring_segments = 42
		torus.rings = 8
		ring.mesh = torus
		ring.position = Vector3(26.0, 0.09 + index * 0.06, -10.0)
		ring.material_override = ring_mat
		add_child(ring)


func _create_background_skyline() -> void:
	var far_mat := _mat(Color(0.045, 0.075, 0.085), Color(0.0, 0.02, 0.03), 0.0)
	var neon_mat := _mat(Color(0.20, 0.86, 1.0), Color(0.13, 0.82, 1.0), 0.9)
	for index in range(14):
		var height := 5.0 + float((index * 17) % 7) * 1.25
		var x := -38.0 + index * 5.8
		_create_decor_box("Far_City_Silhouette_%02d" % index, Vector3(x, height * 0.5 - 0.1, -36.0), Vector3(2.8, height, 2.4), far_mat)
		if index % 3 == 0:
			_create_decor_box("Far_City_Antenna_%02d" % index, Vector3(x, height + 1.1, -36.0), Vector3(0.18, 2.0, 0.18), neon_mat)


func _create_atmosphere_particles() -> void:
	_create_mote_field("City_Cold_Motes", 38, Vector3(-14.0, 1.6, 4.5), Vector3(14.0, 1.8, 12.0), Color(0.45, 0.95, 1.0, 0.62), 0.025, 0.07)
	_create_mote_field("Forest_Spore_Motes", 70, Vector3(23.0, 1.25, -8.0), Vector3(16.0, 2.8, 18.0), Color(0.78, 1.0, 0.22, 0.58), 0.018, 0.09)
	_create_mote_field("Sick_Ember_Motes", 24, Vector3(26.0, 1.0, -12.0), Vector3(8.0, 1.4, 8.0), Color(1.0, 0.28, 0.12, 0.50), 0.022, 0.08)


func _create_mote_field(field_name: String, count: int, center: Vector3, extents: Vector3, tint: Color, min_radius: float, max_radius: float) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 1.15
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for index in range(count):
		var mote := MeshInstance3D.new()
		mote.name = "%s_%02d" % [field_name, index]
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(min_radius, max_radius)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 8
		mesh.rings = 4
		mote.mesh = mesh
		mote.material_override = material
		var local_position := Vector3(
			center.x + randf_range(-extents.x, extents.x),
			center.y + randf_range(-extents.y, extents.y),
			center.z + randf_range(-extents.z, extents.z)
		)
		mote.position = local_position
		mote.set_meta("base_position", local_position)
		mote.set_meta("phase", randf_range(0.0, TAU))
		mote.set_meta("speed", randf_range(0.35, 1.25))
		mote.set_meta("amplitude", randf_range(0.05, 0.24))
		add_child(mote)
		ambient_motes.append(mote)


func _animate_ambient_motes() -> void:
	var seconds := float(Time.get_ticks_msec()) / 1000.0
	for mote in ambient_motes:
		if mote == null or not is_instance_valid(mote):
			continue
		var base_position: Vector3 = mote.get_meta("base_position", mote.position)
		var phase := float(mote.get_meta("phase", 0.0))
		var speed := float(mote.get_meta("speed", 1.0))
		var amplitude := float(mote.get_meta("amplitude", 0.1))
		mote.position = base_position + Vector3(sin(seconds * speed + phase) * amplitude * 0.35, sin(seconds * speed * 1.4 + phase) * amplitude, cos(seconds * speed + phase) * amplitude * 0.35)


func _create_audio() -> void:
	var stream := load("res://assets/audio/kenney/ambience.ogg")
	if stream == null:
		return
	ambient_audio = AudioStreamPlayer.new()
	ambient_audio.name = "Kenney_Ambience"
	ambient_audio.stream = stream
	ambient_audio.volume_db = -18.0
	ambient_audio.autoplay = true
	add_child(ambient_audio)


func _create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player_Robert"
	player.set_script(PlayerController)
	player.set("character_id", selected_character_id)
	player.set("respawn_position", Vector3(-19.0, 1.0, 4.5))
	player.position = Vector3(-19.0, 1.0, 4.5)
	player.rotation_degrees.y = -90.0

	var body_collision := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.42
	capsule_shape.height = 1.8
	body_collision.shape = capsule_shape
	body_collision.position.y = 0.0
	player.add_child(body_collision)

	_create_robert_visual(player)
	_create_camera(player)

	add_child(player)
	player.interaction_requested.connect(_on_player_interaction_requested)
	player.combat_log.connect(_push_log)


func _create_robert_visual(parent: Node3D) -> void:
	var visual_root := Node3D.new()
	visual_root.name = "VisualRoot"
	visual_root.position.y = -0.98
	parent.add_child(visual_root)

	var armor_mat := _mat(Color(0.055, 0.070, 0.080), Color(0.0, 0.018, 0.026), 0.0)
	var plate_mat := _mat(Color(0.24, 0.30, 0.32), Color(0.02, 0.08, 0.09), 0.0)
	var red_mat := _mat(Color(0.82, 0.13, 0.07), Color(0.75, 0.05, 0.02), 0.22)
	var cyber_mat := _mat(Color(0.18, 0.85, 1.0), Color(0.08, 0.78, 1.0), 1.45)
	var blade_mat := _mat(Color(0.80, 0.88, 0.86), Color(0.10, 0.55, 0.72), 0.45)

	if USE_IMPORTED_PLAYER_MODEL:
		var imported_model := _create_imported_model(MODEL_ROBERT, "Robert_GLTF_Model", Vector3.ZERO, Vector3.ONE * 0.74, Vector3(0.0, 180.0, 0.0))
		if imported_model != null:
			visual_root.add_child(imported_model)
			_set_mesh_roughness(imported_model, 1.0)

	_add_child_mesh(visual_root, "Robert_Long_Coat_Back", _box_mesh(Vector3(0.72, 1.08, 0.10)), Vector3(0.0, 0.66, 0.27), Vector3.ONE, armor_mat)
	_add_child_mesh(visual_root, "Robert_Torso_Armored", _box_mesh(Vector3(0.66, 0.84, 0.36)), Vector3(0.0, 0.88, -0.02), Vector3.ONE, armor_mat)
	_add_child_mesh(visual_root, "Robert_Chest_Plate", _box_mesh(Vector3(0.54, 0.46, 0.06)), Vector3(0.0, 1.02, -0.23), Vector3.ONE, plate_mat)
	_add_child_mesh(visual_root, "Robert_Neck_Guard", _box_mesh(Vector3(0.60, 0.14, 0.26)), Vector3(0.0, 1.27, -0.02), Vector3.ONE, armor_mat)
	_add_child_mesh(visual_root, "Robert_Helmet_Shell", _sphere_mesh(0.32), Vector3(0.0, 1.50, -0.02), Vector3(0.86, 0.78, 0.88), plate_mat)
	_add_child_mesh(visual_root, "Robert_Helmet_Visor", _box_mesh(Vector3(0.42, 0.085, 0.04)), Vector3(0.0, 1.50, -0.30), Vector3.ONE, cyber_mat)
	_add_child_mesh(visual_root, "Right_Cyber_Eye", _box_mesh(Vector3(0.12, 0.055, 0.036)), Vector3(0.13, 1.535, -0.325), Vector3.ONE, cyber_mat)
	_add_child_mesh(visual_root, "Robert_RedScarf", _box_mesh(Vector3(0.76, 0.10, 0.13)), Vector3(0.0, 1.26, -0.22), Vector3.ONE, red_mat)
	_add_child_mesh(visual_root, "Robert_Left_Shoulder", _sphere_mesh(0.18), Vector3(-0.46, 1.15, -0.04), Vector3(1.25, 0.66, 0.82), plate_mat)
	_add_child_mesh(visual_root, "Robert_Right_Cyber_Shoulder", _sphere_mesh(0.20), Vector3(0.47, 1.15, -0.04), Vector3(1.32, 0.72, 0.88), cyber_mat)
	_add_child_mesh(visual_root, "Robert_Left_Arm", _capsule_mesh(0.075, 0.62), Vector3(-0.54, 0.76, -0.01), Vector3(0.70, 1.0, 0.70), armor_mat)
	_add_child_mesh(visual_root, "Robert_Right_Arm", _capsule_mesh(0.075, 0.62), Vector3(0.55, 0.76, -0.01), Vector3(0.70, 1.0, 0.70), plate_mat)
	_add_child_mesh(visual_root, "Robert_Left_Leg", _capsule_mesh(0.08, 0.72), Vector3(-0.18, 0.32, 0.02), Vector3(0.72, 1.0, 0.72), armor_mat)
	_add_child_mesh(visual_root, "Robert_Right_Leg", _capsule_mesh(0.08, 0.72), Vector3(0.18, 0.32, 0.02), Vector3(0.72, 1.0, 0.72), armor_mat)
	_add_child_mesh(visual_root, "Robert_Left_Boot", _box_mesh(Vector3(0.20, 0.11, 0.36)), Vector3(-0.18, 0.02, -0.09), Vector3.ONE, plate_mat)
	_add_child_mesh(visual_root, "Robert_Right_Boot", _box_mesh(Vector3(0.20, 0.11, 0.36)), Vector3(0.18, 0.02, -0.09), Vector3.ONE, plate_mat)

	var weapon_root := Node3D.new()
	weapon_root.name = "WeaponRoot"
	weapon_root.position = Vector3(0.55, 0.86, -0.28)
	weapon_root.rotation_degrees = Vector3(-20.0, -8.0, 10.0)
	visual_root.add_child(weapon_root)
	_add_child_mesh(weapon_root, "RifleBladeStock", _box_mesh(Vector3(0.12, 0.14, 0.86)), Vector3(0, 0, -0.18), Vector3.ONE, plate_mat)
	_add_child_mesh(weapon_root, "RifleBladeBarrel", _box_mesh(Vector3(0.08, 0.08, 0.92)), Vector3(0, 0.02, -0.78), Vector3.ONE, cyber_mat)
	_add_child_mesh(weapon_root, "Blade", _box_mesh(Vector3(0.09, 0.025, 0.72)), Vector3(0.14, 0.04, -1.12), Vector3.ONE, blade_mat)


func _create_camera(parent: Node3D) -> void:
	var camera_pivot := Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0, 1.38, 0)
	parent.add_child(camera_pivot)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 2.15, 6.35)
	camera.rotation_degrees.x = -15.0
	camera.current = true
	camera.fov = 55.0
	camera_pivot.add_child(camera)


func _spawn_gameplay_objects() -> void:
	_spawn_resource("sample_contamine", "Echantillon de culture malade", Vector3(3.2, 0.05, 8.4), Color(0.72, 1.0, 0.28))
	_spawn_resource("sample_contamine", "Spore claire instable", Vector3(7.0, 0.05, 10.4), Color(0.55, 1.0, 0.42))
	_spawn_resource("sample_contamine", "Racine noircie", Vector3(11.2, 0.05, 6.3), Color(0.58, 0.95, 0.25))
	_spawn_resource("biomasse", "Biomasse utile", Vector3(18.0, 0.05, -8.5), Color(0.85, 0.55, 0.18))
	_spawn_resource("biomasse", "Fibre malade", Vector3(24.0, 0.05, -15.0), Color(0.95, 0.40, 0.16))

	_spawn_station("blueprints", "Table de plans", "E : analyser un plan de craft", Vector3(-9.2, 0.0, 8.8), Color(0.95, 0.45, 1.0))
	_spawn_station("repair", "Reparateur PNJ", "E : reparer l'equipement", Vector3(-8.2, 0.0, 1.7), Color(0.35, 0.92, 1.0))
	_spawn_station("briefing", "Table de briefing", "E : relire l'objectif", Vector3(-17.0, 0.0, 4.6), Color(1.0, 0.82, 0.35))

	_spawn_enemy("Rôdeur contaminé", "organic", Vector3(15.3, 0.1, -4.7), 62.0, 2.9, 9.0, 1.55, 1.0)
	_spawn_enemy("Cerf-racine agressif", "organic", Vector3(19.3, 0.1, -11.0), 76.0, 3.0, 11.0, 1.65, 1.08)
	_spawn_enemy("Essaim de spores", "organic", Vector3(16.8, 0.1, 1.4), 48.0, 3.4, 8.0, 1.35, 0.82)
	_spawn_enemy("Moissonneuse dereglee", "machine", Vector3(8.2, 0.1, 2.8), 88.0, 2.45, 13.0, 2.0, 1.0)
	_spawn_enemy("Drone agricole instable", "machine", Vector3(12.6, 0.1, 5.6), 64.0, 2.8, 10.0, 1.65, 0.82)
	_spawn_enemy("Gardien-racine dominant", "boss", Vector3(27.0, 0.1, -12.0), 230.0, 2.25, 18.0, 2.25, 1.55)


func _spawn_resource(resource_id: String, title: String, world_position: Vector3, tint: Color) -> void:
	var resource := ResourceNode.new()
	resource.resource_id = resource_id
	resource.title = title
	resource.tint = tint
	resource.position = world_position
	add_child(resource)
	resource.gathered.connect(_on_resource_gathered)


func _spawn_station(station_id: String, station_title: String, prompt: String, world_position: Vector3, accent_color: Color) -> void:
	var station := InteractableStation.new()
	station.station_id = station_id
	station.station_title = station_title
	station.prompt = prompt
	station.accent_color = accent_color
	station.position = world_position
	add_child(station)
	station.used.connect(_on_station_used)


func _spawn_enemy(enemy_name: String, enemy_kind: String, world_position: Vector3, hp: float, speed: float, damage: float, range: float, scale_value: float) -> void:
	var enemy := EnemyBasic.new()
	enemy.enemy_name = enemy_name
	enemy.enemy_kind = enemy_kind
	enemy.max_health = hp
	enemy.move_speed = speed
	enemy.attack_damage = damage
	enemy.attack_range = range
	enemy.model_scale = scale_value
	if enemy_kind == "boss":
		enemy.detection_radius = 20.0
		enemy.attack_interval = 1.55
	elif enemy_kind == "machine":
		enemy.detection_radius = 12.5
		enemy.attack_interval = 1.35
	enemy.position = world_position
	add_child(enemy)
	enemy.set_target(player)
	enemy.died.connect(_on_enemy_died)
	enemy.damaged.connect(_on_enemy_damaged)


func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Alpha_UI"
	add_child(canvas)

	var top_panel := _panel(Vector2(18, 18), Vector2(330, 102), Color(0.02, 0.04, 0.05, 0.34), Color(0.27, 0.88, 1.0, 0.44))
	canvas.add_child(top_panel)
	status_label = _ui_label(Vector2(12, 7), Vector2(306, 88), 12, Color(0.92, 1.0, 0.96))
	top_panel.add_child(status_label)

	var quest_panel := _panel(Vector2(18, 584), Vector2(470, 102), Color(0.03, 0.025, 0.02, 0.38), Color(1.0, 0.68, 0.22, 0.54))
	canvas.add_child(quest_panel)
	quest_label = _ui_label(Vector2(12, 8), Vector2(446, 84), 12, Color(1.0, 0.93, 0.78))
	quest_panel.add_child(quest_label)

	var log_panel := _panel(Vector2(890, 585), Vector2(340, 100), Color(0.015, 0.018, 0.02, 0.34), Color(0.58, 1.0, 0.52, 0.34))
	canvas.add_child(log_panel)
	log_label = _ui_label(Vector2(10, 7), Vector2(318, 82), 11, Color(0.86, 1.0, 0.82))
	log_panel.add_child(log_label)

	prompt_label = Label.new()
	prompt_label.position = Vector2(430, 492)
	prompt_label.size = Vector2(450, 42)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.72))
	canvas.add_child(prompt_label)

	cinematic_label = Label.new()
	cinematic_label.position = Vector2(200, 96)
	cinematic_label.size = Vector2(880, 170)
	cinematic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cinematic_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cinematic_label.add_theme_font_size_override("font_size", 24)
	cinematic_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.62))
	cinematic_label.visible = false
	canvas.add_child(cinematic_label)


func _load_character_preview() -> void:
	var json_text := FileAccess.get_file_as_string(CHARACTERS_PATH)
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_ARRAY:
		status_label.text = "BlockForge Alpha - Donnees de profil introuvables."
		return

	for character in data:
		if character.get("id", "") == selected_character_id:
			selected_character_data = character
			break

	if selected_character_data.is_empty():
		status_label.text = "BlockForge Alpha - Profil non trouve."
		return


func _update_ui() -> void:
	if status_label == null or player == null:
		return

	var snapshot: Dictionary = player.get_status_snapshot()

	status_label.text = "BlockForge Alpha - prototype local\n%s | %s\nPV %d/%d   Stamina %d/%d\nCible : %s\nLMB action | RMB action secondaire | F outil" % [
		selected_character_data.get("name", "Robert"),
		selected_character_data.get("role", "Degats + survie"),
		int(round(snapshot.get("health", 0.0))),
		int(round(snapshot.get("max_health", 0.0))),
		int(round(snapshot.get("stamina", 0.0))),
		int(round(snapshot.get("max_stamina", 0.0))),
		snapshot.get("locked_target", "aucune")
	]

	quest_label.text = _quest_text()
	log_label.text = "Journal alpha\n" + "\n".join(combat_log_lines)

	var nearest := _get_nearest_interactable(3.0)
	if nearest != null and nearest.has_method("get_interaction_prompt"):
		prompt_label.text = nearest.get_interaction_prompt()
	else:
		prompt_label.text = ""

	if objective_marker != null:
		objective_marker.text = _objective_marker_text()


func _quest_text() -> String:
	var samples_text := "%d/3" % harvested_samples
	var machines_text := "%d/2" % destroyed_machines

	match quest_stage:
		0:
			return "Les cultures silencieuses\nRecolter 3 echantillons contamines : %s\nLes machines reagissent a un signal inconnu.\n\nRessources : %s | Jetons : %d | Doublons : %d" % [samples_text, _resource_summary(), alpha_tokens, duplicate_points]
		1:
			return "Les cultures silencieuses\nEchantillons recuperes.\nNeutraliser 2 machines dereglees : %s\n\nRessources : %s | Jetons : %d | Doublons : %d" % [machines_text, _resource_summary(), alpha_tokens, duplicate_points]
		2:
			return "Les cultures silencieuses\nLes machines portaient la meme signature.\nSource detectee : Gardien-racine dominant.\n\nConseil : seul possible, mais dur."
		3:
			return "Les cultures silencieuses\nBoss vaincu.\nLa foret ne remercie pas les joueurs : sa mort empire le declin.\nLes PNJ reagiront dans la prochaine version."
		_:
			return "Quete principale : donnees indisponibles."


func _objective_marker_text() -> String:
	match quest_stage:
		0:
			return "Echantillons"
		1:
			return "Machines dereglees"
		2:
			return "Signal inconnu"
		3:
			return "Nature degradee"
		_:
			return "Objectif"


func _resource_summary() -> String:
	if resource_counts.is_empty():
		return "aucune"
	var parts: Array[String] = []
	for key in resource_counts.keys():
		parts.append("%s x%d" % [str(key), int(resource_counts[key])])
	return ", ".join(parts)


func _on_player_interaction_requested() -> void:
	var nearest := _get_nearest_interactable(3.1)
	if nearest == null:
		_push_log("Rien d'utilisable a portee.")
		return
	if nearest.has_method("interact"):
		nearest.interact(player)


func _get_nearest_interactable(max_distance: float) -> Node3D:
	if player == null:
		return null

	var best: Node3D
	var best_distance := max_distance
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(candidate):
			continue
		if not (candidate is Node3D):
			continue
		var node := candidate as Node3D
		var distance := player.global_position.distance_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = node
	return best


func _on_resource_gathered(_node: Node, resource_id: String, amount: int) -> void:
	resource_counts[resource_id] = int(resource_counts.get(resource_id, 0)) + amount
	if resource_id == "sample_contamine":
		harvested_samples += amount
		alpha_tokens += 1
		_push_log("Echantillon recupere. La table de plans gagne 1 fragment de craft.")
	elif resource_id == "biomasse":
		_push_log("Biomasse recoltee : future matiere de craft.")
	else:
		_push_log("Ressource recoltee : %s." % resource_id)
	_update_quest_progress()


func _on_station_used(station_id: String, station_title: String) -> void:
	match station_id:
		"blueprints":
			_perform_blueprint_unlock()
		"repair":
			if player != null and player.has_method("heal"):
				player.heal(24.0)
			_push_log("Reparation alpha : equipement stabilise, le joueur soigne legerement ses blessures.")
		"briefing":
			_push_log("Briefing : les cultures meurent sans bruit. Le signal forestier n'est pas naturel.")
		_:
			_push_log("%s n'a pas encore de fonction." % station_title)


func _perform_blueprint_unlock() -> void:
	if alpha_tokens <= 0:
		_push_log("Table de plans : aucun fragment disponible. Recolte des echantillons.")
		return

	alpha_tokens -= 1
	var reward := _roll_blueprint_reward()
	var reward_key := "%s:%s" % [reward.get("rarity", "?"), reward.get("name", "recompense")]
	if unlocked_rewards.has(reward_key):
		duplicate_points += int(reward.get("dupe_points", 5))
		_push_log("Plan [%s] deja connu : %s -> +%d pieces de recherche." % [reward.get("rarity", "?"), reward.get("name", "recompense"), int(reward.get("dupe_points", 5))])
	else:
		unlocked_rewards[reward_key] = true
		_push_log("Plan [%s] appris : %s." % [reward.get("rarity", "?"), reward.get("name", "recompense")])


func _roll_blueprint_reward() -> Dictionary:
	var table: Array[Dictionary] = [
		{"name": "Plan de pioche simple", "rarity": "R", "weight": 42, "dupe_points": 5},
		{"name": "Texture de bloc : pierre usee", "rarity": "R", "weight": 34, "dupe_points": 5},
		{"name": "Plan de hache de depart", "rarity": "SR", "weight": 16, "dupe_points": 12},
		{"name": "Plan de table de craft", "rarity": "SR", "weight": 7, "dupe_points": 12},
		{"name": "Plan rare : lanterne de mine", "rarity": "SSR", "weight": 1, "dupe_points": 30}
	]

	var total_weight := 0
	for reward in table:
		total_weight += int(reward.get("weight", 1))

	var roll := randi_range(1, total_weight)
	var cursor := 0
	for reward in table:
		cursor += int(reward.get("weight", 1))
		if roll <= cursor:
			return reward
	return table[0]


func _on_enemy_damaged(enemy: Node, amount: float, _health: float) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if amount >= 35.0:
		_push_log("Gros impact sur %s." % _enemy_name(enemy))


func _on_enemy_died(enemy: Node) -> void:
	var kind := str(enemy.get("enemy_kind"))
	if kind == "machine":
		destroyed_machines += 1
		alpha_tokens += 1
		_push_log("%s neutralise. +1 jeton alpha de test." % _enemy_name(enemy))
	elif kind == "boss":
		boss_defeated = true
		_push_log("Le Gardien-racine dominant s'effondre. Quelque chose se brise sous la foret.")
		_start_boss_aftermath()
	else:
		defeated_organics += 1
		_push_log("%s vaincu. La contamination pulse encore dans le sol." % _enemy_name(enemy))
	_update_quest_progress()


func _enemy_name(enemy: Node) -> String:
	if enemy.has_method("get_display_name"):
		return enemy.get_display_name()
	return enemy.name


func _update_quest_progress() -> void:
	if quest_stage == 0 and harvested_samples >= 3:
		quest_stage = 1
		_push_log("Analyse terminee : les echantillons vibrent avec le meme signal que les machines.")
	if quest_stage == 1 and destroyed_machines >= 2:
		quest_stage = 2
		_push_log("Signal triangule : la source respire dans la foret mourante.")
	if quest_stage == 2 and boss_defeated:
		quest_stage = 3
		_push_log("Victoire ambigue : la mort du boss degrade la nature autour de lui.")


func _start_boss_aftermath() -> void:
	cinematic_timer = 7.0
	if cinematic_label != null:
		cinematic_label.text = "CINEMATIQUE ALPHA\nLe boss tombe. Les racines sechent. Une vague noire traverse la foret.\nA la radio, la ville celebre... mais certains PNJ se taisent."
		cinematic_label.visible = true
	if degradation_wave != null:
		degradation_wave.visible = true
		degradation_wave.scale = Vector3.ONE * 0.2
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.fog_density = 0.034
		world_environment.environment.background_color = Color(0.09, 0.10, 0.08)


func _update_cinematic(delta: float) -> void:
	if cinematic_timer <= 0.0:
		if cinematic_label != null:
			cinematic_label.visible = false
		return

	cinematic_timer = max(cinematic_timer - delta, 0.0)
	if degradation_wave != null:
		var progress := 1.0 - cinematic_timer / 7.0
		degradation_wave.scale = Vector3.ONE * lerp(0.2, 22.0, progress)
		degradation_wave.position.y = 0.22 + sin(progress * PI) * 0.2
	if cinematic_timer <= 0.0 and cinematic_label != null:
		cinematic_label.visible = false


func _push_log(message: String) -> void:
	combat_log_lines.append(message)
	while combat_log_lines.size() > 5:
		combat_log_lines.remove_at(0)


func _panel(local_position: Vector2, local_size: Vector2, background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = local_position
	panel.size = local_size
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _ui_label(local_position: Vector2, local_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = local_position
	label.size = local_size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _create_static_box(node_name: String, world_position: Vector3, size: Vector3, material: StandardMaterial3D, show_mesh: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = world_position
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.visible = show_mesh
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body


func _create_decor_box(node_name: String, world_position: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = world_position
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance


func _create_decor_box_rotated(node_name: String, world_position: Vector3, size: Vector3, material: StandardMaterial3D, rotation_deg: Vector3) -> MeshInstance3D:
	var mesh_instance := _create_decor_box(node_name, world_position, size, material)
	mesh_instance.rotation_degrees = rotation_deg
	return mesh_instance


func _create_dead_tree(world_position: Vector3, scale_value: float) -> void:
	var trunk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.16
	mesh.bottom_radius = 0.32
	mesh.height = 3.1
	mesh.radial_segments = 8
	trunk.mesh = mesh
	trunk.position = world_position
	trunk.scale = Vector3.ONE * scale_value
	trunk.rotation_degrees.z = randf_range(-10.0, 10.0)
	trunk.material_override = _mat(Color(0.10, 0.13, 0.09), Color(0.02, 0.04, 0.01), 0.0)
	add_child(trunk)

	for index in range(3):
		var branch := MeshInstance3D.new()
		var branch_mesh := CylinderMesh.new()
		branch_mesh.top_radius = 0.045
		branch_mesh.bottom_radius = 0.08
		branch_mesh.height = randf_range(1.2, 1.9)
		branch_mesh.radial_segments = 8
		branch.mesh = branch_mesh
		branch.position = world_position + Vector3(0, 1.3 + index * 0.32, 0)
		branch.scale = Vector3.ONE * scale_value
		branch.rotation_degrees = Vector3(randf_range(38.0, 65.0), randf_range(0.0, 360.0), randf_range(-40.0, 40.0))
		branch.material_override = trunk.material_override
		add_child(branch)


func _create_sick_plant_cluster(world_position: Vector3) -> void:
	var material := _mat(Color(0.20, 0.35, 0.14), Color(0.25, 0.65, 0.08), 0.25)
	for index in range(4):
		var plant := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.02
		mesh.bottom_radius = 0.045
		mesh.height = randf_range(0.35, 0.75)
		mesh.radial_segments = 6
		plant.mesh = mesh
		plant.position = world_position + Vector3(randf_range(-0.45, 0.45), 0.25, randf_range(-2.2, 2.2))
		plant.rotation_degrees.z = randf_range(-18.0, 18.0)
		plant.material_override = material
		add_child(plant)


func _create_lamp(world_position: Vector3, light_color: Color) -> void:
	var pole_mat := _mat(Color(0.16, 0.18, 0.18), Color(0, 0, 0), 0.0)
	var glow_mat := _mat(light_color, light_color, 1.35)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.04
	pole_mesh.bottom_radius = 0.06
	pole_mesh.height = 2.2
	pole_mesh.radial_segments = 8
	pole.mesh = pole_mesh
	pole.position = world_position + Vector3(0, 1.1, 0)
	pole.material_override = pole_mat
	add_child(pole)

	var light_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	light_mesh.mesh = sphere
	light_mesh.position = world_position + Vector3(0, 2.28, 0)
	light_mesh.material_override = glow_mat
	add_child(light_mesh)

	var omni := OmniLight3D.new()
	omni.light_color = light_color
	omni.light_energy = 0.45
	omni.omni_range = 4.0
	omni.position = light_mesh.position
	add_child(omni)


func _create_label_3d(text: String, world_position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = world_position
	label.modulate = color
	label.font_size = font_size
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	return label


func _create_character_preview_lineup() -> void:
	_create_character_preview("Mineur\noutils", MODEL_ROBERT, Vector3(-20.6, 0.05, 10.6), Color(0.3, 0.95, 1.0), 0.58)
	_create_character_preview("Bucheronne\nbois", MODEL_SOREN, Vector3(-18.0, 0.05, 10.6), Color(0.45, 1.0, 0.45), 0.58)
	_create_character_preview("Artisan\ncraft", MODEL_AUGUSTIN, Vector3(-15.4, 0.05, 10.6), Color(1.0, 0.68, 0.22), 0.58)
	_create_character_preview("Exploratrice\nsurvie", MODEL_MEDIC, Vector3(-12.8, 0.05, 10.6), Color(0.78, 0.65, 1.0), 0.58)


func _create_blueprint_chamber() -> void:
	var magenta := _mat(Color(0.90, 0.22, 1.0), Color(0.95, 0.18, 1.0), 1.25)
	var gold := _mat(Color(1.0, 0.72, 0.26), Color(1.0, 0.45, 0.08), 0.65)
	var dark := _mat(Color(0.055, 0.065, 0.08), Color(0.02, 0.01, 0.04), 0.0)

	_create_scifi_prop("Blueprint_Chamber_Platform", "Platforms/Platform_Round1.gltf", Vector3(-10.0, 0.08, 13.55), Vector3.ONE * 2.2, Vector3.ZERO)
	_create_scifi_prop("Blueprint_Chamber_Item_Holder", "Props/Prop_ItemHolder.gltf", Vector3(-10.0, 0.10, 13.35), Vector3.ONE * 1.55, Vector3(0.0, 180.0, 0.0))
	_create_scifi_prop("Blueprint_Chamber_Chest", "Props/Prop_Chest.gltf", Vector3(-11.15, 0.08, 12.85), Vector3.ONE * 1.05, Vector3(0.0, 25.0, 0.0))
	_create_scifi_prop("Blueprint_Chamber_Access", "Props/Prop_AccessPoint.gltf", Vector3(-8.75, 0.08, 12.92), Vector3.ONE * 1.05, Vector3(0.0, -40.0, 0.0))
	_create_decor_box("Blueprint_Holo_Card_Main", Vector3(-10.0, 2.35, 12.75), Vector3(1.15, 1.55, 0.055), magenta)
	_create_decor_box("Blueprint_Holo_Card_Side", Vector3(-11.25, 1.82, 13.05), Vector3(0.82, 1.05, 0.05), gold)
	_create_decor_box("Blueprint_Holo_Backdrop", Vector3(-10.0, 1.15, 14.18), Vector3(3.35, 2.2, 0.12), dark)
	_create_label_3d("ATELIER DE PLANS\ncraft prototype", Vector3(-10.0, 3.35, 12.95), Color(1.0, 0.48, 1.0), 18)


func _create_character_preview(title: String, model_path: String, world_position: Vector3, accent: Color, scale_value: float) -> void:
	var pedestal_mat := _mat(Color(0.10, 0.13, 0.15), accent, 0.35)
	_create_decor_box("Preview_Pedestal_%s" % title.replace("\n", "_"), world_position + Vector3(0, 0.06, 0), Vector3(1.25, 0.12, 1.25), pedestal_mat)
	_create_decor_box("Preview_Ring_%s" % title.replace("\n", "_"), world_position + Vector3(0, 0.18, -0.02), Vector3(1.4, 0.04, 0.12), _mat(accent, accent, 0.9))
	_create_scifi_prop("Preview_Platform_%s" % title.replace("\n", "_"), "Platforms/Platform_Round1.gltf", world_position + Vector3(0, 0.04, 0), Vector3.ONE * 0.72, Vector3.ZERO)

	var holder := Node3D.new()
	holder.name = "Preview_%s" % title.replace("\n", "_")
	holder.position = world_position
	holder.rotation_degrees.y = 180.0
	add_child(holder)

	var model := _create_imported_model(model_path, "Preview_Model", Vector3.ZERO, Vector3.ONE * scale_value, Vector3.ZERO)
	if model != null:
		holder.add_child(model)
		_set_mesh_roughness(model, 1.0)
		_play_idle_animation(model)

	_create_label_3d(title, world_position + Vector3(0, 2.05, 0), accent, 18)


func _create_glb_prop(node_name: String, model_path: String, world_position: Vector3, scale_value: Vector3, rotation_deg: Vector3) -> Node3D:
	var model := _create_imported_model(model_path, node_name, world_position, scale_value, rotation_deg)
	if model == null:
		return null
	add_child(model)
	return model


func _create_scifi_prop(node_name: String, relative_path: String, world_position: Vector3, scale_value: Vector3, rotation_deg: Vector3) -> Node3D:
	var model := _create_glb_prop(node_name, SCIFI_MODEL_PATH + relative_path, world_position, scale_value * SCIFI_VISUAL_SCALE, rotation_deg)
	if model != null:
		_stylize_imported_surfaces(model, Color(1.24, 1.34, 1.34, 1.0), 0.055, 0.68, 0.34)
	return model


func _create_nature_prop(node_name: String, relative_path: String, world_position: Vector3, scale_value: Vector3, rotation_deg: Vector3) -> Node3D:
	var model := _create_glb_prop(node_name, NATURE_MODEL_PATH + relative_path, world_position, scale_value * NATURE_VISUAL_SCALE, rotation_deg)
	if model != null:
		_stylize_imported_surfaces(model, Color(1.08, 1.08, 0.96, 1.0), 0.025, 0.84, 0.0)
	return model


func _create_imported_model(model_path: String, node_name: String, local_position: Vector3, local_scale: Vector3, local_rotation_degrees: Vector3) -> Node3D:
	var packed := load(model_path)
	if packed == null or not (packed is PackedScene):
		push_warning("Modele non instanciable : %s" % model_path)
		return null

	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		push_warning("Modele sans racine Node3D : %s" % model_path)
		instance.queue_free()
		return null

	var node := instance as Node3D
	node.name = node_name
	node.position = local_position
	node.scale = local_scale
	node.rotation_degrees = local_rotation_degrees
	return node


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _play_idle_animation(root: Node) -> void:
	var animation_player := _find_animation_player(root)
	if animation_player == null:
		return
	for animation_name in ["iddleanim_", "anim_iddle", "Idle", "idle"]:
		if animation_player.has_animation(animation_name):
			animation_player.play(animation_name)
			return


func _set_mesh_roughness(root: Node, roughness: float) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface)
				if material is StandardMaterial3D:
					var material_copy := (material as StandardMaterial3D).duplicate() as StandardMaterial3D
					material_copy.roughness = roughness
					mesh_instance.set_surface_override_material(surface, material_copy)

	for child in root.get_children():
		_set_mesh_roughness(child, roughness)


func _stylize_imported_surfaces(root: Node, tint: Color, lift: float, roughness: float, emission_floor: float) -> void:
	if root is MeshInstance3D:
		var mesh_instance := root as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh != null:
			for surface in range(mesh.get_surface_count()):
				var material := mesh.surface_get_material(surface)
				if material is StandardMaterial3D:
					var material_copy := (material as StandardMaterial3D).duplicate() as StandardMaterial3D
					var base := material_copy.albedo_color
					material_copy.albedo_color = Color(
						clampf(base.r * tint.r + lift, 0.0, 1.0),
						clampf(base.g * tint.g + lift, 0.0, 1.0),
						clampf(base.b * tint.b + lift, 0.0, 1.0),
						base.a
					)
					material_copy.roughness = roughness
					if material_copy.emission_enabled and emission_floor > 0.0:
						material_copy.emission_energy_multiplier = max(material_copy.emission_energy_multiplier, emission_floor)
					mesh_instance.set_surface_override_material(surface, material_copy)

	for child in root.get_children():
		_stylize_imported_surfaces(child, tint, lift, roughness, emission_floor)


func _add_child_mesh(parent: Node, node_name: String, mesh: Mesh, local_position: Vector3, local_scale: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.scale = local_scale
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _mat(color: Color, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0, use_noise: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if use_noise:
		var noise := FastNoiseLite.new()
		noise.frequency = 0.05
		noise.fractal_octaves = 3
		var texture := NoiseTexture2D.new()
		texture.width = 256
		texture.height = 256
		texture.noise = noise
		material.albedo_texture = texture
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


func _holo_mat(color: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var material := _mat(color, emission, emission_energy)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


func _capsule_mesh(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return mesh


func _sphere_mesh(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return mesh
