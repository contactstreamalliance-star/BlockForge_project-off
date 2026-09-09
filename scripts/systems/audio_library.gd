extends Node

var _players := {}


func setup(names: Array, base_path: String = "res://assets/audio") -> void:
	for name in names:
		var id := String(name)
		var player := AudioStreamPlayer.new()
		player.name = "Audio_" + id
		player.stream = load("%s/%s.wav" % [base_path, id])
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
