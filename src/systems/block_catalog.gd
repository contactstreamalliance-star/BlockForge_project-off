extends RefCounted

var blocks := {}
var block_materials := {}
var solid_block_ids := {}
var transparent_block_ids := {}
var liquid_block_ids := {}
var placeable_block_ids := {}
var single_material_block_ids := {}
var placeable_blocks := []
var creative_inventory_ids := []
var hotbar := []


func load_from_file(path: String, material_factory) -> bool:
	clear()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Impossible de lire " + path)
		return false

	var data: Dictionary = parsed
	hotbar = data.get("hotbar", [])
	for block_value in data.get("blocks", []):
		if typeof(block_value) != TYPE_DICTIONARY:
			continue
		var block: Dictionary = block_value
		var id := String(block.get("id", ""))
		if id == "":
			continue

		if bool(block.get("solid", false)):
			solid_block_ids[id] = true
		if bool(block.get("transparent", false)):
			transparent_block_ids[id] = true
		if bool(block.get("liquid", false)):
			liquid_block_ids[id] = true

		if bool(block.get("placeable", true)):
			block["materials"] = material_factory.create_block_materials(block)
			block_materials[id] = block["materials"]
			var texture_paths: Dictionary = block.get("textures", {})
			block["singleMaterial"] = texture_paths.has("all")
			if bool(block["singleMaterial"]):
				single_material_block_ids[id] = true
			placeable_block_ids[id] = true
			placeable_blocks.append(id)

		blocks[id] = block
		if bool(block.get("creativeInventory", bool(block.get("placeable", true)))):
			creative_inventory_ids.append(id)

	return true


func clear() -> void:
	blocks.clear()
	block_materials.clear()
	solid_block_ids.clear()
	transparent_block_ids.clear()
	liquid_block_ids.clear()
	placeable_block_ids.clear()
	single_material_block_ids.clear()
	placeable_blocks.clear()
	creative_inventory_ids.clear()
	hotbar.clear()
