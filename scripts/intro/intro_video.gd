#extends Control
#
## ─────────────────────────────────────────────
##  intro_video.gd  —  Attached to IntroVideo.tscn
##
##  Scene tree structure (IntroVideo.tscn):
##  └─ IntroVideo  (Control, full-rect, this script)
##      ├─ VideoStreamPlayer   (name: "VideoPlayer")
##      └─ SkipButton          (name: "SkipButton", Button node)
##          └─ Label           (text: "SKIP  ▶▶")
## ─────────────────────────────────────────────
#
#@onready var video_player: VideoStreamPlayer = $VideoPlayer
#@onready var skip_button: Button             = $SkipButton
#
#const NEXT_SCENE := "res://scenes/menus/MainMenu.tscn"
#
#func _ready() -> void:
	## ── Configure video player ──────────────────
	#video_player.stream = load("res://assets/video/intro.ogv")
	#video_player.finished.connect(_on_video_finished)
	#video_player.play()
#
	## ── Skip button styling ──────────────────────
	#skip_button.pressed.connect(_skip)
	#_style_skip_button()
#
	## Animate the skip button in after 1 second
	#skip_button.modulate.a = 0.0
	#var tween := create_tween()
	#tween.tween_interval(1.0)
	#tween.tween_property(skip_button, "modulate:a", 1.0, 0.5)
#
#func _style_skip_button() -> void:
	## Position: bottom-right corner
	#skip_button.anchor_left   = 1.0
	#skip_button.anchor_top    = 1.0
	#skip_button.anchor_right  = 1.0
	#skip_button.anchor_bottom = 1.0
	#skip_button.offset_left   = -160.0
	#skip_button.offset_top    = -60.0
	#skip_button.offset_right  = -20.0
	#skip_button.offset_bottom = -20.0
#
	#var normal_style  := StyleBoxFlat.new()
	#var hover_style   := StyleBoxFlat.new()
	#var pressed_style := StyleBoxFlat.new()
#
	#for s in [normal_style, hover_style, pressed_style]:
		#s.corner_radius_top_left     = 6
		#s.corner_radius_top_right    = 6
		#s.corner_radius_bottom_left  = 6
		#s.corner_radius_bottom_right = 6
#
	#normal_style.bg_color  = Color(0.0, 0.0, 0.0, 0.55)
	#hover_style.bg_color   = Color(1.0, 1.0, 1.0, 0.15)
	#pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.05)
#
	#skip_button.add_theme_stylebox_override("normal",  normal_style)
	#skip_button.add_theme_stylebox_override("hover",   hover_style)
	#skip_button.add_theme_stylebox_override("pressed", pressed_style)
	#skip_button.add_theme_color_override("font_color", Color.WHITE)
	#skip_button.add_theme_font_size_override("font_size", 16)
#
#func _on_video_finished() -> void:
	#_go_to_main_menu()
#
#func _skip() -> void:
	#video_player.stop()
	#_go_to_main_menu()
#
#func _go_to_main_menu() -> void:
	## Fade out then change scene
	#var tween := create_tween()
	#tween.tween_property(self, "modulate:a", 0.0, 0.4)
	#tween.tween_callback(Callable(GameData, "go_to_scene").bind(NEXT_SCENE))
extends Control

# ─────────────────────────────────────────────
#  intro_video.gd  —  Attached to IntroVideo.tscn
#
#  Scene tree structure (IntroVideo.tscn):
#  └─ IntroVideo  (Control, full-rect, this script)
#      ├─ VideoStreamPlayer   (name: "VideoPlayer")
#      └─ SkipButton          (name: "SkipButton", Button node)
#          └─ Label           (text: "SKIP  ▶▶")
# ─────────────────────────────────────────────

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var skip_button: Button             = $SkipButton

const NEXT_SCENE := "res://scenes/pressAnyKey/pressAnyKey.tscn"

func _ready() -> void:
	# ── Configure video player ──────────────────
	video_player.stream = load("res://assets/video/intro.ogv")
	video_player.finished.connect(_on_video_finished)

	# Make video fill the entire screen
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.autoplay = false

	video_player.play()

	# ── Skip button styling ──────────────────────
	skip_button.pressed.connect(_skip)
	_style_skip_button()

	# Animate the skip button in after 1 second
	skip_button.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(skip_button, "modulate:a", 1.0, 0.5)

func _style_skip_button() -> void:
	# Position: bottom-right corner
	skip_button.anchor_left   = 1.0
	skip_button.anchor_top    = 1.0
	skip_button.anchor_right  = 1.0
	skip_button.anchor_bottom = 1.0
	skip_button.offset_left   = -160.0
	skip_button.offset_top    = -60.0
	skip_button.offset_right  = -20.0
	skip_button.offset_bottom = -20.0

	var normal_style  := StyleBoxFlat.new()
	var hover_style   := StyleBoxFlat.new()
	var pressed_style := StyleBoxFlat.new()

	for s in [normal_style, hover_style, pressed_style]:
		s.corner_radius_top_left     = 6
		s.corner_radius_top_right    = 6
		s.corner_radius_bottom_left  = 6
		s.corner_radius_bottom_right = 6

	normal_style.bg_color  = Color(0.0, 0.0, 0.0, 0.55)
	hover_style.bg_color   = Color(1.0, 1.0, 1.0, 0.15)
	pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.05)

	skip_button.add_theme_stylebox_override("normal",  normal_style)
	skip_button.add_theme_stylebox_override("hover",   hover_style)
	skip_button.add_theme_stylebox_override("pressed", pressed_style)
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.add_theme_font_size_override("font_size", 16)

func _on_video_finished() -> void:
	_go_to_main_menu()

func _skip() -> void:
	video_player.stop()
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	# Fade out then change scene
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(GameData, "go_to_scene").bind(NEXT_SCENE))
