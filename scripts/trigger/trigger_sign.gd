extends Node2D

# ─────────────────────────────────────────────
#  TriggerSign
#  A visual indicator that bobs up and down
#  to guide the player toward the trigger area.
#
#  Scene structure:
#  TriggerSign (Node2D, this script)
#  └─ Sprite2D or AnimatedSprite2D   ← your sign graphic
#  └─ Label                          ← optional "!" or arrow text
# ─────────────────────────────────────────────

@export var pulse_speed : float = 1.5   # bobs per second

var _base_position : Vector2
var _label         : Label


func _ready() -> void:
	if get_child_count() == 0 or not (get_child(0) is Sprite2D or get_child(0) is AnimatedSprite2D):
		_build_fallback_label()
	_base_position = position
	_pulse()


func _pulse() -> void:
	while true:
		# Move UP 3 pixels
		var tween_up := create_tween()
		tween_up.tween_property(self, "position",
			_base_position + Vector2(0, -3), 1.0 / pulse_speed) \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
		await tween_up.finished

		# Move DOWN 3 pixels
		var tween_down := create_tween()
		tween_down.tween_property(self, "position",
			_base_position + Vector2(0, 3), 1.0 / pulse_speed) \
			.set_ease(Tween.EASE_IN_OUT) \
			.set_trans(Tween.TRANS_SINE)
		await tween_down.finished


func _build_fallback_label() -> void:
	var label := Label.new()
	label.text = "❕"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	label.set_anchor(SIDE_LEFT,   0.5)
	label.set_anchor(SIDE_RIGHT,  0.5)
	label.set_anchor(SIDE_TOP,    0.5)
	label.set_anchor(SIDE_BOTTOM, 0.5)
	label.offset_left   = -16
	label.offset_right  =  16
	label.offset_top    = -16
	label.offset_bottom =  16
	add_child(label)
	_label = label


func hide_sign() -> void:
	visible = false


func show_sign() -> void:
	visible = true
