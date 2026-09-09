extends Area3D

signal used(station_id: String, station_title: String)

@export var station_id: String = "station"
@export var station_title: String = "Station"
@export var prompt: String = "E : utiliser"
@export var accent_color: Color = Color(0.35, 0.95, 1.0)

var _screen: MeshInstance3D


func _ready() -> void:
	add_to_group("interactable")
	monitoring = true
	monitorable = true
	_create_collision()
	_create_visual()


func interact(_player: Node = null) -> void:
	used.emit(station_id, station_title)


func get_interaction_prompt() -> String:
	return prompt


func get_display_name() -> String:
	return station_title


func _process(_delta: float) -> void:
	if _screen == null:
		return
	var seconds := float(Time.get_ticks_msec()) / 1000.0
	_screen.scale.y = 1.0 + sin(seconds * 3.1) * 0.035


func _create_collision() -> void:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.65, 2.0, 1.65)
	collision.shape = box
	collision.position.y = 1.0
	add_child(collision)


func _create_visual() -> void:
	var base_material := _mat(Color(0.10, 0.13, 0.14), Color(0.02, 0.06, 0.06), 0.0)
	var light_material := _mat(accent_color, accent_color, 1.1)

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.2, 1.2, 0.75)
	base.mesh = base_mesh
	base.position.y = 0.6
	base.material_override = base_material
	add_child(base)

	_screen = MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.95, 0.55, 0.08)
	_screen.mesh = screen_mesh
	_screen.position = Vector3(0, 1.25, -0.42)
	_screen.material_override = light_material
	add_child(_screen)

	var antenna := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.025
	antenna_mesh.bottom_radius = 0.035
	antenna_mesh.height = 1.0
	antenna_mesh.radial_segments = 8
	antenna.mesh = antenna_mesh
	antenna.position = Vector3(0.42, 1.65, 0.0)
	antenna.material_override = light_material
	add_child(antenna)

	var label := Label3D.new()
	label.text = station_title
	label.position = Vector3(0, 1.95, 0)
	label.font_size = 16
	label.modulate = accent_color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _mat(color: Color, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material
