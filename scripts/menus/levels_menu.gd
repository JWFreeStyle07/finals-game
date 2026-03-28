extends Control

# ─────────────────────────────────────────────
#  levels_menu.gd  —  Attached to LevelsMenu.tscn
#
#  Scene tree structure (LevelsMenu.tscn):
#  └─ LevelsMenu  (Control, full-rect, this script)
#      ├─ Background      (TextureRect, full-rect)
#      ├─ Title           (Label, centered top)
#      ├─ GridContainer   (name: "Grid", centered)
#      └─ BackButton      (Button, bottom-left)
# ─────────────────────────────────────────────

const TOTAL_LEVELS  := 5
const CELL_SIZE     := 120
const CELL_RADIUS   := 14
const CELL_FONT_SIZE:= 36
const CELL_GAP      := 20

const COLOR_UNLOCKED := Color(0.10, 0.10, 0.16, 0.88)
const COLOR_HOVER    := Color(0.22, 0.22, 0.34, 0.95)
const COLOR_PRESSED  := Color(0.05, 0.05, 0.10, 1.00)
const COLOR_BORDER   := Color(1.0, 1.0, 1.0, 0.22)
const COLOR_CURRENT  := Color(0.20, 0.50, 0.90, 0.90)  # Highlight current level

func _ready() -> void:
	_setup_background()
	_build_ui()
	_animate_entrance()

func _setup_background() -> void:
	var bg := TextureRect.new()
	bg.texture      = load("res://Assets/images/menu_bg.png")
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

func _build_ui() -> void:
	# ── Title ──────────────────────────────────
	var title := Label.new()
	title.text                              = "SELECT LEVEL"
	title.horizontal_alignment              = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left                       = 0.0
	title.anchor_right                      = 1.0
	title.anchor_top                        = 0.0
	title.offset_top                        = 50
	title.offset_bottom                     = 110
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# ── Grid (centered) ────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var grid := GridContainer.new()
	grid.columns = TOTAL_LEVELS  # All 5 in one row; adjust if needed
	grid.add_theme_constant_override("h_separation", CELL_GAP)
	grid.add_theme_constant_override("v_separation", CELL_GAP)
	center.add_child(grid)

	for i in range(TOTAL_LEVELS):
		_make_level_cell(i + 1, grid)

	# ── Back button ────────────────────────────
	var back := Button.new()
	back.text                    = "← BACK"
	back.custom_minimum_size     = Vector2(140, 50)
	back.anchor_left             = 0.0
	back.anchor_top              = 1.0
	back.anchor_right            = 0.0
	back.anchor_bottom           = 1.0
	back.offset_left             = 30
	back.offset_top              = -80
	back.offset_right            = 170
	back.offset_bottom           = -30
	_style_back_button(back)
	back.pressed.connect(_on_back)
	add_child(back)

func _make_level_cell(level_num: int, parent: Node) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	btn.text                = str(level_num)

	var is_current := (level_num == GameData.current_level)
	var base_color  := COLOR_CURRENT if is_current else COLOR_UNLOCKED

	btn.add_theme_stylebox_override("normal",  _make_cell_style(base_color))
	btn.add_theme_stylebox_override("hover",   _make_cell_style(COLOR_HOVER))
	btn.add_theme_stylebox_override("pressed", _make_cell_style(COLOR_PRESSED))
	btn.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
	btn.add_theme_color_override("font_color", Color.WHITE)

	btn.mouse_entered.connect(_on_cell_hover.bind(btn))
	btn.mouse_exited.connect(_on_cell_unhover.bind(btn))
	btn.pressed.connect(_on_level_selected.bind(level_num))

	parent.add_child(btn)

func _make_cell_style(bg_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color                   = bg_color
	s.corner_radius_top_left     = CELL_RADIUS
	s.corner_radius_top_right    = CELL_RADIUS
	s.corner_radius_bottom_left  = CELL_RADIUS
	s.corner_radius_bottom_right = CELL_RADIUS
	s.border_width_left          = 1
	s.border_width_right         = 1
	s.border_width_top           = 1
	s.border_width_bottom        = 1
	s.border_color               = COLOR_BORDER
	return s

func _style_back_button(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.08, 0.08, 0.12, 0.82)
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.border_width_left   = 1; s.border_width_right  = 1
	s.border_width_top    = 1; s.border_width_bottom = 1
	s.border_color = COLOR_BORDER
	var sh := s.duplicate(); sh.bg_color = Color(0.18, 0.18, 0.26, 0.92)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  sh)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 16)

func _on_cell_hover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.12)

func _on_cell_unhover(btn: Button) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)

func _on_level_selected(level_num: int) -> void:
	GameData.current_level = level_num
	GameData.save_data()
	_fade_then(func(): GameData.go_to_scene("res://scenes/cutscene/PlayCutscene.tscn"))

func _on_back() -> void:
	_fade_then(func(): GameData.go_to_scene("res://scenes/menus/MainMenu.tscn"))

func _animate_entrance() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _fade_then(callback: Callable) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(callback)
