extends RefCounted

const RECIPES_PATH := "res://assets/recipes.json"

var recipes: Array = []


func load_recipes() -> void:
	recipes.clear()
	var data = JSON.parse_string(FileAccess.get_file_as_string(RECIPES_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Impossible de lire assets/recipes.json")
		return
	recipes = data.get("recipes", [])


func get_recipes() -> Array:
	return recipes


func can_craft(recipe: Dictionary, inventory) -> bool:
	return inventory.can_pay(recipe.get("input", {}))


func craft(recipe: Dictionary, inventory) -> bool:
	var input: Dictionary = recipe.get("input", {})
	var output: Dictionary = recipe.get("output", {})
	if not inventory.pay(input):
		return false
	for id in output.keys():
		inventory.add_item(String(id), int(output[id]))
	return true

