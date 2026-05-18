extends Control

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var bg_music: AudioStreamPlayer = $BGMusic  # 👈 add this

const NEXT_SCENE := "res://scenes/tutorial/Tutorial.tscn"

var _can_skip := false

func _ready() -> void:
	anchor_left   = 0.0
	anchor_top    = 0.0
	anchor_right  = 1.0
	anchor_bottom = 1.0
	offset_left   = 0.0
	offset_top    = 0.0
	offset_right  = 0.0
	offset_bottom = 0.0

	# ── Video setup ──────────────────────────────
	video_player.stream = load("res://assets/video/PressAnyKey.ogv")
	var screen_size := get_viewport_rect().size
	video_player.position = Vector2.ZERO
	video_player.size = screen_size
	video_player.expand = true
	video_player.autoplay = false
	video_player.loop = true
	video_player.play()

	# ── Music setup ──────────────────────────────
	bg_music.stream = load("res://assets/audio/sfx/bg-sound-start_game_screen(press start).mp3")
	bg_music.volume_db = 0.0
	bg_music.autoplay = false  # we control it manually
	bg_music.play()            # starts when scene loads

	# ── Fade in ──────────────────────────────────
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(0.6).timeout
	_can_skip = true

func _input(event: InputEvent) -> void:
	if not _can_skip:
		return
	var triggered : bool = (
		(event is InputEventKey and event.pressed) or
		(event is InputEventMouseButton and event.pressed) or
		(event is InputEventScreenTouch and event.pressed)
	)
	if triggered:
		_go_to_tutorial()

func _go_to_tutorial() -> void:
	_can_skip = false
	video_player.stop()
	bg_music.stop()  # 👈 stop music before fading out
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(GameData, "go_to_scene").bind(NEXT_SCENE))
