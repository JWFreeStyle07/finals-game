extends CanvasLayer

# ── Swappable assets (assign in Inspector) ──
@export var board_texture        : Texture2D
@export var music_icon_texture   : Texture2D
@export var sfx_icon_texture     : Texture2D
@export var slider_track_texture : Texture2D
@export var home_texture         : Texture2D
@export var play_texture         : Texture2D
@export var restart_texture      : Texture2D
@export var slider_grabber_texture : Texture2D
@export var dimmer_color         : Color  = Color(0, 0, 0, 0.55)
@export var title_font_size      : int    = 40
@export var main_menu_scene      : String = "res://scenes/MainMenu.tscn"
@export var title_font : Font

signal resumed
signal restarted
signal went_home

const C_PANEL_BG   := Color(0.118, 0.047, 0.016, 0.95)
const C_BORDER     := Color(0.545, 0.353, 0.169)
const C_GOLD       := Color(0.784, 0.518, 0.039)
const C_GOLD_LIGHT := Color(0.910, 0.659, 0.125)
const C_TAN        := Color(0.784, 0.584, 0.424)
const C_CREAM      := Color(0.910, 0.788, 0.604)

var _dimmer         : ColorRect
var _panel_root     : PanelContainer
var _title_label    : Label
var _music_slider   : HSlider
var _sfx_slider     : HSlider
var _home_button    : BaseButton
var _play_button    : BaseButton
var _restart_button : BaseButton


func _ready() -> void:
	# ✅ FIX 1: Make this CanvasLayer always process so buttons work while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


# ── Public API ──────────────────────────────────────────────

func show_menu() -> void:
	show()
	get_tree().paused = true

func hide_menu() -> void:
	hide()
	get_tree().paused = false

func toggle() -> void:
	if visible:
		hide_menu()
	else:
		show_menu()


# ── Builder ─────────────────────────────────────────────────

func _build() -> void:
	# Fullscreen dimmer
	_dimmer = ColorRect.new()
	_dimmer.color = dimmer_color
	_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	# ✅ FIX 1 (continued): Every built node also needs PROCESS_MODE_ALWAYS
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)

	# Centred card
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	_dimmer.add_child(center)

	# ✅ FIX 2: Fixed panel size — set both min AND a comfortable fixed width
	_panel_root = PanelContainer.new()
	_panel_root.custom_minimum_size = Vector2(50, 0)
	_panel_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_panel_style()
	center.add_child(_panel_root)

	# Main VBox inside card
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# ✅ FIX 2 (continued): Give it a size flag so it fills the panel properly
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel_root.add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "PAUSE"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", C_CREAM)
	_title_label.add_theme_font_size_override("font_size", title_font_size)
	_title_label.add_theme_font_override("font", title_font)
	vbox.add_child(_title_label)

	# Music row
	var music_row := _build_slider_row(
		music_icon_texture, "♪",
		func(v): _on_music_changed(v)
	)
	_music_slider = music_row.get_child(1) as HSlider
	vbox.add_child(music_row)

	# SFX row
	var sfx_row := _build_slider_row(
		sfx_icon_texture, "🔊",
		func(v): _on_sfx_changed(v)
	)
	_sfx_slider = sfx_row.get_child(1) as HSlider
	vbox.add_child(sfx_row)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 20)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(btn_row)

	_home_button    = _build_button(home_texture,    "🏠", 48)
	_play_button    = _build_button(play_texture,    "▶",  64)
	_restart_button = _build_button(restart_texture, "↺",  48)

	# ✅ FIX 1 (continued): Each button must process while paused
	_home_button.process_mode    = Node.PROCESS_MODE_ALWAYS
	_play_button.process_mode    = Node.PROCESS_MODE_ALWAYS
	_restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

	_home_button.pressed.connect(_on_home_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)

	btn_row.add_child(_home_button)
	btn_row.add_child(_play_button)
	btn_row.add_child(_restart_button)


func _build_slider_row(icon_tex: Texture2D, fallback: String,
		on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.process_mode = Node.PROCESS_MODE_ALWAYS

	if icon_tex:
		var tr := TextureRect.new()
		tr.texture             = icon_tex
		tr.custom_minimum_size = Vector2(28, 28)
		tr.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(tr)
	else:
		var lbl := Label.new()
		lbl.text = fallback
		lbl.add_theme_font_size_override("font_size", 20)
		row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value             = 0.0
	slider.max_value             = 1.0
	slider.step                  = 0.01
	slider.value                 = 1.0
	slider.custom_minimum_size   = Vector2(0, 1)  # ✅ taller so track PNG has room
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.process_mode          = Node.PROCESS_MODE_ALWAYS

	# ✅ Track texture (the bar background)
	if slider_track_texture:
		# "slider" = the full background track
		var track_style          := StyleBoxTexture.new()
		track_style.texture      = slider_track_texture
		# These margins let the texture stretch only in the middle
		# Adjust the numbers to match your PNG's left/right end-cap pixel widths
		track_style.texture_margin_left  = 6
		track_style.texture_margin_right = 6
		track_style.expand_margin_top    = 100   # push texture vertically centered
		track_style.expand_margin_bottom = 100
		slider.add_theme_stylebox_override("slider",           track_style)

		# "grabber_area" = the filled portion to the LEFT of the thumb
		# Use the same texture so it looks continuous, or use a tinted version
		var fill_style          := StyleBoxTexture.new()
		fill_style.texture      = slider_track_texture
		fill_style.texture_margin_left  = 6
		fill_style.texture_margin_right = 6
		fill_style.expand_margin_top    = 4
		fill_style.expand_margin_bottom = 4
		fill_style.modulate_color = C_GOLD   # tint the filled side gold
		slider.add_theme_stylebox_override("grabber_area",          fill_style)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill_style)
	else:
		# Fallback flat styles if no texture assigned
		var fill := StyleBoxFlat.new()
		fill.bg_color = C_GOLD
		slider.add_theme_stylebox_override("grabber_area", fill)

	# ✅ Grabber thumb texture (the draggable button)
	# Add a new @export at the top of your script:
	#   @export var slider_grabber_texture : Texture2D
	# Then use it here:
	# ✅ Grabber — icon override + suppress default circle
	if slider_grabber_texture:
		slider.add_theme_icon_override("grabber",           slider_grabber_texture)
		slider.add_theme_icon_override("grabber_highlight", slider_grabber_texture)
		slider.add_theme_icon_override("grabber_disabled",  slider_grabber_texture)

		# Suppress the default theme's circle by zeroing its size constants
		slider.add_theme_constant_override("grabber_offset", 0)

		# Make the slider tall enough so your PNG isn't clipped vertically
		# Change 40 to match your grabber PNG's pixel height
		slider.custom_minimum_size = Vector2(140, 40)
	else:
		var grabber_flat := StyleBoxFlat.new()
		grabber_flat.bg_color     = C_GOLD_LIGHT
		grabber_flat.border_color = C_CREAM
		grabber_flat.set_border_width_all(1)
		slider.add_theme_stylebox_override("grabber",           grabber_flat)
		slider.add_theme_stylebox_override("grabber_highlight", grabber_flat)
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	return row


func _build_button(tex: Texture2D, fallback: String, size: int) -> BaseButton:
	if tex:
		var btn := TextureButton.new()
		btn.texture_normal      = tex
		btn.custom_minimum_size = Vector2(size, size)
		btn.ignore_texture_size = true
		btn.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		return btn
	else:
		var btn := Button.new()
		btn.text = fallback
		btn.flat = true
		btn.custom_minimum_size = Vector2(size, size)
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", C_CREAM)
		return btn


func _apply_panel_style() -> void:
	if board_texture:
		var s                   := StyleBoxTexture.new()
		s.texture               = board_texture
		s.texture_margin_left   = 150
		s.texture_margin_right  = 150
		s.texture_margin_top    = 100
		s.texture_margin_bottom = 100
		_panel_root.add_theme_stylebox_override("panel", s)
	else:
		var s                    := StyleBoxFlat.new()
		s.bg_color               = C_PANEL_BG
		s.border_color           = C_BORDER
		s.set_border_width_all(2)
		s.content_margin_left    = 24   # ✅ FIX 2: more breathing room
		s.content_margin_right   = 24
		s.content_margin_top     = 24
		s.content_margin_bottom  = 24
		_panel_root.add_theme_stylebox_override("panel", s)


# ── Handlers ────────────────────────────────────────────────

func _on_play_pressed() -> void:
	hide_menu()
	emit_signal("resumed")

func _on_home_pressed() -> void:
	get_tree().paused = false
	emit_signal("went_home")
	GameData.go_to_scene("res://scenes/menus/MainMenu.tscn")

func _on_restart_pressed() -> void:
	get_tree().paused = false
	emit_signal("restarted")
	get_tree().reload_current_scene()

func _on_music_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))
