extends Control

# ─────────────────────────────────────────────
#  play_cutscene.gd  —  Attached to PlayCutscene.tscn
#
#  Plays a cutscene video before loading the
#  player's current level. A skip button is shown.
#
#  Scene tree (PlayCutscene.tscn):
#  └─ PlayCutscene  (Control, full-rect, this script)
#      ├─ VideoPlayer  (VideoStreamPlayer)
#      └─ SkipButton   (Button)
# ─────────────────────────────────────────────

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var skip_button: Button             = $SkipButton

func _ready() -> void:
	video_player.stream = load("res://assets/video/play_cutscene.ogv")
	video_player.finished.connect(_load_level)

	# Make video fill the entire screen
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.autoplay = false

	video_player.play()

	skip_button.pressed.connect(_on_skip)
	_style_skip_button()

	# Fade-in skip button after 1 second
	skip_button.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(skip_button, "modulate:a", 1.0, 0.4)

	# Fade scene in
	modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.5)

func _style_skip_button() -> void:
	skip_button.anchor_left   = 1.0
	skip_button.anchor_top    = 1.0
	skip_button.anchor_right  = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left   = -160.0
	skip_button.offset_top    = -60.0
	skip_button.offset_right  = -20.0
	skip_button.offset_bottom = -20.0
	skip_button.text          = "SKIP  ▶▶"

	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0, 0, 0, 0.55)
	ns.corner_radius_top_left     = 6
	ns.corner_radius_top_right    = 6
	ns.corner_radius_bottom_left  = 6
	ns.corner_radius_bottom_right = 6

	var hs := ns.duplicate()
	hs.bg_color = Color(1, 1, 1, 0.15)

	skip_button.add_theme_stylebox_override("normal", ns)
	skip_button.add_theme_stylebox_override("hover",  hs)
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.add_theme_font_size_override("font_size", 16)

func _on_skip() -> void:
	video_player.stop()
	_load_level()

func _load_level() -> void:
	var level_path := GameData.get_current_level_scene()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(Callable(GameData, "go_to_scene").bind(level_path))
