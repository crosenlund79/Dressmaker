class_name SoundEffects
extends Node
## Small pool of one-shot sound effects on the "SFX" bus (UI clicks, fabric rustles).

const SOUNDS := {
	"click": "res://assets/audio/sfx/click.ogg",
	"rustle": "res://assets/audio/sfx/rustle.ogg",
	"radio": "res://assets/audio/sfx/radio_switch.ogg",
	"snip": "res://assets/audio/sfx/snip.ogg",
}

static var instance: SoundEffects

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played: Dictionary = {}


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	for key in SOUNDS:
		if ResourceLoader.exists(SOUNDS[key]):
			_streams[key] = load(SOUNDS[key])
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool.append(p)


static func play(sound: String, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	if instance:
		instance._play(sound, volume_db, pitch_jitter)


func _play(sound: String, volume_db: float, pitch_jitter: float) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -1000)) < 60:
		return  # avoid machine-gunning during drags
	_last_played[sound] = now
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
