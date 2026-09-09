extends CharacterBody3D

signal interaction_requested
signal combat_log(message: String)
signal health_changed(current: float, maximum: float)

@export var character_id: String = "robert"
@export var move_speed: float = 6.2
@export var sprint_speed: float = 9.4
@export var jump_velocity: float = 4.8
@export var mouse_sensitivity: float = 0.003
@export var max_health: float = 140.0
@export var max_stamina: float = 100.0
@export var normal_damage: float = 22.0
@export var charge_damage: float = 42.0
@export var parry_damage: float = 18.0

var respawn_position := Vector3(0, 1.0, 14)
var locked_target: Node3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var stamina: float = max_stamina

var _health: float = max_health
var _pitch: float = -0.2
var _attack_cooldown: float = 0.0
var _attack_anim_timer: float = 0.0
var _charge_cooldown: float = 0.0
var _charge_timer: float = 0.0
var _charge_hit_done := false
var _guard_timer: float = 0.0
var _perfect_parry_timer: float = 0.0
var _hurt_timer: float = 0.0
var _downed := false
var _visual_root_base_position := Vector3.ZERO
var _animation_player: AnimationPlayer
var _active_animation := ""

@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot")
@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var left_arm: Node3D = get_node_or_null("VisualRoot/LeftArm")
@onready var right_arm: Node3D = get_node_or_null("VisualRoot/RightArm")
@onready var left_leg: Node3D = get_node_or_null("VisualRoot/LeftLeg")
@onready var right_leg: Node3D = get_node_or_null("VisualRoot/RightLeg")
@onready var weapon_root: Node3D = get_node_or_null("VisualRoot/WeaponRoot")


func _ready() -> void:
	_health = max_health
	stamina = max_stamina
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if visual_root != null:
		_visual_root_base_position = visual_root.position
		_animation_player = _find_animation_player(visual_root)
		_play_existing_animation(["iddleanim_", "anim_iddle", "Idle", "idle"])
	health_changed.emit(_health, max_health)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if camera_pivot == null:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-55), deg_to_rad(25))
		camera_pivot.rotation.x = _pitch

	if event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_normal_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_start_guard()
			else:
				_guard_timer = min(_guard_timer, 0.18)
				_perfect_parry_timer = 0.0

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_TAB:
			_toggle_lock_target()
		elif event.keycode == KEY_F:
			_charge_break_line()
		elif event.keycode == KEY_E:
			interaction_requested.emit()


func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if _downed:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if _is_jump_pressed() and is_on_floor() and _charge_timer <= 0.0:
		velocity.y = jump_velocity

	var input_vector := _movement_input()
	var direction := global_transform.basis * input_vector
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()

	var is_moving := direction.length() > 0.01
	var wants_sprint := _is_sprint_pressed() and is_moving and stamina > 4.0 and _guard_timer <= 0.0
	var speed := sprint_speed if wants_sprint else move_speed

	if wants_sprint:
		stamina = max(stamina - 24.0 * delta, 0.0)
	else:
		stamina = min(stamina + 18.0 * delta, max_stamina)

	if _charge_timer > 0.0:
		var forward := -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		velocity.x = forward.x * 15.0
		velocity.z = forward.z * 15.0
		if not _charge_hit_done:
			_charge_hit_done = true
			if _deal_damage_to_best_target(charge_damage, 4.1, true):
				combat_log.emit("Le joueur utilise l'action speciale de prototype.")
	else:
		velocity.x = move_toward(velocity.x, direction.x * speed, speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, speed * 7.0 * delta)

	if _guard_timer > 0.0:
		velocity.x *= 0.55
		velocity.z *= 0.55

	move_and_slide()
	_clean_locked_target()
	_animate_visual(delta, is_moving, wants_sprint)


func _tick_timers(delta: float) -> void:
	_attack_cooldown = max(_attack_cooldown - delta, 0.0)
	_attack_anim_timer = max(_attack_anim_timer - delta, 0.0)
	_charge_cooldown = max(_charge_cooldown - delta, 0.0)
	_charge_timer = max(_charge_timer - delta, 0.0)
	_guard_timer = max(_guard_timer - delta, 0.0)
	_perfect_parry_timer = max(_perfect_parry_timer - delta, 0.0)
	_hurt_timer = max(_hurt_timer - delta, 0.0)


func _movement_input() -> Vector3:
	var x := 0.0
	var z := 0.0

	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		z += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0

	return Vector3(x, 0.0, z).normalized()


func _is_sprint_pressed() -> bool:
	return Input.is_key_pressed(KEY_SHIFT)


func _is_jump_pressed() -> bool:
	return Input.is_key_pressed(KEY_SPACE)


func _normal_attack() -> void:
	if _attack_cooldown > 0.0 or _downed:
		return
	_attack_cooldown = 0.52
	_attack_anim_timer = 0.26

	if _deal_damage_to_best_target(normal_damage, 3.2, true):
		combat_log.emit("Combo fusil-lame : impact confirme.")
	else:
		combat_log.emit("Le joueur frappe dans le vide.")


func _start_guard() -> void:
	if _downed:
		return
	_guard_timer = 0.82
	_perfect_parry_timer = 0.23
	combat_log.emit("Parade renforcee active : timing parfait au debut du blocage.")


func _charge_break_line() -> void:
	if _charge_cooldown > 0.0 or stamina < 28.0 or _downed:
		return
	stamina -= 28.0
	_charge_cooldown = 4.5
	_charge_timer = 0.26
	_charge_hit_done = false
	_attack_anim_timer = 0.32
	combat_log.emit("Charge brise-ligne lancee.")


func _toggle_lock_target() -> void:
	if locked_target != null and is_instance_valid(locked_target):
		locked_target = null
		combat_log.emit("Ciblage libere.")
		return

	locked_target = _find_best_target(18.0, false)
	if locked_target != null:
		combat_log.emit("Cible verrouillee : %s" % _target_name(locked_target))
	else:
		combat_log.emit("Aucune cible assez proche.")


func _deal_damage_to_best_target(damage: float, max_range: float, require_angle: bool) -> bool:
	var target := _valid_locked_target(max_range)
	if target == null:
		target = _find_best_target(max_range, require_angle)

	if target == null:
		return false

	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		return true
	return false


func _find_best_target(max_range: float, require_angle: bool) -> Node3D:
	var best: Node3D
	var best_score := INF
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.01:
		forward = forward.normalized()

	for candidate in get_tree().get_nodes_in_group("targetable"):
		if not is_instance_valid(candidate):
			continue
		if not (candidate is Node3D):
			continue
		if candidate.has_method("is_alive") and not candidate.is_alive():
			continue

		var target_node := candidate as Node3D
		var to_target := target_node.global_position - global_position
		to_target.y = 0.0
		var distance := to_target.length()
		if distance > max_range or distance < 0.05:
			continue

		if require_angle and forward.length() > 0.01:
			var angle_score := forward.dot(to_target.normalized())
			if angle_score < 0.18:
				continue

		var score := distance
		if locked_target != null and target_node == locked_target:
			score -= 3.0
		if score < best_score:
			best_score = score
			best = target_node

	return best


func _valid_locked_target(max_range: float) -> Node3D:
	if locked_target == null or not is_instance_valid(locked_target):
		return null
	if locked_target.has_method("is_alive") and not locked_target.is_alive():
		return null
	if global_position.distance_to(locked_target.global_position) > max_range:
		return null
	return locked_target


func _clean_locked_target() -> void:
	if locked_target == null:
		return
	if not is_instance_valid(locked_target):
		locked_target = null
		return
	if locked_target.has_method("is_alive") and not locked_target.is_alive():
		locked_target = null


func apply_damage(amount: float, attacker: Node = null) -> void:
	if _downed:
		return

	if _perfect_parry_timer > 0.0 and attacker != null:
		_perfect_parry_timer = 0.0
		_guard_timer = 0.18
		if attacker.has_method("take_damage"):
			attacker.take_damage(parry_damage, self)
		combat_log.emit("Parade parfaite : le joueur renvoie le choc.")
		return

	var incoming := amount
	if _guard_timer > 0.0:
		incoming *= 0.35
		combat_log.emit("Parade tenue : degats reduits.")

	_health = max(_health - incoming, 0.0)
	_hurt_timer = 0.25
	health_changed.emit(_health, max_health)

	if _health <= 0.0:
		_down_and_respawn()


func heal(amount: float) -> void:
	_health = min(_health + amount, max_health)
	health_changed.emit(_health, max_health)


func _down_and_respawn() -> void:
	if _downed:
		return
	_downed = true
	_play_existing_animation(["dyinganim_", "anim_dying", "Dying", "death"])
	combat_log.emit("Le joueur tombe. Retour au camp BlockForge.")
	await get_tree().create_timer(1.15).timeout
	global_position = respawn_position
	velocity = Vector3.ZERO
	_health = max_health * 0.72
	stamina = max_stamina
	_downed = false
	health_changed.emit(_health, max_health)
	combat_log.emit("Le joueur se releve.")


func _animate_visual(_delta: float, moving: bool, sprinting: bool) -> void:
	if visual_root == null:
		return

	var seconds := float(Time.get_ticks_msec()) / 1000.0
	var stride_speed := 9.0 if sprinting else 6.2
	var stride_power := 0.62 if sprinting else 0.36
	if not moving:
		stride_power = 0.08

	var bob := sin(seconds * stride_speed) * 0.035 * (2.0 if sprinting else 1.0)
	visual_root.position = _visual_root_base_position + Vector3(0.0, bob, 0.0)

	if _animation_player != null:
		if _downed:
			_play_existing_animation(["dyinganim_", "anim_dying", "Dying", "death"])
		elif _attack_anim_timer > 0.0:
			_play_existing_animation(["pushanim_", "anim_push", "Attack", "attack"])
		elif _charge_timer > 0.0 or sprinting:
			_play_existing_animation(["runanim_", "anim_run", "Run", "run"])
		elif moving:
			_play_existing_animation(["walkanim_", "anim_walk", "Walk", "walk"])
		elif _guard_timer > 0.0:
			_play_existing_animation(["crouchiddleanim_", "anim_crouchiddle", "Guard", "guard"])
		else:
			_play_existing_animation(["iddleanim_", "anim_iddle", "Idle", "idle"])

	if left_arm != null:
		left_arm.rotation.x = sin(seconds * stride_speed) * stride_power
	if right_arm != null:
		right_arm.rotation.x = -sin(seconds * stride_speed) * stride_power
	if left_leg != null:
		left_leg.rotation.x = -sin(seconds * stride_speed) * stride_power
	if right_leg != null:
		right_leg.rotation.x = sin(seconds * stride_speed) * stride_power

	if _guard_timer > 0.0:
		if left_arm != null:
			left_arm.rotation.x = -0.85
			left_arm.rotation.z = 0.28
		if right_arm != null:
			right_arm.rotation.x = -0.62
			right_arm.rotation.z = -0.18
	elif left_arm != null and right_arm != null:
		left_arm.rotation.z = 0.0
		right_arm.rotation.z = 0.0

	if weapon_root != null:
		if _attack_anim_timer > 0.0:
			var swing := sin((1.0 - _attack_anim_timer / 0.32) * PI)
			weapon_root.rotation.x = -0.55 - swing * 0.85
			weapon_root.rotation.z = 0.18 + swing * 0.42
		else:
			weapon_root.rotation.x = -0.35
			weapon_root.rotation.z = 0.18

	if _hurt_timer > 0.0:
		visual_root.scale = Vector3.ONE * (1.0 + sin(seconds * 55.0) * 0.025)
	else:
		visual_root.scale = Vector3.ONE


func get_status_snapshot() -> Dictionary:
	return {
		"health": _health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"locked_target": _target_name(locked_target),
		"charge_cooldown": _charge_cooldown,
		"guard_active": _guard_timer > 0.0,
		"downed": _downed
	}


func _target_name(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return "aucune"
	if node.has_method("get_display_name"):
		return node.get_display_name()
	return node.name


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer

	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found

	return null


func _play_existing_animation(candidates: Array[String]) -> void:
	if _animation_player == null:
		return

	for animation_name in candidates:
		if _animation_player.has_animation(animation_name):
			if _active_animation != animation_name:
				_animation_player.play(animation_name, 0.14)
				_active_animation = animation_name
			return
