extends PanelContainer

signal pressed(item_id: String)
signal drop_requested(item_id: String, slot_index: int)
signal destroy_requested(item_id: String, slot_index: int)

var normal_style := StyleBoxFlat.new()
var hover_style := StyleBoxFlat.new()
var icon_rect: TextureRect
var name_label: Label
var count_label: Label
var item_id := ""
var inventory_index := -1


func _init() -> void:
	custom_minimum_size = Vector2(86, 92)
	mouse_filter = Control.MOUSE_FILTER_STOP

	normal_style.bg_color = Color(0.08, 0.10, 0.11, 0.86)
	normal_style.border_color = Color(0.45, 0.52, 0.50, 0.72)
	normal_style.set_border_width_all(1)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", normal_style)

	hover_style.bg_color = Color(0.16, 0.18, 0.18, 0.94)
	hover_style.border_color = Color(0.94, 0.82, 0.34, 0.9)
	hover_style.set_border_width_all(2)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 3)
	margin.add_child(box)

	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(38, 38)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon_rect)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 12)
	box.add_child(name_label)

	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 13)
	box.add_child(count_label)


func setup(display_name: String, amount: int, texture: Texture2D = null, block_id: String = "", show_name: bool = false, slot_index: int = -1) -> void:
	item_id = block_id
	inventory_index = slot_index
	name_label.text = display_name
	name_label.visible = show_name
	count_label.text = "x%d" % amount
	count_label.visible = amount > 0
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	if item_id == "":
		tooltip_text = display_name
	else:
		tooltip_text = "%s\nQuantite: %d\nClic gauche: barre rapide\nClic droit: jeter 1\nMaj + clic droit: detruire la pile" % [display_name, amount]


func _on_mouse_entered() -> void:
	add_theme_stylebox_override("panel", hover_style)


func _on_mouse_exited() -> void:
	add_theme_stylebox_override("panel", normal_style)


func _on_gui_input(event: InputEvent) -> void:
	if item_id == "" or not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(item_id)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if mouse_event.shift_pressed:
			destroy_requested.emit(item_id, inventory_index)
		else:
			drop_requested.emit(item_id, inventory_index)
