extends Node

# ─────────────────────────────────────────────
#  TUTORIAL GAME MANAGER
#  Same as GameManager but:
#   - Only 1 task (deliver the crumpled paper)
#   - No deadline / no timer pressure
#   - On win → fade out → go to Level 1
# ─────────────────────────────────────────────

@export var level1_scene : String = "res://scenes/levels/Level1.tscn"

@onready var hud    : CanvasLayer     = $"../HUD"
@onready var player : CharacterBody2D = $"../Player"

var tasks      : Array[Dictionary] = []
var tasks_done : Array[bool]       = []
var game_active: bool = true


func _ready() -> void:
	add_to_group("game_manager")

	player.stats_changed.connect(hud.update_stats)
	player.inventory_changed.connect(hud.update_inventory)
	player.stat_depleted.connect(_on_stat_depleted)

	# Tutorial has only one task
	tasks = [
		{
			"id":          "task_trash",
			"label":       "Put crumpled paper in trash bin",
			"item_id":     "crumpled_paper",
			"receiver_id": "trash_bin"
		}
	]

	tasks_done.resize(tasks.size())
	tasks_done.fill(false)

	var task_labels : Array[String] = []
	for t in tasks:
		task_labels.append(t.get("label", "???"))
	hud.setup_tasks(task_labels)

	# Show timer label but count up (relaxed tutorial — no pressure)
	hud.setup_timer(0, "TUTORIAL")

	hud.update_stats(player.health, player.energy, player.happiness)


# ── Called by ReceiverObject ──────────────────────────────────────
func try_complete_task(item_id: String, receiver_id: String) -> void:
	if not game_active:
		return

	for i in tasks.size():
		if tasks_done[i]:
			continue
		var t : Dictionary = tasks[i]
		if t.get("item_id", "") == item_id and t.get("receiver_id", "") == receiver_id:
			tasks_done[i] = true
			hud.complete_task(i)
			_on_task_completed(i)
			break

	_check_win()


func _on_task_completed(_index: int) -> void:
	player.restore_stats(0.0, 0.0, 15.0)


func _check_win() -> void:
	if tasks_done.all(func(d): return d):
		_trigger_win()


func _trigger_win() -> void:
	if not game_active:
		return
	game_active = false

	# Small pause so the player sees the checkmark
	await get_tree().create_timer(2.0).timeout

	# Fade the whole tree to black then load Level 1
	var tween := create_tween()
	tween.tween_property(get_tree().get_root(), "modulate:a", 0.0, 0.8)
	await tween.finished

	get_tree().change_scene_to_file(level1_scene)


func _on_stat_depleted(_stat_name: String) -> void:
	# In tutorial, just restore the stat instead of game-over
	player.restore_stats(20.0, 20.0, 20.0)
