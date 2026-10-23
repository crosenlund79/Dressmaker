extends Node
## Entry point: wires the boutique, the model, the editor, the UI and audio together.

const REFLECTION_INTERVAL := 0.12

@onready var boutique: Boutique = $World/Boutique
@onready var character: CharacterPresentation = $World/Character
@onready var camera: CameraController = $World/Camera
@onready var editor: FashionEditor = $Editor
@onready var ui: EditorUI = $UI
@onready var music: MusicPlayer = $Music
@onready var thumbnails: ThumbnailRenderer = $Thumbnails

var handles: TransformHandles
var _reflection_dirty := true
var _reflection_timer := 0.0
var _last_template_sig := ""


func _ready() -> void:
	boutique.street.camera = camera
	character.set_design(editor.design)
	character.set_selected_slot(editor.selected_slot)
	handles = TransformHandles.new()
	handles.name = "Handles"
	handles.editor = editor
	handles.presentation = character
	character.rig.add_child(handles)
	boutique.mirror.reflection.set_design(editor.design)

	ui.editor = editor
	ui.camera = camera
	ui.presentation = character
	ui.handles = handles
	ui.music = music
	ui.thumbnailer = thumbnails
	ui.setup()

	editor.design_changed.connect(_on_design_changed)
	editor.design_replaced.connect(_on_design_changed)
	boutique.radio_clicked.connect(ui.open_radio)
	music.state_changed.connect(func(p): boutique.radio.playing = p)
	_last_template_sig = _template_signature()

	var wants_shot := false
	for a in OS.get_cmdline_user_args():
		wants_shot = wants_shot or a.begins_with("--shot")
	if wants_shot and ResourceLoader.exists("res://tools/dev/screenshot_driver.gd"):
		var driver: Node = load("res://tools/dev/screenshot_driver.gd").new()
		driver.set("main", self)
		add_child(driver)
	await get_tree().process_frame
	ui.frame_model(1.45)
	if music.track_count() > 0:
		music.play_track(maxi(music.current_index, 0))


func _on_design_changed() -> void:
	character.refresh()
	_reflection_dirty = true
	var sig := _template_signature()
	if sig != _last_template_sig:
		_last_template_sig = sig
		SoundEffects.play("rustle", -8.0)


func _process(delta: float) -> void:
	_reflection_timer -= delta
	if _reflection_dirty and _reflection_timer <= 0.0:
		_reflection_dirty = false
		_reflection_timer = REFLECTION_INTERVAL
		boutique.mirror.reflection.refresh()


func _template_signature() -> String:
	var d := editor.design
	var parts: Array[String] = [d.body_id, d.shoe_id, d.hair_id]
	for slot in DressDesign.GARMENT_SLOTS:
		parts.append(d.garment(slot).template_id)
		parts.append(d.garment(slot).material.fabric_id)
	return "|".join(parts)
