class_name AmbiencePlayer
extends Node
## Restrained shop ambience: a looping street bed plus occasional distant one-shots.

const BED := "res://assets/audio/sfx/street_ambience.ogg"
const ONE_SHOTS := ["res://assets/audio/sfx/carriage.ogg", "res://assets/audio/sfx/footsteps.ogg", "res://assets/audio/sfx/shop_bell.ogg"]

var _bed: AudioStreamPlayer
var _shot: AudioStreamPlayer
var _shots: Array[AudioStream] = []
var _timer := 12.0


func _ready() -> void:
	_bed = AudioStreamPlayer.new()
	_bed.bus = &"Ambience"
	_bed.volume_db = -6.0
	add_child(_bed)
	_shot = AudioStreamPlayer.new()
	_shot.bus = &"Ambience"
	add_child(_shot)
	if ResourceLoader.exists(BED):
		var s: AudioStream = load(BED)
		if s is AudioStreamOggVorbis:
			s.loop = true
		_bed.stream = s
		_bed.play()
	for path in ONE_SHOTS:
		if ResourceLoader.exists(path):
			_shots.append(load(path))


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(14.0, 32.0)
		if not _shots.is_empty() and not _shot.playing:
			_shot.stream = _shots.pick_random()
			_shot.volume_db = randf_range(-14.0, -8.0)
			_shot.pitch_scale = randf_range(0.95, 1.05)
			_shot.play()
