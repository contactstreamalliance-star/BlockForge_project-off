extends Node

signal closed

const PATCH_NOTES_PATH := "res://assets/patch_notes.json"
const PatchNotesPanelScript := preload("res://src/ui/patch_notes_panel.gd")

var _panel
var _updates: Array = []


func setup() -> void:
	_updates = _load_updates()
	_panel = PatchNotesPanelScript.new()
	_panel.name = "PatchNotesLayer"
	_panel.setup(_updates)
	_panel.closed.connect(_on_panel_closed)
	add_child(_panel)


func open_panel() -> void:
	if _panel == null:
		return
	_panel.open_panel()


func close_panel() -> void:
	if _panel == null:
		return
	_panel.close_panel()


func is_open() -> bool:
	return _panel != null and _panel.visible


func _load_updates() -> Array:
	if not FileAccess.file_exists(PATCH_NOTES_PATH):
		push_warning("Patch notes introuvables : %s" % PATCH_NOTES_PATH)
		return []

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATCH_NOTES_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Patch notes invalides : %s" % PATCH_NOTES_PATH)
		return []

	var patch_data: Dictionary = parsed as Dictionary
	var updates_value: Variant = patch_data.get("updates", [])
	if typeof(updates_value) != TYPE_ARRAY:
		push_warning("Patch notes sans liste updates : %s" % PATCH_NOTES_PATH)
		return []

	return updates_value as Array


func _on_panel_closed() -> void:
	closed.emit()
