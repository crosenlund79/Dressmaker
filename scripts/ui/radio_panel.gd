class_name RadioPanel
extends PopupPanel
## The radio's music selection window: track list, transport and volume controls.

var music: MusicPlayer
var _list: ItemList
var _play: Button
var _now: Label


func _ready() -> void:
	title = "The Parlour Wireless"
	min_size = Vector2i(460, 520)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(UiTheme.header("The Parlour Wireless"))
	var intro := UiTheme.note("Gentle music for the boutique. Choose a piece — it keeps playing while you design.")
	intro.custom_minimum_size.x = 430
	v.add_child(intro)
	_now = Label.new()
	v.add_child(_now)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(430, 170)
	for i in range(music.track_count()):
		_list.add_item(music.track_title(i))
		_list.set_item_tooltip(i, music.tracks[i].description)
	_list.item_activated.connect(func(i): _choose(i))
	_list.item_clicked.connect(func(i, _pos, _btn): _choose(i))
	v.add_child(_list)
	var transport := HBoxContainer.new()
	transport.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(transport)
	var prev := Button.new()
	prev.text = "⏮ Previous"
	prev.pressed.connect(func(): _click(); music.previous_track())
	transport.add_child(prev)
	_play = Button.new()
	_play.custom_minimum_size.x = 110
	_play.pressed.connect(func(): _click(); music.toggle_pause())
	transport.add_child(_play)
	var nxt := Button.new()
	nxt.text = "Next ⏭"
	nxt.pressed.connect(func(): _click(); music.next_track())
	transport.add_child(nxt)
	v.add_child(HSeparator.new())
	for spec in [["Music", "Music"], ["Effects", "SFX"], ["Ambience", "Ambience"]]:
		v.add_child(_volume_row(spec[0], spec[1]))
	music.track_changed.connect(func(_i): _refresh())
	music.state_changed.connect(func(_p): _refresh())
	_refresh()


func _choose(i: int) -> void:
	if i != music.current_index or not music.playing:
		SoundEffects.play("radio", -6.0)
		music.play_track(i)


func _click() -> void:
	SoundEffects.play("click", -8.0)


func _volume_row(label: String, bus: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size.x = 90
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = MusicPlayer.bus_volume(bus)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v):
		MusicPlayer.set_bus_volume(bus, v)
		music.save_settings())
	row.add_child(s)
	var mute := CheckBox.new()
	mute.text = "Mute"
	mute.button_pressed = MusicPlayer.bus_muted(bus)
	mute.toggled.connect(func(m):
		MusicPlayer.set_bus_muted(bus, m)
		music.save_settings())
	row.add_child(mute)
	return row


func _refresh() -> void:
	_play.text = "⏸ Pause" if music.playing else "▶ Play"
	if music.current_index >= 0 and music.current_index < _list.item_count:
		_list.select(music.current_index)
		_now.text = "Now playing: %s" % music.track_title(music.current_index) if music.playing else "Paused: %s" % music.track_title(music.current_index)
	else:
		_now.text = "The radio is quiet."
