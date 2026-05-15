extends Control

# ─────────────────────────────────────────────
#  press_any_key.gd  —  Attached to PressAnyKey.tscn
#
#  Plays a looping "Press Any Key" video.
#  Any keyboard key, mouse click, or touch tap
#  fades out and goes to the tutorial scene.
# ─────────────────────────────────────────────

@onready var video_player: VideoStreamPlayer = $VideoPlayer

const NEXT_SCENE := "res://scenes/tutorial/Tutorial.tscn"  # ← set your tutorial path here
#const NEXT_SCENE := "res://scenes/levels/Level1.tscn"  # ← set your tutorial path here

var _can_skip := false   # small delay so the scene doesn't flash past instantly

func _ready() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = 0.0
	offset_top    = 0.0
	offset_right  = 0.0
	offset_bottom = 0.0

	# ── Video setup ─────────────────────────────
	video_player.stream = load("res://assets/video/PressAnyKey.ogv")

	# Force video player to match screen size exactly
	var screen_size := get_viewport_rect().size
	video_player.position = Vector2.ZERO
	video_player.size = screen_size
	video_player.expand = true
	video_player.autoplay = false
	video_player.loop = true
	video_player.play()

	# Fade the scene in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

	await get_tree().create_timer(0.6).timeout
	_can_skip = true
func _input(event: InputEvent) -> void:
	if not _can_skip:
		return

	# Accept: any key press, any mouse button, or any touch
	var triggered : bool = (
		(event is InputEventKey and event.pressed) or
		(event is InputEventMouseButton and event.pressed) or
		(event is InputEventScreenTouch and event.pressed)
	)

	if triggered:
		_go_to_tutorial()

func _go_to_tutorial() -> void:
	_can_skip = false   # block double-triggers during fade
	video_player.stop()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(GameData, "go_to_scene").bind(NEXT_SCENE))
