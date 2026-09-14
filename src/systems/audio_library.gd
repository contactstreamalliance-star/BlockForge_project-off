extends Node

var _players := {}


func setup(names: Array, base_path: String = "res://assets/audio") -> void:
	for name in names:
		var id := String(name)
		var player := AudioStreamPlayer.new()
		player.name = "Audio_" + id
		player.stream = _load_wav("%s/%s.wav" % [base_path, id])
		if id == "music" and player.stream:
			player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			player.volume_db = -8
		else:
			player.volume_db = -8
		add_child(player)
		_players[id] = player


func play_sfx(id: String) -> void:
	var player: AudioStreamPlayer = _players.get(id)
	if player:
		player.stop()
		player.play()


func play_music() -> void:
	var music: AudioStreamPlayer = _players.get("music")
	if music and not music.playing:
		music.play()


func _load_wav(path: String) -> AudioStreamWAV:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44:
		push_error("Fichier WAV invalide: " + path)
		return null

	var fmt_offset := _find_chunk(bytes, "fmt ")
	var data_offset := _find_chunk(bytes, "data")
	if fmt_offset < 0 or data_offset < 0:
		push_error("Chunks WAV manquants: " + path)
		return null

	var channels := _read_u16(bytes, fmt_offset + 10)
	var sample_rate := _read_u32(bytes, fmt_offset + 12)
	var bits_per_sample := _read_u16(bytes, fmt_offset + 22)
	var data_size := _read_u32(bytes, data_offset + 4)
	var data_start := data_offset + 8
	var data_end: int = mini(data_start + data_size, bytes.size())

	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.stereo = channels == 2
	stream.format = AudioStreamWAV.FORMAT_8_BITS if bits_per_sample == 8 else AudioStreamWAV.FORMAT_16_BITS
	stream.data = bytes.slice(data_start, data_end)
	return stream


func _find_chunk(bytes: PackedByteArray, chunk_id: String) -> int:
	var target := chunk_id.to_ascii_buffer()
	var offset := 12
	while offset + 8 <= bytes.size():
		if bytes[offset] == target[0] and bytes[offset + 1] == target[1] and bytes[offset + 2] == target[2] and bytes[offset + 3] == target[3]:
			return offset
		var size := _read_u32(bytes, offset + 4)
		offset += 8 + size + int(size % 2)
	return -1


func _read_u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)


func _read_u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)
