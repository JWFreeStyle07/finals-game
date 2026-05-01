extends Control

# ─────────────────────────────────────────────
#  main_menu.gd  —  Attached to MainMenu.tscn
#
#  Scene tree structure (MainMenu.tscn):
#  └─ MainMenu  (Control, full-rect, this script)
#      ├─ Background         (TextureRect, full-rect)
#      ├─ CenterContainer    (anchored center)
#      │   └─ ButtonsVBox   (VBoxContainer)
#      │       ├─ PlayBtn    (Button)
#      │       ├─ LevelsBtn  (Button)
#      │       ├─ SettingsBtn(Button)
#      │       └─ LeaveBtn   (Button)
#      └─ MusicPlayer        (AudioStreamPlayer, name: "MusicPlayer")
# ─────────────────────────────────────────────

var music_player: AudioStreamPlayer
var bg: TextureRect

# Button references — set in _ready via $path
var play_btn:     Button
var levels_btn:   Button
var settings_btn: Button
var leave_btn:    Button

# ── Button visual config ──
const BTN_WIDTH      := 380
const BTN_HEIGHT     := 64
const BTN_FONT_SIZE  := 22
const BTN_RADIUS     := 10

const COLOR_NORMAL   := Color(0.08, 0.08, 0.12, 0.82)
const COLOR_HOVER    := Color(0.18, 0.18, 0.26, 0.92)
const COLOR_PRESSED  := Color(0.05, 0.05, 0.08, 1.00)
const COLOR_BORDER   := Color(1.0, 1.0, 1.0, 0.18)
const COLOR_TEXT     := Color(1.0, 1.0, 1.0, 1.0)
const BORDER_WIDTH   := 1

func _ready() -> void:
	_setup_background()
	_build_ui()
	_start_music()
	_animate_entrance()

# ── Background ────────────────────────────────
func _setup_background() -> void:
	bg = TextureRect.new()
	bg.texture      = load("res://assets/images/menu_bg.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)  # Push behind all other nodes

# ── Build UI programmatically ─────────────────
func _build_ui() -> void:
	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.anchor_left   = 0.0
	center.anchor_right  = 1.0
	center.anchor_top    = 0.0
	center.anchor_bottom = 1.0
	center.offset_left   = 0
	center.offset_right  = 0
	center.offset_top    = 0
	center.offset_bottom = 0
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	play_btn     = _make_button("▶   PLAY",     vbox)
	levels_btn   = _make_button("☰   LEVELS",   vbox)
	settings_btn = _make_button("⚙   SETTINGS", vbox)
	leave_btn    = _make_button("✕   LEAVE",     vbox)

	play_btn.pressed.connect(_on_play)
	levels_btn.pressed.connect(_on_levels)
	settings_btn.pressed.connect(_on_settings)
	leave_btn.pressed.connect(_on_leave)

func _make_button(label_text: String, parent: Node) -> Button:
	var btn := Button.new()
	btn.text              = label_text
	btn.custom_minimum_size = Vector2(BTN_WIDTH, BTN_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# ── Styles ──
	btn.add_theme_stylebox_override("normal",  _make_style(COLOR_NORMAL))
	btn.add_theme_stylebox_override("hover",   _make_style(COLOR_HOVER))
	btn.add_theme_stylebox_override("pressed", _make_style(COLOR_PRESSED))
	btn.add_theme_stylebox_override("focus",   _make_style(COLOR_HOVER))

	btn.add_theme_color_override("font_color",         COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color",   COLOR_TEXT)
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.8, 0.8, 1.0))
	btn.add_theme_font_size_override("font_size", BTN_FONT_SIZE)

	# Hover scale animation
	btn.mouse_entered.connect(_on_btn_hover.bind(btn))
	btn.mouse_exited.connect(_on_btn_unhover.bind(btn))

	parent.add_child(btn)
	return btn

func _make_style(bg_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = bg_color
	s.corner_radius_top_left     = BTN_RADIUS
	s.corner_radius_top_right    = BTN_RADIUS
	s.corner_radius_bottom_left  = BTN_RADIUS
	s.corner_radius_bottom_right = BTN_RADIUS
	s.border_width_left          = BORDER_WIDTH
	s.border_width_right         = BORDER_WIDTH
	s.border_width_top           = BORDER_WIDTH
	s.border_width_bottom        = BORDER_WIDTH
	s.border_color               = COLOR_BORDER
	return s

# ── Hover micro-animations ────────────────────
func _on_btn_hover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.12)

func _on_btn_unhover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)

# ── Entrance animation ────────────────────────
func _animate_entrance() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

# ── Music ─────────────────────────────────────
func _start_music() -> void:
	var music_path := "res://assets/audio/menu_music.ogg"
	if not ResourceLoader.exists(music_path):
		push_warning("Music file not found: " + music_path)
		return

	# Use existing node from scene tree if present, otherwise create one
	if has_node("MusicPlayer"):
		music_player = $MusicPlayer
	else:
		music_player = AudioStreamPlayer.new()
		music_player.name = "MusicPlayer"
		add_child(music_player)

	music_player.stream    = load(music_path)
	music_player.volume_db = 0.0
	music_player.autoplay  = false

	if GameData.music_enabled:
		music_player.play()
		print("Music started: ", music_path)
	else:
		print("Music disabled in GameData")

# ── Button callbacks ──────────────────────────
func _on_play() -> void:
	_fade_then(func(): GameData.go_to_scene("res://scenes/levels/Level1.tscn"))
	#_fade_then(func(): GameData.go_to_scene("res://scenes/cutscene/PlayCutscene.tscn"))

func _on_levels() -> void:
	_fade_then(func(): GameData.go_to_scene("res://scenes/menus/LevelsMenu.tscn"))

func _on_settings() -> void:
	_fade_then(func(): GameData.go_to_scene("res://scenes/menus/SettingsMenu.tscn"))

func _on_leave() -> void:
	_fade_then(func(): get_tree().quit())

func _fade_then(callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(callback)
