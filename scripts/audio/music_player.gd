class_name MusicPlayer
extends Node
## The radio's music engine: plays tracks from the playlist on the "Music" bus,
## crossfades between tracks, loops, and remembers volume settings.

signal track_changed(index: int)
signal state_changed(playing: bool)

const SETTINGS_PATH := "user://settings.cfg"
const FADE_TIME := 1.6

var tracks: Array[MusicTrack] = []
var current_index: int = -1
var playing: bool = false

var _players: Array[AudioStreamPlayer] = []
var _active: int = 0
var _tween: Tween


func _ready() -> void:
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	if Content.playlist:
		tracks = Content.playlist.tracks
	load_settings()


func track_count() -> int:
	return tracks.size()


func track_title(i: int) -> String:
	return tracks[i].title if i >= 0 and i < tracks.size() else ""


func play_track(index: int) -> void:
	if tracks.is_empty():
		return
	index = wrapi(index, 0, tracks.size())
	var stream := tracks[index].stream
	if stream == null:
		return
	_set_loop(stream)
	var old := _players[_active]
	_active = 1 - _active
	var incoming := _players[_active]
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
	if old.playing:
		_tween.tween_property(old, "volume_db", -60.0, FADE_TIME).set_trans(Tween.TRANS_SINE)
		_tween.chain().tween_callback(old.stop)
	current_index = index
	playing = true
	track_changed.emit(index)
	state_changed.emit(true)
	save_settings()


func next_track() -> void:
	play_track(current_index + 1)


func previous_track() -> void:
	play_track(current_index - 1)


func toggle_pause() -> void:
	if current_index < 0:
		play_track(0)
		return
	var p := _players[_active]
	playing = not playing
	p.stream_paused = not playing
	state_changed.emit(playing)


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		if stream.loop_end <= 0:
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
	elif stream is AudioStreamMP3:
		stream.loop = true


# ------------------------------------------------------------------ volume (shared settings)
static func bus_volume(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 1.0


static func set_bus_volume(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


static func bus_muted(bus: String) -> bool:
	var idx := AudioServer.get_bus_index(bus)
	return AudioServer.is_bus_mute(idx) if idx >= 0 else false


static func set_bus_muted(bus: String, muted: bool) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for bus in ["Music", "SFX", "Ambience"]:
		cfg.set_value("audio", bus + "_volume", bus_volume(bus))
		cfg.set_value("audio", bus + "_muted", bus_muted(bus))
	cfg.set_value("audio", "track", current_index)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		set_bus_volume("Music", 0.7)
		set_bus_volume("SFX", 0.8)
		set_bus_volume("Ambience", 0.5)
		return
	for bus in ["Music", "SFX", "Ambience"]:
		set_bus_volume(bus, cfg.get_value("audio", bus + "_volume", 0.7))
		set_bus_muted(bus, cfg.get_value("audio", bus + "_muted", false))
	current_index = int(cfg.get_value("audio", "track", -1))
