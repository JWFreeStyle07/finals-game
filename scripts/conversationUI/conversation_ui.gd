extends CanvasLayer

signal conversation_finished

# Node refs
var character_sprite : AnimatedSprite2D
var speaker_name     : Label
var dialog_text      : RichTextLabel
var continue_hint    : Label
var root_control     : Control

const CHAR_DELAY := 0.03

var _pages      : Array[String] = []
var _page_index : int           = 0
var _is_typing  : bool          = false
var _skip_typing: bool          = false
var _active     : bool          = false

var convo_music : AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

	# ── Conversation music setup ───────────────
	convo_music = AudioStreamPlayer.new()
	convo_music.stream = load("res://assets/audio/sfx/Fish_Dialog.mp3")
	convo_music.volume_db = -8.0  # quieter than bg music
	convo_music.autoplay = false
	add_child(convo_music)

	character_sprite.sprite_frames = load("res://assets/sprites/characters/Fish/fish_animation.tres")
	character_sprite.play("idle")


func start_conversation(pages: Array[String], speaker: String = "Mom") -> void:
	_pages      = pages
	_page_index = 0
	_active     = true
	visible     = true
	speaker_name.text = speaker
	dialog_text.text  = ""
	continue_hint.visible = false
	get_tree().paused = true

	# ── Play convo music, bg music keeps going ──
	convo_music.play()

	if character_sprite.sprite_frames != null and \
			character_sprite.sprite_frames.has_animation("talk"):
		character_sprite.play("talk")

	await _show_page(0)


func _input(event: InputEvent) -> void:
	if not _active:
		return

	var pressed: bool = (
		(event is InputEventKey         and event.pressed) or
		(event is InputEventMouseButton and event.pressed) or
		(event is InputEventScreenTouch and event.pressed)
	)

	if not pressed:
		return

	get_viewport().set_input_as_handled()

	if _is_typing:
		_skip_typing = true
	else:
		_next_page()


func _show_page(index: int) -> void:
	dialog_text.text      = ""
	continue_hint.visible = false
	_is_typing            = true
	_skip_typing          = false

	# Play talk animation while typing
	if character_sprite.sprite_frames != null and \
			character_sprite.sprite_frames.has_animation("talk"):
		character_sprite.play("talk")

	await _typewrite(_pages[index])

	# Play idle animation when done typing
	if character_sprite.sprite_frames != null and \
			character_sprite.sprite_frames.has_animation("idle"):
		character_sprite.play("idle")


func _typewrite(full_text: String) -> void:
	var i := 0
	while i < full_text.length():
		if _skip_typing:
			dialog_text.text      = full_text
			_is_typing            = false
			continue_hint.visible = true
			return
		dialog_text.text += full_text[i]
		i += 1
		await get_tree().create_timer(CHAR_DELAY, true, false, true).timeout

	_is_typing            = false
	continue_hint.visible = true


func _next_page() -> void:
	_page_index += 1
	if _page_index >= _pages.size():
		_end_conversation()
	else:
		await _show_page(_page_index)


func _end_conversation() -> void:
	_active = false
	get_tree().paused = false
	visible = false

	# ── Stop convo music, bg music keeps going ──
	convo_music.stop()

	emit_signal("conversation_finished")


func _build_ui() -> void:
	# ── Root control ─────────────────────────────
	root_control = Control.new()
	root_control.name = "Root"
	root_control.process_mode = Node.PROCESS_MODE_ALWAYS
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# ── Dark overlay ─────────────────────────────
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(overlay)

	# ── Character holder (lower-left) ────────────
	var spr_holder := Control.new()
	spr_holder.set_anchor(SIDE_LEFT,   0.0)
	spr_holder.set_anchor(SIDE_RIGHT,  0.0)
	spr_holder.set_anchor(SIDE_TOP,    1.0)
	spr_holder.set_anchor(SIDE_BOTTOM, 1.0)
	spr_holder.offset_left   = 10
	spr_holder.offset_right  = 210
	spr_holder.offset_top    = -420
	spr_holder.offset_bottom = -180
	root_control.add_child(spr_holder)

	# Border panel behind everything in the holder
	var border_panel := Panel.new()
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var border_style := StyleBoxFlat.new()
	border_style.bg_color     = Color(0.08, 0.04, 0.01, 0.92)
	border_style.border_color = Color(0.55, 0.35, 0.17)
	border_style.set_border_width_all(3)
	border_style.set_corner_radius_all(8)
	border_panel.add_theme_stylebox_override("panel", border_style)
	spr_holder.add_child(border_panel)

	# Control anchor so AnimatedSprite2D can be centered inside holder
	var spr_anchor := Control.new()
	spr_anchor.set_anchors_preset(Control.PRESET_FULL_RECT)
	spr_anchor.offset_left   = 4
	spr_anchor.offset_right  = -4
	spr_anchor.offset_top    = 4
	spr_anchor.offset_bottom = -4
	spr_holder.add_child(spr_anchor)

	# AnimatedSprite2D — centered inside the holder box
	var anim_spr := AnimatedSprite2D.new()
	anim_spr.name     = "CharacterSprite"
	anim_spr.position = Vector2(95, 113)
	anim_spr.scale    = Vector2(0.5, 0.5)
	spr_anchor.add_child(anim_spr)
	character_sprite = anim_spr

	# ── Dialog box (bottom, starts after character box) ──
	var panel := PanelContainer.new()
	panel.name = "DialogBox"
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left   =  220.0
	panel.offset_right  = -20.0
	panel.offset_top    = -220.0
	panel.offset_bottom = -20.0

	var box_style := StyleBoxFlat.new()
	box_style.bg_color     = Color(0.08, 0.04, 0.01, 0.95)
	box_style.border_color = Color(0.55, 0.35, 0.17)
	box_style.set_border_width_all(3)
	box_style.set_corner_radius_all(8)
	box_style.content_margin_left   = 16
	box_style.content_margin_right  = 16
	box_style.content_margin_top    = 12
	box_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box_style)
	root_control.add_child(panel)

	# ── VBox inside dialog panel ─────────────────
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Speaker name
	var name_lbl := Label.new()
	name_lbl.text = "Mom"
	name_lbl.add_theme_color_override("font_color", Color(0.91, 0.66, 0.13))
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)
	speaker_name = name_lbl

	# Divider
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Dialog text
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled      = true
	rtl.fit_content         = false
	rtl.scroll_active       = false
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.custom_minimum_size = Vector2(0, 80)
	rtl.add_theme_color_override("default_color", Color(1.0, 1.0, 1.0, 1.0))
	rtl.add_theme_font_size_override("normal_font_size", 25)
	vbox.add_child(rtl)
	dialog_text = rtl

	# Continue hint
	var hint := Label.new()
	hint.text    = "▶  Press any key to continue"
	hint.visible = false
	hint.add_theme_color_override("font_color", Color(0.55, 0.61, 0.35))
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(hint)
	continue_hint = hint

	# ── Custom font ───────────────────────────────
	var my_font := load("res://assets/fonts/Minecraft.ttf") as FontFile
	speaker_name.add_theme_font_override("font", my_font)
	dialog_text.add_theme_font_override("normal_font", my_font)
	continue_hint.add_theme_font_override("font", my_font)
