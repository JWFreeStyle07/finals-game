extends CanvasLayer

# ── Textures ──
@export var board_texture       : Texture2D
@export var banner_texture      : Texture2D
@export var star_texture        : Texture2D
@export var empty_star_texture  : Texture2D
@export var quit_button_texture : Texture2D
@export var next_button_texture : Texture2D
@export var victory_sound       : AudioStream

# ── Fonts ──
@export var title_font  : Font
@export var banner_font : Font
@export var score_font  : Font
@export var button_font : Font

# ── Font sizes ──
@export var title_font_size  : int = 28
@export var banner_font_size : int = 16
@export var score_font_size  : int = 14
@export var button_font_size : int = 14

# ── Font colors ──
@export var title_color        : Color = Color(0.910, 0.788, 0.604)
@export var banner_color       : Color = Color(1, 1, 1, 1)
@export var score_label_color  : Color = Color(0.910, 0.788, 0.604)
@export var score_value_color  : Color = Color(0.910, 0.788, 0.604)
@export var button_label_color : Color = Color(0.910, 0.788, 0.604)

# ── Panel / board size ──
@export var board_min_width     : int = 380
@export var board_margin_left   : int = 24
@export var board_margin_right  : int = 24
@export var board_margin_top    : int = 24
@export var board_margin_bottom : int = 24

# ── Spacing ──
@export var vbox_separation   : int = 14
@export var button_separation : int = 16

# ── Stars ──
@export var star_size : int = 36

# ── Buttons ──
@export var button_width  : int = 90
@export var button_height : int = 36

# ── Banner margins ──
@export var banner_margin_left   : int = 20
@export var banner_margin_right  : int = 20
@export var banner_margin_top    : int = 10
@export var banner_margin_bottom : int = 10

# ── Misc ──
@export var dimmer_color  : Color = Color(0, 0, 0, 0.55)
@export var menu_scene    : String = "res://scenes/menus/MainMenu.tscn"  # 👈 changed
@export var level1_scene  : String = "res://scenes/levels/Level1.tscn"   # 👈 changed

signal went_to_menu   # 👈 changed
signal went_to_next

const C_PANEL_BG := Color(0.118, 0.047, 0.016, 0.95)
const C_BORDER   := Color(0.545, 0.353, 0.169)
const C_GOLD     := Color(0.784, 0.518, 0.039)
const C_CREAM    := Color(0.910, 0.788, 0.604)
const C_GREEN    := Color(0.180, 0.490, 0.180)

var _dimmer       : ColorRect
var _panel_root   : PanelContainer
var _banner_label : Label
var _star_nodes   : Array = []
var _score_value  : Label
var _audio_player : AudioStreamPlayer

var _final_score : int = 0
var _star_count  : int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("tutorial_win_menu")  # 👈 added

	# ── Audio player created before _build() ──
	_audio_player = AudioStreamPlayer.new()
	_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_player)

	_build()
	hide()


# ── Public API ──────────────────────────────────────────────

func show_win() -> void:  # 👈 no score/stars param, always shows 3 stars
	_star_count = 3
	_refresh()
	show()
	get_tree().paused = true
	if victory_sound != null and _audio_player != null:
		_audio_player.stream = victory_sound
		_audio_player.play()


func hide_win() -> void:
	hide()
	get_tree().paused = false


# ── Internal ────────────────────────────────────────────────

func _refresh() -> void:
	# Banner text — always "Well done!" for tutorial
	_banner_label.text = "You're ready for Level 1!"  # 👈 changed

	# Stars — always all 3 filled for tutorial
	for i in 3:
		var tr := _star_nodes[i] as TextureRect
		tr.texture  = star_texture if star_texture else null
		tr.modulate = Color(1, 1, 1, 1)

	# Score — show dashes since tutorial has no score
	_score_value.text = "—"  # 👈 changed


# ── Builder ─────────────────────────────────────────────────

func _build() -> void:
	# Dimmer
	_dimmer = ColorRect.new()
	_dimmer.color = dimmer_color
	_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	_dimmer.add_child(center)

	# Panel card
	_panel_root = PanelContainer.new()
	_panel_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_panel_style()
	center.add_child(_panel_root)

	# Main VBox
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", vbox_separation)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel_root.add_child(vbox)

	# ── Spacer ──
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	# ── "TUTORIAL COMPLETE" title ──  👈 changed text only
	var title := Label.new()
	title.text = "TUTORIAL COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_font_size_override("font_size", title_font_size)
	if title_font:
		title.add_theme_font_override("font", title_font)
	vbox.add_child(title)

	# ── Banner ──
	var banner_panel := PanelContainer.new()
	banner_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_banner_style(banner_panel)
	vbox.add_child(banner_panel)

	var banner_hbox := HBoxContainer.new()
	banner_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_hbox.add_theme_constant_override("separation", 6)
	banner_panel.add_child(banner_hbox)

	_banner_label = Label.new()
	_banner_label.text = "You're ready for Level 1!"
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_label.add_theme_color_override("font_color", banner_color)
	_banner_label.add_theme_font_size_override("font_size", banner_font_size)
	if banner_font:
		_banner_label.add_theme_font_override("font", banner_font)
	banner_hbox.add_child(_banner_label)

	# Stars inside banner (right side)
	for i in 3:
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(star_size, star_size)
		tr.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		tr.texture             = empty_star_texture
		banner_hbox.add_child(tr)
		_star_nodes.append(tr)

	# ── Score row ──
	var score_row := HBoxContainer.new()
	score_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_theme_constant_override("separation", 365)
	vbox.add_child(score_row)

	var score_label := Label.new()
	score_label.text = "TUTORIAL SCORE"  # 👈 changed
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", score_label_color)
	score_label.add_theme_font_size_override("font_size", score_font_size)
	if score_font:
		score_label.add_theme_font_override("font", score_font)
	score_row.add_child(score_label)

	_score_value = Label.new()
	_score_value.text = "COMPLETE"  # 👈 changed
	_score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_score_value.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_score_value.add_theme_color_override("font_color", score_value_color)
	_score_value.add_theme_font_size_override("font_size", score_font_size)
	_score_value.add_theme_constant_override("separation", 365)
	if score_font:
		_score_value.add_theme_font_override("font", score_font)
	score_row.add_child(_score_value)

	# ── Button row ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", button_separation)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(btn_row)

	var quit_btn := _build_button(quit_button_texture, "MENU")  # 👈 changed label
	var next_btn := _build_button(next_button_texture, "NEXT")

	quit_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	next_btn.process_mode = Node.PROCESS_MODE_ALWAYS

	quit_btn.pressed.connect(_on_menu_pressed)   # 👈 changed
	next_btn.pressed.connect(_on_next_pressed)

	btn_row.add_child(quit_btn)
	btn_row.add_child(next_btn)


func _build_button(tex: Texture2D, fallback: String) -> BaseButton:
	var btn := Button.new()
	btn.text = fallback
	btn.custom_minimum_size = Vector2(button_width, button_height)
	btn.add_theme_font_size_override("font_size", button_font_size)
	btn.add_theme_color_override("font_color", button_label_color)
	if button_font:
		btn.add_theme_font_override("font", button_font)
	if tex:
		var normal_style                   := StyleBoxTexture.new()
		normal_style.texture               = tex
		normal_style.texture_margin_left   = 8
		normal_style.texture_margin_right  = 8
		normal_style.texture_margin_top    = 6
		normal_style.texture_margin_bottom = 6
		normal_style.content_margin_top    = 10
		normal_style.content_margin_bottom = 47
		btn.add_theme_stylebox_override("normal",  normal_style)
		btn.add_theme_stylebox_override("hover",   normal_style)
		btn.add_theme_stylebox_override("pressed", normal_style)
		btn.add_theme_stylebox_override("focus",   normal_style)
	else:
		btn.flat = false
	return btn


func _apply_panel_style() -> void:
	_panel_root.custom_minimum_size = Vector2(board_min_width, 0)
	if board_texture:
		var s                   := StyleBoxTexture.new()
		s.texture               = board_texture
		s.texture_margin_left   = 150
		s.texture_margin_right  = 150
		s.texture_margin_top    = 100
		s.texture_margin_bottom = 100
		s.content_margin_left   = board_margin_left
		s.content_margin_right  = board_margin_right
		s.content_margin_top    = board_margin_top
		s.content_margin_bottom = board_margin_bottom
		_panel_root.add_theme_stylebox_override("panel", s)
	else:
		var s                   := StyleBoxFlat.new()
		s.bg_color              = C_PANEL_BG
		s.border_color          = C_BORDER
		s.set_border_width_all(2)
		s.content_margin_left   = board_margin_left
		s.content_margin_right  = board_margin_right
		s.content_margin_top    = board_margin_top
		s.content_margin_bottom = board_margin_bottom
		_panel_root.add_theme_stylebox_override("panel", s)


func _apply_banner_style(panel: PanelContainer) -> void:
	if banner_texture:
		var s                   := StyleBoxTexture.new()
		s.texture               = banner_texture
		s.texture_margin_left   = banner_margin_left
		s.texture_margin_right  = banner_margin_right
		s.texture_margin_top    = banner_margin_top
		s.texture_margin_bottom = banner_margin_bottom
		panel.add_theme_stylebox_override("panel", s)
	else:
		var s                   := StyleBoxFlat.new()
		s.bg_color              = C_GREEN
		s.content_margin_left   = 10
		s.content_margin_right  = 10
		s.content_margin_top    = 6
		s.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", s)


# ── Handlers ────────────────────────────────────────────────

func _on_menu_pressed() -> void:   # 👈 changed
	get_tree().paused = false
	emit_signal("went_to_menu")
	GameData.go_to_scene(menu_scene)

func _on_next_pressed() -> void:
	get_tree().paused = false
	emit_signal("went_to_next")
	GameData.go_to_scene(level1_scene)
