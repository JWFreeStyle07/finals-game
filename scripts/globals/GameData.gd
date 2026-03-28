extends Node

# ─────────────────────────────────────────────
#  GameData.gd  —  AutoLoad Singleton
#  Add this in: Project > Project Settings > AutoLoad
#  Name it exactly: GameData
# ─────────────────────────────────────────────

const SAVE_PATH := "user://save_data.cfg"

# ── Player Info ──
var player_name: String = "Player"
var selected_outfit: int = 0  # Index of chosen outfit

# ── Audio ──
var music_enabled: bool = true

# ── Progress ──
var current_level: int = 1
var unlocked_levels: Array = [1, 2, 3, 4, 5]  # All unlocked from the start

# ── Outfit options (add your texture paths here) ──
var outfits: Array = [
	"res://assets/characters/outfit_1.png",
	"res://assets/characters/outfit_2.png",
	"res://assets/characters/outfit_3.png",
]

# ── Level scene paths ──
var level_scenes: Array = [
	"res://scenes/levels/Level1.tscn",
	"res://scenes/levels/Level2.tscn",
	"res://scenes/levels/Level3.tscn",
	"res://scenes/levels/Level4.tscn",
	"res://scenes/levels/Level5.tscn",
]

func _ready() -> void:
	load_data()

# ─── Save / Load ───────────────────────────────
func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.set_value("player", "outfit", selected_outfit)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("progress", "current_level", current_level)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # No save file yet — use defaults
	player_name     = cfg.get_value("player",   "name",          player_name)
	selected_outfit = cfg.get_value("player",   "outfit",        selected_outfit)
	music_enabled   = cfg.get_value("audio",    "music_enabled", music_enabled)
	current_level   = cfg.get_value("progress", "current_level", current_level)

# ─── Helpers ───────────────────────────────────
func go_to_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func get_current_level_scene() -> String:
	var idx: int = clamp(current_level - 1, 0, level_scenes.size() - 1)
	return level_scenes[idx]
