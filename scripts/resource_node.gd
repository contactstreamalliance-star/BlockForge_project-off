extends Area3D

signal gathered(node: Node, resource_id: String, amount: int)

@export var resource_id: String = "sample_contamine"
@export var title: String = "Echantillon contamine"
@export var amount: int = 1
@export var tint: Color = Color(0.62, 1.0, 0.30)

const NATURE_MODEL_PATH := "res://assets/models/nature/glTF/"

var _gathered := false
var _visual_root: Node3D


func _ready() -> void:
	add_to_group("interactable")
	monitoring = true
	monitorable = true
	_create_collision()
	_create_visual()


func interact(_player: Node = null) -> void:
	if _gathered:
		return
	_gathered = true
	gathered.emit(self, resource_id, amount)
	queue_free()


func get_interaction_prompt() -> String:
	return "E : recolter %s" % title


func get_display_name() -> String:
	return title


func _process(_delta: float) -> void:
	if _visual_root == null:
		return
	var seconds := float(Time.get_ticks_msec()) / 1000.0
	_visual_root.rotation.y = seconds * 0.55
	_visual_root.position.y = sin(seconds * 2.4) * 0.08


func _create_collision() -> void:
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	collision.shape = sphere
	collision.position.y = 0.6
	add_child(collision)


func _create_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)

	var imported_path := NATURE_MODEL_PATH + ("Plant_1_Big.gltf" if resource_id == "biomasse" else "Plant_7_Big.gltf")
	var imported := _add_imported_model("ImportedResource", imported_path, Vector3.ZERO, Vector3.ONE * 0.95, Vector3(0.0, randf_range(0.0, 360.0), 0.0))
	if imported != null:
		var glow := MeshInstance3D.new()
		var glow_mesh := SphereMesh.new()
		glow_mesh.radius = 0.16
		glow_mesh.height = 0.32
		glow_mesh.radial_segments = 12
		glow_mesh.rings = 6
		glow.mesh = glow_mesh
		glow.position.y = 0.78
		glow.material_override = _mat(tint, tint, 1.25)
		_visual_root.add_child(glow)

		var label := Label3D.new()
		label.text = title
		label.position = Vector3(0, 1.14, 0)
		label.font_size = 14
		label.modulate = Color(0.92, 1.0, 0.86)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_visual_root.add_child(label)
		return

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.09
	stem_mesh.height = 0.9
	stem_mesh.radial_segments = 8
	stem.mesh = stem_mesh
	stem.position.y = 0.45
	stem.material_override = _mat(Color(0.08, 0.12, 0.08), Color(0.03, 0.10, 0.02), 0.1)
	_visual_root.add_child(stem)

	for index in range(3):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(0.45, 0.05, 0.16)
		leaf.mesh = leaf_mesh
		leaf.position = Vector3(0, 0.48 + index * 0.12, 0)
		leaf.rotation_degrees.y = index * 120.0
		leaf.rotation_degrees.z = 18.0
		leaf.material_override = _mat(Color(0.18, 0.28, 0.12), tint, 0.16)
		_visual_root.add_child(leaf)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.18
	core_mesh.height = 0.36
	core_mesh.radial_segments = 12
	core_mesh.rings = 6
	core.mesh = core_mesh
	core.position.y = 0.98
	core.material_override = _mat(tint, tint, 1.25)
	_visual_root.add_child(core)

	var label := Label3D.new()
	label.text = title
	label.position = Vector3(0, 1.20, 0)
	label.font_size = 14
	label.modulate = Color(0.92, 1.0, 0.86)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_visual_root.add_child(label)


func _add_imported_model(node_name: String, model_path: String, local_position: Vector3, local_scale: Vector3, local_rotation_degrees: Vector3) -> Node3D:
	var packed := load(model_path)
	if packed == null or not (packed is PackedScene):
		return null
	var instance := (packed as PackedScene).instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		return null
	var node := instance as Node3D
	node.name = node_name
	node.position = local_position
	node.scale = local_scale
	node.rotation_degrees = local_rotation_degrees
	_visual_root.add_child(node)
	return node


func _mat(color: Color, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material
