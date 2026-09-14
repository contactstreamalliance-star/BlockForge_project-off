extends RefCounted

const VoxelMathScript := preload("res://src/world/voxel_math.gd")


static func terrain_height(x: int, z: int, settings: Dictionary, seed: int, height_cache: Dictionary, biome_cache: Dictionary) -> int:
	var cache_key := Vector2i(x, z)
	if height_cache.has(cache_key):
		return int(height_cache[cache_key])

	var water_level := int(settings.get("waterLevel", 8))
	var max_height := int(settings.get("maxHeight", 24))
	var min_height := int(settings.get("minHeight", -16))
	var plateau_radius := int(settings.get("spawnPlateauRadius", 13))
	var plateau_height := int(settings.get("spawnPlateauHeight", water_level + 4))
	if String(settings.get("terrainMode", "")) == "showcase_flat":
		return plateau_height

	var dist: int = maxi(abs(x), abs(z))
	var hill_strength := float(settings.get("hillStrength", 7.0))
	var mountain_strength := float(settings.get("mountainStrength", 16.0))
	var detail_strength := float(settings.get("detailStrength", 3.0))
	var biome := biome_at(x, z, settings, seed, biome_cache)

	var broad: float = VoxelMathScript.value_noise(x * 0.018, z * 0.018, seed)
	var continent: float = VoxelMathScript.value_noise(x * 0.009 + 20.0, z * 0.009 - 80.0, seed + 7)
	var hills: float = VoxelMathScript.value_noise(x * 0.058 + 90.0, z * 0.058 - 27.0, seed + 11)
	var detail: float = VoxelMathScript.value_noise(x * 0.17 - 18.0, z * 0.17 + 44.0, seed + 23) - 0.5
	var ridge: float = absf(VoxelMathScript.value_noise(x * 0.032 - 200.0, z * 0.032 + 140.0, seed + 41) - 0.5) * 2.0

	var mountains: float = pow(maxf(0.0, broad - 0.52), 1.42) * mountain_strength
	if biome == "mountain":
		mountains += pow(maxf(0.0, ridge - 0.34), 1.18) * mountain_strength * 0.82
	elif biome == "rocky":
		mountains += pow(maxf(0.0, ridge - 0.42), 1.35) * mountain_strength * 0.38

	var natural: float = float(water_level + 5)
	natural += (continent - 0.44) * 11.0
	natural += (hills - 0.46) * hill_strength * biome_hill_multiplier(biome)
	natural += detail * detail_strength
	natural += mountains + biome_height_offset(biome)

	if dist <= plateau_radius:
		height_cache[cache_key] = plateau_height
		return plateau_height

	var blend_distance: float = float(settings.get("plateauBlendDistance", 10.0))
	var blend: float = clampf(float(dist - plateau_radius) / maxf(1.0, blend_distance), 0.0, 1.0)
	var result: int = clampi(roundi(lerpf(float(plateau_height), natural, blend)), min_height + 6, max_height)
	height_cache[cache_key] = result
	return result


static func biome_at(x: int, z: int, settings: Dictionary, seed: int, biome_cache: Dictionary) -> String:
	var cache_key := Vector2i(x, z)
	if biome_cache.has(cache_key):
		return String(biome_cache[cache_key])

	var scale := float(settings.get("biomeScale", 0.018))
	var heat: float = VoxelMathScript.value_noise(x * scale + 120.0, z * scale - 80.0, seed + 101)
	var moisture: float = VoxelMathScript.value_noise(x * scale - 240.0, z * scale + 160.0, seed + 203)
	var ridge: float = VoxelMathScript.value_noise(x * scale * 1.5, z * scale * 1.5, seed + 307)
	var water_level := int(settings.get("waterLevel", 8))
	var quick_height: float = float(water_level + 5) + (VoxelMathScript.value_noise(x * 0.009 + 20.0, z * 0.009 - 80.0, seed + 7) - 0.44) * 11.0

	var biome: String = "meadow"
	if quick_height <= float(water_level + 1):
		biome = "coast"
	elif ridge > 0.76:
		biome = "mountain"
	elif moisture > 0.62 and heat > 0.28:
		biome = "forest"
	elif moisture < 0.33 and heat > 0.55:
		biome = "dry"
	elif ridge > 0.58:
		biome = "rocky"
	biome_cache[cache_key] = biome
	return biome


static func natural_block_id(x: int, y: int, z: int, height: int, water_level: int, min_y: int, seed: int, biome: String, ore_chance: float) -> String:
	if y == height:
		if height <= water_level + 1:
			return "wet_sand" if VoxelMathScript.hash2(x, z, seed + 41) > 0.28 else "clay"
		if biome == "dry":
			return "sand" if VoxelMathScript.hash2(x, z, seed + 141) > 0.35 else "rocky_dirt"
		if biome == "mountain" and height > water_level + 22:
			return "stone" if VoxelMathScript.hash2(x, z, seed + 151) > 0.22 else "deep_stone"
		if biome == "rocky" and VoxelMathScript.hash2(x, z, seed + 161) > 0.42:
			return "stone"
		return "grass"

	if y > height - 4:
		if height <= water_level + 2:
			return "wet_sand" if VoxelMathScript.hash3(x, y, z, seed + 82) > 0.22 else "clay"
		if biome == "dry":
			return "sand" if y > height - 3 else "rocky_dirt"
		if biome == "mountain" and height > water_level + 22:
			return "stone"
		if biome == "rocky":
			return "stone" if y > height - 2 else "rocky_dirt"
		return "dirt"

	var ore := ore_block_id(x, y, z, min_y, ore_chance, seed)
	if ore != "":
		return ore
	if y < min_y + 12:
		return "deep_stone" if VoxelMathScript.hash3(x, y, z, seed + 17) < 0.72 else "granite"
	if VoxelMathScript.hash3(x, y, z, seed + 229) < 0.026:
		return "gravel"
	if VoxelMathScript.hash3(x, y, z, seed + 99) < 0.018:
		return "marble"
	return "stone"


static func ore_block_id(x: int, y: int, z: int, min_y: int, chance: float, seed: int) -> String:
	var roll := VoxelMathScript.hash3(x, y, z, seed + 301)
	if y < min_y + 14 and roll < chance * 0.20:
		return "rare_ore"
	if y < 8 and roll < chance * 0.48:
		return "iron_ore"
	if y < 34 and roll < chance * 0.82:
		return "coal_ore"
	if y >= min_y + 8 and y < 42 and roll < chance * 1.06:
		return "copper_ore"
	return ""


static func is_cave_air(x: int, y: int, z: int, surface_y: int, min_y: int, cave_chance: float, spawn_radius: int, tunnel_threshold: float, pocket_threshold: float, surface_buffer: int, floor_buffer: int, tunnel_scale: float, branch_scale: float, room_scale: float, small_room_threshold: float, medium_room_threshold: float, large_room_threshold: float, biome: String, seed: int) -> bool:
	if abs(x) <= spawn_radius + 4 and abs(z) <= spawn_radius + 4:
		return false
	if y <= min_y + floor_buffer or y >= surface_y - surface_buffer:
		return false

	var depth := float(surface_y - y)
	var usable_depth := maxf(1.0, float(surface_y - min_y - surface_buffer - floor_buffer))
	var depth_factor := clampf((depth - float(surface_buffer)) / usable_depth, 0.0, 1.0)
	var biome_opening := cave_biome_opening(biome)
	var chance_shift := cave_chance * 0.12 + biome_opening
	var deep_bonus := depth_factor * 0.16
	var y_float := float(y)

	var main_tunnel: float = VoxelMathScript.value_noise(
		x * tunnel_scale + y_float * 0.014 + 7.0,
		z * tunnel_scale - y_float * 0.012 - 11.0,
		seed + 401
	)
	var main_limit := tunnel_threshold - chance_shift - deep_bonus * 0.55
	if main_tunnel > main_limit:
		var vertical_gate: float = VoxelMathScript.value_noise(
			x * 0.024 + z * 0.011,
			y_float * 0.052 - z * 0.008,
			seed + 467
		)
		var tunnel_band: float = VoxelMathScript.value_noise(
			x * 0.030 - z * 0.012,
			y_float * 0.115 + z * 0.008,
			seed + 487
		)
		var lower_band := 0.34 + (1.0 - depth_factor) * 0.16
		return vertical_gate > 0.34 + (1.0 - depth_factor) * 0.18 and tunnel_band > lower_band and tunnel_band < 0.82

	if main_tunnel < main_limit - 0.16:
		return false

	var branch: float = VoxelMathScript.value_noise(
		x * branch_scale - y_float * 0.015,
		z * branch_scale + y_float * 0.019,
		seed + 619
	)
	if branch > tunnel_threshold + 0.035 - chance_shift and main_tunnel > 0.50:
		return true

	if depth_factor < 0.30:
		return false

	var room_seed: float = VoxelMathScript.value_noise(x * 0.018, z * 0.018, seed + 733)
	if room_seed < 0.42:
		return false

	var small_room: float = VoxelMathScript.value_noise(
		(x + y) * (room_scale * 1.36),
		(z - y) * (room_scale * 1.36),
		seed + 511
	)
	var small_vertical: float = VoxelMathScript.value_noise(
		x * 0.026 + z * 0.006,
		y_float * 0.18 - z * 0.008,
		seed + 547
	)
	var small_limit := small_room_threshold - depth_factor * 0.10 - cave_chance * 0.05 - biome_opening
	if small_room > small_limit and small_vertical > 0.38 and small_vertical < 0.78:
		return true

	if depth_factor < 0.46 or room_seed < 0.70:
		return false

	var medium_room: float = VoxelMathScript.value_noise(
		(x - y) * room_scale,
		(z + y) * room_scale,
		seed + 811
	)
	var medium_vertical: float = VoxelMathScript.value_noise(
		x * 0.018 - z * 0.014,
		y_float * 0.135 + z * 0.006,
		seed + 863
	)
	var medium_limit := maxf(pocket_threshold + 0.035, medium_room_threshold) - depth_factor * 0.09 - biome_opening * 0.65
	if medium_room > medium_limit and main_tunnel > 0.49 and medium_vertical > 0.44 and medium_vertical < 0.70:
		return true

	if depth_factor < 0.76 or room_seed < 0.92:
		return false

	var large_room: float = VoxelMathScript.value_noise(
		(x + y) * (room_scale * 0.58),
		(z - y) * (room_scale * 0.58),
		seed + 1021
	)
	var large_gate: float = VoxelMathScript.value_noise(
		x * 0.011 - z * 0.007,
		y_float * 0.019 + z * 0.010,
		seed + 1193
	)
	var large_vertical: float = VoxelMathScript.value_noise(
		x * 0.014 + z * 0.009,
		y_float * 0.105 - z * 0.004,
		seed + 1237
	)
	var large_limit := maxf(pocket_threshold + 0.13, large_room_threshold) - depth_factor * 0.035 - biome_opening * 0.25
	return large_room > large_limit and large_gate > 0.82 and large_vertical > 0.48 and large_vertical < 0.64 and main_tunnel > 0.56


static func tree_chance_for_biome(biome: String, base_chance: float) -> float:
	if biome == "forest":
		return base_chance * 2.8
	if biome == "meadow":
		return base_chance
	if biome == "coast":
		return base_chance * 0.28
	if biome == "dry":
		return base_chance * 0.18
	if biome == "rocky":
		return base_chance * 0.35
	if biome == "mountain":
		return base_chance * 0.12
	return base_chance


static func cave_biome_opening(biome: String) -> float:
	if biome == "mountain":
		return 0.035
	if biome == "rocky":
		return 0.026
	if biome == "dry":
		return 0.014
	if biome == "coast":
		return -0.018
	if biome == "forest":
		return -0.006
	return 0.0


static func biome_height_offset(biome: String) -> float:
	if biome == "mountain":
		return 7.0
	if biome == "rocky":
		return 2.5
	if biome == "dry":
		return -1.5
	if biome == "forest":
		return 1.0
	if biome == "coast":
		return -3.0
	return 0.0


static func biome_hill_multiplier(biome: String) -> float:
	if biome == "mountain":
		return 1.45
	if biome == "rocky":
		return 1.25
	if biome == "coast":
		return 0.45
	if biome == "dry":
		return 0.72
	return 1.0
