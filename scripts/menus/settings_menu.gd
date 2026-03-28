extends Control

# ─────────────────────────────────────────────
#  settings_menu.gd  —  Attached to SettingsMenu.tscn
#
#  Scene tree (SettingsMenu.tscn):
#  └─ SettingsMenu  (Control, full-rect, this script)
#      ├─ Background   (TextureRect)
#      └─ (UI built programmatically below)
# ─────────────────────────────────────────────

const OUTFIT_COUNT  := 3   # Must match GameData.outfits.size()
const PANEL_WIDTH   := 500
const PANEL_PADDING := 30

# Outfit display names shown in the picker
const OUTFIT_NAMES := ["Default", "Cool Blue", "Fiery Red"]

# Outfit preview colors (used if no texture is loaded yet — acts as a swatch)
const OUTFIT_COLORS := [
	Color(0.55, 0.55, 0.65),
	Color(0.25, 0.45, 0.85),
	Color(0.85, 0.28, 0.25),
]

var name_input: LineEdit
var music_toggle: CheckButton
var outfit_buttons: Array = []

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
	# ── Outer centering ────────────────────────
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := _make_panel()
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	# ── Title ──────────────────────────────────
	var title := Label.new()
	title.text               = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	_add_separator(vbox)

	# ── Player Name ────────────────────────────
	_add_section_label("Player Name", vbox)
	name_input = LineEdit.new()
	name_input.text               = GameData.player_name
	name_input.placeholder_text   = "Enter your name..."
	name_input.custom_minimum_size = Vector2(0, 48)
	name_input.add_theme_font_size_override("font_size", 18)
	_style_line_edit(name_input)
	vbox.add_child(name_input)

	_add_separator(vbox)

	# ── Background Music toggle ────────────────
	_add_section_label("Background Music", vbox)
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 16)
	vbox.add_child(music_row)

	var music_label := Label.new()
	music_label.text = "Music On/Off"
	music_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	music_label.add_theme_font_size_override("font_size", 18)
	music_row.add_child(music_label)

	music_toggle = CheckButton.new()
	music_toggle.button_pressed = GameData.music_enabled
	music_toggle.add_theme_font_size_override("font_size", 16)
	music_toggle.toggled.connect(_on_music_toggled)
	music_row.add_child(music_toggle)

	_add_separator(vbox)

	# ── Outfit Picker ──────────────────────────
	_add_section_label("Character Outfit", vbox)
	var outfit_grid := GridContainer.new()
	outfit_grid.columns = OUTFIT_COUNT
	outfit_grid.add_theme_constant_override("h_separation", 14)
	outfit_grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(outfit_grid)

	for i in range(OUTFIT_COUNT):
		_make_outfit_tile(i, outfit_grid)

	_add_separator(vbox)

	# ── Buttons Row ────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var save_btn := _make_action_button("✔  SAVE", Color(0.20, 0.55, 0.25, 0.90))
	save_btn.pressed.connect(_on_save)
	btn_row.add_child(save_btn)

	var back_btn := _make_action_button("← BACK", Color(0.08, 0.08, 0.14, 0.88))
	back_btn.pressed.connect(_on_back)
	btn_row.add_child(back_btn)

# ── Outfit tiles ──────────────────────────────
func _make_outfit_tile(index: int, parent: Node) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(130, 130)
	btn.tooltip_text        = OUTFIT_NAMES[index]

	var is_selected := (index == GameData.selected_outfit)
	btn.add_theme_stylebox_override("normal",  _outfit_style(index, is_selected, false))
	btn.add_theme_stylebox_override("hover",   _outfit_style(index, is_selected, true))
	btn.add_theme_stylebox_override("pressed", _outfit_style(index, is_selected, false))

	# Outfit name label inside tile
	var lbl := Label.new()
	lbl.text               = OUTFIT_NAMES[index]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	btn.add_child(lbl)

	btn.mouse_entered.connect(_on_outfit_hover.bind(btn, index))
	btn.mouse_exited.connect(_on_outfit_unhover.bind(btn, index))
	btn.pressed.connect(_on_outfit_selected.bind(index))

	outfit_buttons.append(btn)
	parent.add_child(btn)

func _outfit_style(index: int, selected: bool, hovered: bool) -> StyleBoxFlat:
	var s    := StyleBoxFlat.new()
	var col: Color = OUTFIT_COLORS[index]
	if hovered:
		col = col.lightened(0.15)
	s.bg_color                   = col
	s.corner_radius_top_left     = 12
	s.corner_radius_top_right    = 12
	s.corner_radius_bottom_left  = 12
	s.corner_radius_bottom_right = 12
	s.border_width_left   = 2; s.border_width_right  = 2
	s.border_width_top    = 2; s.border_width_bottom = 2
	s.border_color = Color.WHITE if selected else Color(1, 1, 1, 0.15)
	return s

func _on_outfit_hover(btn: Button, index: int) -> void:
	btn.add_theme_stylebox_override("normal", _outfit_style(index, index == GameData.selected_outfit, true))

func _on_outfit_unhover(btn: Button, index: int) -> void:
	btn.add_theme_stylebox_override("normal", _outfit_style(index, index == GameData.selected_outfit, false))

func _on_outfit_selected(index: int) -> void:
	GameData.selected_outfit = index
	# Refresh all tile borders
	for i in range(outfit_buttons.size()):
		outfit_buttons[i].add_theme_stylebox_override("normal",  _outfit_style(i, i == index, false))
		outfit_buttons[i].add_theme_stylebox_override("hover",   _outfit_style(i, i == index, true))

# ── Helpers ───────────────────────────────────
func _add_section_label(text: String, parent: Node) -> void:
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 1.0))
	parent.add_child(lbl)

func _add_separator(parent: Node) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(1, 1, 1, 0.12))
	parent.add_child(sep)

func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color                   = Color(0.06, 0.06, 0.10, 0.88)
	style.corner_radius_top_left     = 18
	style.corner_radius_top_right    = 18
	style.corner_radius_bottom_left  = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left   = PANEL_PADDING
	style.content_margin_right  = PANEL_PADDING
	style.content_margin_top    = PANEL_PADDING
	style.content_margin_bottom = PANEL_PADDING
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _style_line_edit(le: LineEdit) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.12, 0.12, 0.18, 0.9)
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_left  = 8
	s.corner_radius_bottom_right = 8
	s.border_width_bottom = 2
	s.border_color        = Color(0.35, 0.55, 1.0, 0.7)
	s.content_margin_left = 12
	le.add_theme_stylebox_override("normal", s)
	le.add_theme_color_override("font_color", Color.WHITE)

func _make_action_button(label: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text               = label
	btn.custom_minimum_size = Vector2(160, 52)
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left     = 9
	s.corner_radius_top_right    = 9
	s.corner_radius_bottom_left  = 9
	s.corner_radius_bottom_right = 9
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.border_color = Color(1, 1, 1, 0.18)
	var sh := s.duplicate(); sh.bg_color = bg_color.lightened(0.12)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 17)
	return btn

# ── Callbacks ─────────────────────────────────
func _on_music_toggled(enabled: bool) -> void:
	GameData.music_enabled = enabled

func _on_save() -> void:
	GameData.player_name = name_input.text.strip_edges()
	if GameData.player_name.is_empty():
		GameData.player_name = "Player"
	GameData.save_data()
	_fade_then(func(): GameData.go_to_scene("res://scenes/menus/MainMenu.tscn"))

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
