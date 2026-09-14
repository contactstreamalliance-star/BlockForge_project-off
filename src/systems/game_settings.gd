extends RefCounted

const SETTINGS_PATH := "user://blockforge_settings.json"
const LOCAL_SETTINGS_PATH := "res://blockforge_settings.local.json"
const DEFAULT_RAM_BUDGET_MB := 1024
const MIN_RAM_BUDGET_MB := 512
const MAX_RAM_BUDGET_MB := 6144

var ram_budget_mb := DEFAULT_RAM_BUDGET_MB


func load() -> void:
	ram_budget_mb = DEFAULT_RAM_BUDGET_MB
	var settings_path := SETTINGS_PATH if FileAccess.file_exists(SETTINGS_PATH) else LOCAL_SETTINGS_PATH
	if not FileAccess.file_exists(settings_path):
		return

	var settings_text := FileAccess.get_file_as_string(settings_path)
	if settings_text.strip_edges() == "":
		return

	var settings_data: Variant = JSON.parse_string(settings_text)
	if typeof(settings_data) != TYPE_DICTIONARY:
		return

	var settings: Dictionary = settings_data
	ram_budget_mb = normalize_ram_budget(int(settings.get("ramBudgetMb", DEFAULT_RAM_BUDGET_MB)))


func save() -> void:
	var settings := {
		"ramBudgetMb": normalize_ram_budget(ram_budget_mb)
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		file = FileAccess.open(LOCAL_SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()


func normalize_ram_budget(value: int) -> int:
	return clampi(value, MIN_RAM_BUDGET_MB, MAX_RAM_BUDGET_MB)


func ram_options() -> Array:
	return [
		{"label": "512 Mo", "value": 512},
		{"label": "1 Go", "value": 1024},
		{"label": "2 Go", "value": 2048},
		{"label": "4 Go", "value": 4096},
		{"label": "6 Go", "value": 6144}
	]


func format_ram_budget() -> String:
	if ram_budget_mb >= 1024:
		var gb := float(ram_budget_mb) / 1024.0
		if is_equal_approx(gb, roundf(gb)):
			return "%d Go" % int(roundf(gb))
		return "%.1f Go" % gb
	return "%d Mo" % ram_budget_mb
