extends RefCounted

var _texture_loader


func setup(texture_loader) -> void:
	_texture_loader = texture_loader


func create_block_materials(block: Dictionary) -> Array:
	var texture_paths: Dictionary = block.get("textures", {})
	if texture_paths.has("all"):
		var transparent := bool(block.get("transparent", false)) or bool(block.get("liquid", false))
		var alpha: float = 0.6 if bool(block.get("liquid", false)) else 0.72 if bool(block.get("transparent", false)) else 1.0
		var mat := _make_material(String(texture_paths.get("all", "")), Color(0.92, 0.92, 0.92, alpha), transparent)
		return [mat, mat, mat, mat, mat, mat]
	var side_path: String = String(texture_paths.get("side", texture_paths.get("all", "")))
	var top_path: String = String(texture_paths.get("top", texture_paths.get("all", side_path)))
	var bottom_path: String = String(texture_paths.get("bottom", texture_paths.get("all", side_path)))
	var transparent := bool(block.get("transparent", false)) or bool(block.get("liquid", false))
	var alpha: float = 0.6 if bool(block.get("liquid", false)) else 0.72 if bool(block.get("transparent", false)) else 1.0
	return [
		_make_material(side_path, Color(0.93, 0.93, 0.93, alpha), transparent),
		_make_material(side_path, Color(0.86, 0.86, 0.86, alpha), transparent),
		_make_material(top_path, Color(1.0, 1.0, 1.0, alpha), transparent),
		_make_material(bottom_path, Color(0.78, 0.78, 0.78, alpha), transparent),
		_make_material(side_path, Color(0.96, 0.96, 0.96, alpha), transparent),
		_make_material(side_path, Color(0.82, 0.82, 0.82, alpha), transparent)
	]


func _make_material(path: String, tint: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture_loader.load_png(path)
	mat.albedo_color = tint
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat.alpha_scissor_threshold = 0.05
	return mat
