extends RefCounted

var _textures := {}


func load_png(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]

	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := image.load_png_from_buffer(bytes)
	if err != OK:
		push_error("Impossible de charger la texture: " + path)
		return PlaceholderTexture2D.new()

	var texture := ImageTexture.create_from_image(image)
	_textures[path] = texture
	return texture


func clear() -> void:
	_textures.clear()
