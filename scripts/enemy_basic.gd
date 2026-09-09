extends CharacterBody3D

signal died(enemy: Node)
signal damaged(enemy: Node, amount: float, health: float)

@export var enemy_name: String = "Creature contaminee"
@export var enemy_kind: String = "organic"
@export var max_health: float = 70.0
@export var move_speed: float = 2.8
@export var attack_damage: float = 11.0
@export var detection_radius: float = 13.0
@export var attack_range: float = 1.75
@export var attack_interval: float = 1.25
@export var model_scale: float = 1.0

const SCIFI_MODEL_PATH := "res://assets/models/scifi/glTF/"
const NATURE_MODEL_PATH := "res://assets/models/nature/glTF/"

var health: float

var _target: Node3D
var _spawn_position := Vector3.ZERO
var _patrol_destination := Vector3.ZERO
var _attack_cooldown := 0.0
var _hit_flash_timer := 0.0
var _stun_timer := 0.0
var _attack_anim_timer := 0.0
var _base_materials: Array[StandardMaterial3D] = []
var _visual_root: Node3D
var _name_label: Label3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	health = max_health
	_spawn_position = global_position
	_patrol_destination = _spawn_position
	add_to_group("targetable")
	_create_collision()
	_create_model()
	_pick_new_patrol_destination()


func set_target(target: Node3D) -> void:
	_target = target


func _physics_process(delta: float) -> void:
	if health <= 0.0:
		return

	_attack_cooldown = max(_attack_cooldown - delta, 0.0)
	_hit_flash_timer = max(_hit_flash_timer - delta, 0.0)
	_stun_timer = max(_stun_timer - delta, 0.0)
	_attack_anim_timer = max(_attack_anim_timer - delta, 0.0)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var desired := Vector3.ZERO
	if _target != null and is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		to_target.y = 0.0
		var distance := to_target.length()

		if distance <= detection_radius:
			if distance <= attack_range:
				_attack_target()
			elif _stun_timer <= 0.0 and distance > 0.05:
				desired = to_target.normalized() * move_speed
				_face_direction(to_target)
		else:
			desired = _patrol(delta)
	else:
		desired = _patrol(delta)

	if _stun_timer > 0.0:
		desired = Vector3.ZERO

	velocity.x = move_toward(velocity.x, desired.x, move_speed * 5.0 * delta)
	velocity.z = move_toward(velocity.z, desired.z, move_speed * 5.0 * delta)
	move_and_slide()

	_animate(delta)
	_update_label()


func take_damage(amount: float, attacker: Node = null) -> void:
	if health <= 0.0:
		return

	health = max(health - amount, 0.0)
	_hit_flash_timer = 0.16
	_stun_timer = max(_stun_timer, 0.08)
	damaged.emit(self, amount, health)

	if attacker != null and attacker is Node3D:
		_target = attacker as Node3D

	if health <= 0.0:
		_die()


func is_alive() -> bool:
	return health > 0.0


func get_display_name() -> String:
	return enemy_name


func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return health / max_health


func _attack_target() -> void:
	if _attack_cooldown > 0.0:
		return

	_attack_cooldown = attack_interval
	_attack_anim_timer = 0.34
	if _target != null and is_instance_valid(_target) and _target.has_method("apply_damage"):
		_target.apply_damage(attack_damage, self)


func _patrol(_delta: float) -> Vector3:
	var to_destination := _patrol_destination - global_position
	to_destination.y = 0.0
	if to_destination.length() < 0.45:
		_pick_new_patrol_destination()
		return Vector3.ZERO

	_face_direction(to_destination)
	return to_destination.normalized() * (move_speed * 0.42)


func _pick_new_patrol_destination() -> void:
	var angle := randf_range(0.0, TAU)
	var radius := randf_range(2.0, 5.0)
	_patrol_destination = _spawn_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _face_direction(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length() <= 0.05:
		return
	var look_position := global_position + direction.normalized()
	look_at(Vector3(look_position.x, global_position.y, look_position.z), Vector3.UP)


func _die() -> void:
	remove_from_group("targetable")
	died.emit(self)
	queue_free()


func _create_collision() -> void:
	var collision := CollisionShape3D.new()

	if enemy_kind == "machine":
		var box := BoxShape3D.new()
		box.size = Vector3(1.3, 1.15, 1.5) * model_scale
		collision.shape = box
		collision.position.y = 0.58 * model_scale
	else:
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.42 * model_scale
		capsule.height = 1.55 * model_scale
		collision.shape = capsule
		collision.position.y = 0.78 * model_scale

	add_child(collision)


func _create_model() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "VisualRoot"
	add_child(_visual_root)

	if enemy_kind == "machine":
		_create_machine_model()
	elif enemy_kind == "boss":
		_create_boss_model()
	else:
		_create_organic_model()

	_name_label = Label3D.new()
	_name_label.name = "NameLabel"
	_name_label.position = Vector3(0.0, 2.05 * model_scale, 0.0)
	_name_label.font_size = 16
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.modulate = Color(1.0, 0.92, 0.78)
	_visual_root.add_child(_name_label)
	_update_label()


func _create_organic_model() -> void:
	var hide_mat := _mat(Color(0.18, 0.21, 0.15), Color(0.06, 0.24, 0.08), 0.2)
	var wound_mat := _mat(Color(0.55, 0.95, 0.26), Color(0.34, 1.0, 0.18), 1.2)
	var bark_mat := _mat(Color(0.08, 0.11, 0.08), Color(0.02, 0.06, 0.02), 0.0)
	var alien_models := [
		SCIFI_MODEL_PATH + "Aliens/Alien_Cyclop.gltf",
		SCIFI_MODEL_PATH + "Aliens/Alien_Oculichrysalis.gltf",
		SCIFI_MODEL_PATH + "Aliens/Alien_Scolitex.gltf"
	]
	var model_path: String = alien_models[abs(hash(enemy_name)) % alien_models.size()]
	var imported := _add_imported_model("Imported_Bioform", model_path, Vector3(0, 0.06, 0), Vector3.ONE * model_scale * 1.25, Vector3(0.0, 180.0, 0.0))
	if imported != null:
		_add_mesh("ContaminationCore", _sphere_mesh(0.20), Vector3(0.0, 1.0, -0.45), Vector3.ONE * model_scale, wound_mat)
		for index in range(4):
			var side := -1.0 if index % 2 == 0 else 1.0
			var root := _add_mesh("OrganicRoot%d" % index, _cylinder_mesh(0.045, 0.85), Vector3(side * 0.38, 0.32, -0.22 + index * 0.14), Vector3.ONE * model_scale, bark_mat)
			root.rotation_degrees.x = 74.0
			root.rotation_degrees.z = side * 22.0
		return

	_add_mesh("Body", _capsule_mesh(0.42, 1.24), Vector3(0, 0.86, 0), Vector3(1.0, 0.78, 1.28) * model_scale, hide_mat)
	_add_mesh("CoreGlow", _sphere_mesh(0.22), Vector3(0.0, 0.95, -0.43), Vector3.ONE * model_scale, wound_mat)
	_add_mesh("Head", _sphere_mesh(0.35), Vector3(0.0, 1.48, -0.05), Vector3(0.82, 0.68, 0.92) * model_scale, hide_mat)

	for index in range(4):
		var side := -1.0 if index % 2 == 0 else 1.0
		var front := -0.34 if index < 2 else 0.35
		var leg := _add_mesh("RootLeg%d" % index, _cylinder_mesh(0.08, 0.95), Vector3(side * 0.34, 0.38, front), Vector3.ONE * model_scale, bark_mat)
		leg.rotation_degrees.x = 18.0 if index < 2 else -18.0
		leg.rotation_degrees.z = side * 18.0

	for index in range(5):
		var thorn := _add_mesh("BackThorn%d" % index, _cone_mesh(0.09, 0.45), Vector3(0.0, 1.05 + index * 0.11, 0.34), Vector3.ONE * model_scale, bark_mat)
		thorn.rotation_degrees.x = 68.0


func _create_machine_model() -> void:
	var metal_mat := _mat(Color(0.34, 0.39, 0.38), Color(0.02, 0.04, 0.04), 0.0)
	var hazard_mat := _mat(Color(0.92, 0.57, 0.10), Color(0.8, 0.28, 0.02), 0.55)
	var alarm_mat := _mat(Color(1.0, 0.08, 0.05), Color(1.0, 0.02, 0.0), 1.4)
	var imported := _add_imported_model("Imported_HarvesterHull", SCIFI_MODEL_PATH + "Props/Prop_Crate4.gltf", Vector3(0.0, 0.34, 0.0), Vector3.ONE * model_scale * 1.45, Vector3(0.0, 180.0, 0.0))
	if imported != null:
		_add_imported_model("Imported_HarvesterComputer", SCIFI_MODEL_PATH + "Props/Prop_Computer.gltf", Vector3(0.0, 0.72, -0.66), Vector3.ONE * model_scale * 0.9, Vector3.ZERO)
		_add_imported_model("Imported_HarvesterLight", SCIFI_MODEL_PATH + "Props/Prop_Light_Small.gltf", Vector3(0.0, 1.1, -0.72), Vector3.ONE * model_scale * 0.95, Vector3.ZERO)
		_add_mesh("AlarmEye", _sphere_mesh(0.13), Vector3(0.0, 1.32, -0.62), Vector3.ONE * model_scale, alarm_mat)
		_add_mesh("FrontBlade", _box_mesh(Vector3(1.75, 0.14, 0.32)), Vector3(0.0, 0.38, -0.88), Vector3.ONE * model_scale, hazard_mat)
		for side in [-1.0, 1.0]:
			for z in [-0.48, 0.46]:
				var wheel := _add_mesh("Wheel", _cylinder_mesh(0.22, 0.18), Vector3(side * 0.78, 0.28, z), Vector3.ONE * model_scale, metal_mat)
				wheel.rotation_degrees.z = 90.0
		return

	_add_mesh("HarvesterBody", _box_mesh(Vector3(1.35, 0.74, 1.52)), Vector3(0, 0.72, 0), Vector3.ONE * model_scale, metal_mat)
	_add_mesh("Cabin", _box_mesh(Vector3(0.82, 0.55, 0.66)), Vector3(0.0, 1.25, -0.22), Vector3.ONE * model_scale, metal_mat)
	_add_mesh("AlarmEye", _sphere_mesh(0.13), Vector3(0.0, 1.32, -0.62), Vector3.ONE * model_scale, alarm_mat)
	_add_mesh("FrontBlade", _box_mesh(Vector3(1.75, 0.14, 0.32)), Vector3(0.0, 0.38, -0.88), Vector3.ONE * model_scale, hazard_mat)

	for side in [-1.0, 1.0]:
		for z in [-0.48, 0.46]:
			var wheel := _add_mesh("Wheel", _cylinder_mesh(0.22, 0.18), Vector3(side * 0.78, 0.28, z), Vector3.ONE * model_scale, metal_mat)
			wheel.rotation_degrees.z = 90.0


func _create_boss_model() -> void:
	var hide_mat := _mat(Color(0.15, 0.18, 0.13), Color(0.02, 0.10, 0.03), 0.15)
	var glow_mat := _mat(Color(0.72, 1.0, 0.20), Color(0.45, 1.0, 0.14), 1.65)
	var root_mat := _mat(Color(0.07, 0.09, 0.06), Color(0.01, 0.03, 0.01), 0.0)
	var imported := _add_imported_model("Imported_Root_Guardian", SCIFI_MODEL_PATH + "Aliens/Alien_Scolitex.gltf", Vector3(0.0, 0.14, 0.0), Vector3.ONE * model_scale * 2.2, Vector3(0.0, 180.0, 0.0))
	if imported != null:
		_add_imported_model("Guardian_Crown_Left", NATURE_MODEL_PATH + "DeadTree_4.gltf", Vector3(-0.95, 0.02, 0.35), Vector3.ONE * model_scale * 1.25, Vector3(0.0, -35.0, 0.0))
		_add_imported_model("Guardian_Crown_Right", NATURE_MODEL_PATH + "TwistedTree_3.gltf", Vector3(0.95, 0.02, 0.35), Vector3.ONE * model_scale * 1.25, Vector3(0.0, 40.0, 0.0))
		_add_mesh("Heart", _sphere_mesh(0.36), Vector3(0, 1.20, -0.86), Vector3.ONE * model_scale, glow_mat)
		for index in range(8):
			var angle := float(index) / 8.0 * TAU
			var x := cos(angle) * 0.72
			var z := sin(angle) * 0.72
			var root := _add_mesh("RootCrown%d" % index, _cylinder_mesh(0.07, 1.2), Vector3(x, 0.72, z), Vector3.ONE * model_scale, root_mat)
			root.rotation_degrees.x = 72.0
			root.rotation_degrees.z = rad_to_deg(angle) + 20.0
		return

	_add_mesh("DominantBody", _capsule_mesh(0.85, 2.0), Vector3(0, 1.12, 0), Vector3(1.55, 0.92, 1.85) * model_scale, hide_mat)
	_add_mesh("Heart", _sphere_mesh(0.36), Vector3(0, 1.20, -0.86), Vector3.ONE * model_scale, glow_mat)
	_add_mesh("Skull", _sphere_mesh(0.52), Vector3(0, 2.02, -0.24), Vector3(1.1, 0.76, 1.0) * model_scale, hide_mat)

	for index in range(8):
		var angle := float(index) / 8.0 * TAU
		var x := cos(angle) * 0.72
		var z := sin(angle) * 0.72
		var root := _add_mesh("RootCrown%d" % index, _cylinder_mesh(0.07, 1.2), Vector3(x, 0.72, z), Vector3.ONE * model_scale, root_mat)
		root.rotation_degrees.x = 72.0
		root.rotation_degrees.z = rad_to_deg(angle) + 20.0

	for side in [-1.0, 1.0]:
		var horn := _add_mesh("Horn", _cone_mesh(0.18, 0.9), Vector3(side * 0.32, 2.45, -0.25), Vector3.ONE * model_scale, root_mat)
		horn.rotation_degrees.z = side * -28.0


func _animate(_delta: float) -> void:
	if _visual_root == null:
		return

	var seconds := float(Time.get_ticks_msec()) / 1000.0
	var breathe := 1.0 + sin(seconds * (3.2 if enemy_kind != "machine" else 5.0)) * 0.025
	_visual_root.scale = Vector3.ONE * breathe

	if _attack_anim_timer > 0.0:
		_visual_root.rotation.x = sin((1.0 - _attack_anim_timer / 0.34) * PI) * 0.18
	else:
		_visual_root.rotation.x = 0.0

	if _hit_flash_timer > 0.0:
		for mesh_node in _visual_root.get_children():
			if mesh_node is MeshInstance3D:
				var flash_mat := _mat(Color(1.0, 0.95, 0.78), Color(1.0, 0.38, 0.12), 0.9)
				mesh_node.material_override = flash_mat
	else:
		var material_index := 0
		for mesh_node in _visual_root.get_children():
			if mesh_node is MeshInstance3D and material_index < _base_materials.size():
				mesh_node.material_override = _base_materials[material_index]
				material_index += 1


func _update_label() -> void:
	if _name_label == null:
		return
	var hp_percent := int(round(get_health_ratio() * 100.0))
	_name_label.text = "%s\nPV %d%%" % [enemy_name, hp_percent]


func _add_mesh(node_name: String, mesh: Mesh, local_position: Vector3, local_scale: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = local_position
	mesh_instance.scale = local_scale
	mesh_instance.material_override = material
	_visual_root.add_child(mesh_instance)
	_base_materials.append(material)
	return mesh_instance


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
	_set_imported_roughness(node, 0.92)
	return node


func _set_imported_roughness(root: Node, roughness: float) -> void:
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
		_set_imported_roughness(child, roughness)


func _mat(color: Color, emission: Color = Color(0, 0, 0, 1), emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
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


func _cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	return mesh


func _cone_mesh(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	return mesh
