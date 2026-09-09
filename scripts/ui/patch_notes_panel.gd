extends CanvasLayer

signal closed

const PANEL_SIZE := Vector2(840, 560)
const SECTION_TITLES := {
	"added": "Ajouts",
	"changed": "Modifications",
	"removed": "Retraits"
}

var _updates: Array = []
var _root: Control


func setup(updates: Array) -> void:
	_updates = updates
	layer = 40
	visible = false
	_build_ui()


func open_panel() -> void:
	visible = true


func close_panel() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.015, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	var title := Label.new()
	title.text = "Patch Notes"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 34)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(120, 42)
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 16)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	if _updates.is_empty():
		_add_wrapped_label(list, "Aucune mise à jour enregistrée.", 18, Color(1, 1, 1, 0.9))
		return

	for update_value in _updates:
		if typeof(update_value) == TYPE_DICTIONARY:
			_add_update_card(list, update_value as Dictionary)


func _add_update_card(parent: Control, update: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(box)

	var version := String(update.get("version", "?"))
	var title := String(update.get("title", "Mise à jour"))
	_add_wrapped_label(box, "%s - %s" % [version, title], 24, Color(1, 1, 1, 1))
	_add_wrapped_label(box, String(update.get("date", "")), 16, Color(0.78, 0.86, 0.66, 1))
	_add_wrapped_label(box, String(update.get("description", "")), 16, Color(1, 1, 1, 0.92))

	for section_key in ["added", "changed", "removed"]:
		var section_items: Array = _read_list(update.get(section_key, []))
		_add_section(box, String(SECTION_TITLES[section_key]), section_items)


func _add_section(parent: Control, title: String, items: Array) -> void:
	_add_wrapped_label(parent, title, 18, Color(1, 1, 1, 1))

	if items.is_empty():
		_add_wrapped_label(parent, "- Aucun.", 15, Color(1, 1, 1, 0.82))
		return

	for item in items:
		_add_wrapped_label(parent, "- %s" % String(item), 15, Color(1, 1, 1, 0.82))


func _add_wrapped_label(parent: Control, text_value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _read_list(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value as Array
	return []
