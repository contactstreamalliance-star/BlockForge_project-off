extends RefCounted

const FACE_RIGHT := 0
const FACE_LEFT := 1
const FACE_UP := 2
const FACE_DOWN := 3
const FACE_FORWARD := 4
const FACE_BACK := 5


static func chunk_key_for_block(pos: Vector3i, chunk_size: int) -> String:
	var cx := floori(float(pos.x) / float(chunk_size))
	var cz := floori(float(pos.z) / float(chunk_size))
	return "%d,%d" % [cx, cz]


static func face_dir(face: int) -> Vector3i:
	if face == FACE_RIGHT:
		return Vector3i.RIGHT
	if face == FACE_LEFT:
		return Vector3i.LEFT
	if face == FACE_UP:
		return Vector3i.UP
	if face == FACE_DOWN:
		return Vector3i.DOWN
	if face == FACE_FORWARD:
		return Vector3i.FORWARD
	return Vector3i.BACK


static func face_vertices(face: int) -> Array:
	if face == FACE_RIGHT:
		return [Vector3(0.5, -0.5, 0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)]
	if face == FACE_LEFT:
		return [Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(-0.5, 0.5, -0.5)]
	if face == FACE_UP:
		return [Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5), Vector3(-0.5, 0.5, -0.5)]
	if face == FACE_DOWN:
		return [Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, -0.5, 0.5), Vector3(-0.5, -0.5, 0.5)]
	if face == FACE_FORWARD:
		return [Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(0.5, 0.5, -0.5)]
	return [Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5), Vector3(-0.5, 0.5, 0.5)]


static func value_noise(x: float, z: float, seed: int) -> float:
	var x0 := floori(x)
	var z0 := floori(z)
	var xf := smooth_curve(x - x0)
	var zf := smooth_curve(z - z0)
	var a := hash2(x0, z0, seed)
	var b := hash2(x0 + 1, z0, seed)
	var c := hash2(x0, z0 + 1, seed)
	var d := hash2(x0 + 1, z0 + 1, seed)
	return lerpf(lerpf(a, b, xf), lerpf(c, d, xf), zf)


static func smooth_curve(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


static func hash2(x: int, z: int, seed: int) -> float:
	var n: int = int(x * 374761393) ^ int(z * 668265263) ^ int(seed * 1274126177)
	n = int((n ^ (n >> 13)) * 1274126177)
	return float(n & 0x7fffffff) / 2147483647.0


static func hash3(x: int, y: int, z: int, seed: int) -> float:
	var n: int = int(x * 1597334677) ^ int(y * 3812015801) ^ int(z * 958689251) ^ seed
	n = int((n ^ (n >> 15)) * 2246822507)
	return float(n & 0x7fffffff) / 2147483647.0


static func signi(value: float) -> int:
	if value < 0:
		return -1
	if value > 0:
		return 1
	return 0
