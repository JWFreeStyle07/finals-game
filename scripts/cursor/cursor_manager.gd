extends Node

var cursor_default = preload("res://assets/sprites/cursor/cursor1.png")
var cursor_click   = preload("res://assets/sprites/cursor/cursor2.png")

# Add an AudioStreamPlayer for the SFX
var audio_player : AudioStreamPlayer

func _ready():
	Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))

	# Create and configure the audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = preload("res://assets/audio/sfx/cursor_click_sound.wav")
	audio_player.volume_db = 0.0  # Adjust volume here (-10 = quieter, 10 = louder)
	add_child(audio_player)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Input.set_custom_mouse_cursor(cursor_click, Input.CURSOR_ARROW, Vector2(0, 0))
				if not audio_player.playing:
					audio_player.play()  # 👈 Play SFX on click
			else:
				Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))
