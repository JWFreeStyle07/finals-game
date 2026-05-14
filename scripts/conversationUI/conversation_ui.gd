extends CanvasLayer

# ─────────────────────────────────────────────
#  ConversationUI
#
#  Scene structure:
#  ConversationUI (CanvasLayer)
#  └─ Root (Control, full rect)
#      ├─ CharacterSprite (AnimatedSprite2D)   ← left side
#      └─ DialogBox (PanelContainer)           ← bottom center
#          └─ VBox (VBoxContainer)
#              ├─ SpeakerName (Label)
#              ├─ DialogText (RichTextLabel)
#              └─ ContinueHint (Label)         "Press any key..."
# ─────────────────────────────────────────────

signal conversation_finished

@onready var character_sprite : AnimatedSprite2D = $Root/CharacterSprite
@onready var dialog_box       : PanelContainer   = $Root/DialogBox
@onready var speaker_name     : Label            = $Root/DialogBox/VBox/SpeakerName
@onready var dialog_text      : RichTextLabel    = $Root/DialogBox/VBox/DialogText
@onready var continue_hint    : Label            = $Root/DialogBox/VBox/ContinueHint

# ── Typewriter settings ──
const CHAR_DELAY := 0.03   # seconds between each character

var _pages       : Array[String] = []
var _page_index  : int           = 0
var _is_typing   : bool          = false
var _skip_typing : bool          = false
var _active      : bool          = false
var _tween       : Tween


func _ready() -> void:
	visible = false
	_build_ui()


# ── Public: start a conversation ─────────────────────────────────

func start_conversation(pages: Array[String], speaker: String = "Guide") -> void:
	
	_pages      = pages
	_page_index = 0
	_active     = true
	visible     = true
	speaker_name.text = speaker

	# Freeze the game while talking
	get_tree().paused = true

	# Fade in
	$Root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($Root, "modulate:a", 1.0, 0.3)
	await tween.finished

	_show_page(_page_index)


# ── Input: any key/click/touch advances ──────────────────────────
func _unhandled_input(event: InputEvent) -> void:
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
		# First press: finish typing instantly
		_skip_typing = true
	else:
		# Already done typing: go to next page
		_next_page()


# ── Show one page ────────────────────────────────────────────────
func _show_page(index: int) -> void:
	dialog_text.text    = ""
	continue_hint.visible = false
	_is_typing   = true
	_skip_typing = false

	# Play idle animation if available
	if character_sprite.sprite_frames and \
			character_sprite.sprite_frames.has_animation("talk"):
		character_sprite.play("talk")

	await _typewrite(_pages[index])

	_is_typing = false
	continue_hint.visible = true

	# Play idle animation when done typing
	if character_sprite.sprite_frames and \
			character_sprite.sprite_frames.has_animation("idle"):
		character_sprite.play("idle")


func _typewrite(full_text: String) -> void:
	dialog_text.text = ""
	for i in full_text.length():
		if _skip_typing:
			dialog_text.text = full_text
			return
		dialog_text.text += full_text[i]
		await get_tree().create_timer(CHAR_DELAY).timeout


func _next_page() -> void:
	_page_index += 1
	if _page_index >= _pages.size():
		_end_conversation()
	else:
		_show_page(_page_index)


func _end_conversation() -> void:
	_active = false
	get_tree().paused = false

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	visible = false
	emit_signal("conversation_finished")


# ── Build UI in code (no .tscn needed for the UI layout) ─────────
func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Character sprite placeholder (left side, lower half) ──
	var spr := AnimatedSprite2D.new()
	spr.name     = "CharacterSprite"
	spr.position = Vector2(120, 500)   # adjust to your screen
	root.add_child(spr)

	# ── Dialog box (bottom, wide) ──
	var panel := PanelContainer.new()
	panel.name = "DialogBox"
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left   =  160.0   # leave room for character sprite
	panel.offset_right  = -20.0
	panel.offset_top    = -200.0
	panel.offset_bottom = -20.0

	var box_style := StyleBoxFlat.new()
	box_style.bg_color     = Color(0.08, 0.04, 0.01, 0.92)
	box_style.border_color = Color(0.55, 0.35, 0.17)
	box_style.set_border_width_all(3)
	box_style.set_corner_radius_all(8)
	box_style.content_margin_left   = 16
	box_style.content_margin_right  = 16
	box_style.content_margin_top    = 12
	box_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", box_style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Speaker name
	var name_lbl := Label.new()
	name_lbl.name = "SpeakerName"
	name_lbl.text = "Guide"
	name_lbl.add_theme_color_override("font_color", Color(0.91, 0.66, 0.13))
	name_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_lbl)

	# Dialog text (RichTextLabel supports BBCode formatting)
	var rtl := RichTextLabel.new()
	rtl.name            = "DialogText"
	rtl.bbcode_enabled  = true
	rtl.fit_content     = false
	rtl.scroll_active   = false
	rtl.custom_minimum_size = Vector2(0, 100)
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rtl.add_theme_color_override("default_color", Color(0.91, 0.79, 0.60))
	rtl.add_theme_font_size_override("normal_font_size", 15)
	vbox.add_child(rtl)

	# Continue hint
	var hint := Label.new()
	hint.name    = "ContinueHint"
	hint.text    = "▶  Press any key to continue"
	hint.visible = false
	hint.add_theme_color_override("font_color", Color(0.55, 0.61, 0.35))
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(hint)
