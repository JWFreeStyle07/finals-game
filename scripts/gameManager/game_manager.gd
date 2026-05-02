extends Node

# ═════════════════════════════════════════════════════════════════════════════
#  GAME MANAGER
#  Attach this script to a Node named "GameManager" in your Level scene.
#  Add it to the group "game_manager" (Node tab → Groups → Add "game_manager").
#
#  This node owns:
#    • The countdown timer
#    • Task completion checking
#    • Win / Lose detection
#    • Spawning the Deadline entity when time runs out
#    • Level progression
# ═════════════════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────
#  LEVEL DATA
#  Edit these per-level inside the Inspector via @export, or set them
#  programmatically before the scene loads.
# ─────────────────────────────────────────────

## Seconds the player has to finish all tasks
@export var level_time_seconds : int    = 300   # 5:00

## Internal level index used for scene transitions
@export var level_index        : int    = 1

## Human-readable label shown in the timer panel
@export var level_display_name : String = "LEVEL 1"

## Scene path to load when the player wins (next level)
@export var next_level_scene   : String = "res://scenes/Level2.tscn"

## Scene path for the game-over screen
@export var game_over_scene    : String = "res://scenes/GameOver.tscn"

## Scene path for the win screen
@export var win_scene          : String = "res://scenes/Win.tscn"

## Scene path to the Deadline entity (the thing that spawns when time runs out)
@export var deadline_scene     : String = "res://scenes/Deadline.tscn"

## Where the Deadline entity spawns (set to a position outside the room)
@export var deadline_spawn_position : Vector2 = Vector2(-64, 300)

# ─────────────────────────────────────────────
#  TASK DATA
#  Each entry is a Dictionary:
#    {
#      "id"         : String  — unique task id,  e.g. "task_trash"
#      "label"      : String  — shown in HUD,    e.g. "Put crumpled paper in trash bin"
#      "item_id"    : String  — id of item to carry, e.g. "crumpled_paper"
#      "receiver_id": String  — id of the receiver object, e.g. "trash_bin"
#    }
#  Populate this array in the Inspector or override _get_level_tasks().
# ─────────────────────────────────────────────
@export var tasks : Array[Dictionary] = []

# ─────────────────────────────────────────────
#  NODE REFS
# ─────────────────────────────────────────────
@onready var hud    : CanvasLayer      = $"../HUD"
@onready var player : CharacterBody2D  = $"../Player"

# Internal timer node — we build it in code
var _timer_node : Timer

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
var time_left         : int  = 0
var deadline_spawned  : bool = false
var deadline_instance : Node = null
var game_active       : bool = true

# Track which tasks are done (parallel to `tasks` array)
var tasks_done : Array[bool] = []


# ═════════════════════════════════════════════
#  LIFECYCLE
# ═════════════════════════════════════════════

func _ready() -> void:
	add_to_group("game_manager")

	# ── Connect player signals ──
	player.stats_changed.connect(hud.update_stats)
	player.inventory_changed.connect(hud.update_inventory)
	player.stat_depleted.connect(_on_stat_depleted)

	# ── Set up tasks ──
	if tasks.is_empty():
		tasks = _get_level_tasks()

	tasks_done.resize(tasks.size())
	tasks_done.fill(false)

	var task_labels : Array[String] = []
	for t in tasks:
		task_labels.append(t.get("label", "???"))
	hud.setup_tasks(task_labels)

	# ── Set up timer ──
	time_left = level_time_seconds
	hud.setup_timer(time_left, level_display_name)

	_timer_node = Timer.new()
	_timer_node.wait_time  = 1.0
	_timer_node.autostart  = true
	_timer_node.one_shot   = false
	_timer_node.timeout.connect(_on_timer_tick)
	add_child(_timer_node)

	# ── Initial stat push so bars are correct from frame 1 ──
	hud.update_stats(player.health, player.energy, player.happiness)


# ═════════════════════════════════════════════
#  TIMER
# ═════════════════════════════════════════════

func _on_timer_tick() -> void:
	if not game_active:
		return

	time_left = max(0, time_left - 1)
	hud.tick_timer(time_left)

	if time_left == 0 and not deadline_spawned:
		_spawn_deadline()


# ═════════════════════════════════════════════
#  TASK COMPLETION
# ═════════════════════════════════════════════

## Called by a receiver object (e.g. TrashBin) when an item is deposited.
## Pass in the item_id of the item that was just placed and the receiver_id.
##
## Example from TrashBin.gd:
##   func receive_item(item: Dictionary) -> void:
##       var gm = get_tree().get_first_node_in_group("game_manager")
##       if gm:
##           gm.try_complete_task(item.get("id",""), "trash_bin")
##
func try_complete_task(item_id: String, receiver_id: String) -> void:
	if not game_active:
		return

	for i in tasks.size():
		if tasks_done[i]:
			continue
		var t : Dictionary = tasks[i]
		if t.get("item_id","") == item_id and t.get("receiver_id","") == receiver_id:
			tasks_done[i] = true
			hud.complete_task(i)
			_on_task_completed(i)
			break

	_check_win()


func _on_task_completed(index: int) -> void:
	# Completing a task boosts happiness a little
	player.restore_stats(0.0, 0.0, 15.0)
	# You can play a sound here via an AudioStreamPlayer in the scene:
	# $TaskCompleteSound.play()
	print("Task %d completed!" % index)


func _check_win() -> void:
	if tasks_done.all(func(d): return d):
		_trigger_win()


# ═════════════════════════════════════════════
#  WIN / LOSE
# ═════════════════════════════════════════════

func _trigger_win() -> void:
	if not game_active:
		return
	game_active = false
	_timer_node.stop()
	print("PLAYER WON!")
	# Small delay so the last task completion animation can play
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(win_scene)


func _trigger_lose(reason: String) -> void:
	if not game_active:
		return
	game_active = false
	_timer_node.stop()
	print("GAME OVER — reason: " + reason)
	# Pass reason to the game-over screen via an autoload or scene metadata
	# e.g.  GameState.last_lose_reason = reason
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file(game_over_scene)


## Called by Player when any stat hits zero
func _on_stat_depleted(stat_name: String) -> void:
	_trigger_lose("Stat depleted: " + stat_name)


## Called by Player's _check_death() via call_group (kept for compatibility)
func on_player_died() -> void:
	_trigger_lose("Player died")


# ═════════════════════════════════════════════
#  DEADLINE ENTITY
# ═════════════════════════════════════════════
#
# The Deadline is a Node2D scene (e.g. an angry ghost / clock spirit) that
# spawns when the timer hits 0:00 and chases the player.
# When it overlaps the player, it calls take_damage() every second.
#
# Minimum Deadline.tscn structure:
#   Deadline (CharacterBody2D  OR  Area2D)
#   ├── Sprite2D / AnimatedSprite2D
#   ├── CollisionShape2D
#   └── script: Deadline.gd  (see template below)

func _spawn_deadline() -> void:
	deadline_spawned = true

	if deadline_scene == "" or not ResourceLoader.exists(deadline_scene):
		push_warning("GameManager: deadline_scene path not set or missing.")
		return

	var packed : PackedScene = load(deadline_scene)
	deadline_instance = packed.instantiate()
	deadline_instance.global_position = deadline_spawn_position

	# Pass a reference so the Deadline can call take_damage on the player
	if deadline_instance.has_method("set_target"):
		deadline_instance.set_target(player)

	get_parent().add_child(deadline_instance)
	print("Deadline entity spawned!")


# ═════════════════════════════════════════════
#  LEVEL TASK DEFINITIONS  (override per level)
# ═════════════════════════════════════════════
#
# If you prefer data-driven tasks via the @export array, leave this empty.
# Otherwise override this function in a child script per level.

func _get_level_tasks() -> Array[Dictionary]:
	# ── LEVEL 1 default tasks ──
	return [
		{
			"id"         : "task_trash",
			"label"      : "Put crumpled paper in trash bin",
			"item_id"    : "crumpled_paper",
			"receiver_id": "trash_bin"
		},
		{
			"id"         : "task_toys",
			"label"      : "Put toys in the toy box",
			"item_id"    : "toy",
			"receiver_id": "toy_box"
		},
		{
			"id"         : "task_laundry",
			"label"      : "Put clothes in the laundry basket",
			"item_id"    : "clothes",
			"receiver_id": "laundry_basket"
		},
		{
			"id"         : "task_dishes",
			"label"      : "Put dishes in the kitchen sink",
			"item_id"    : "dish",
			"receiver_id": "kitchen_sink"
		},
		{
			"id"         : "task_veggies",
			"label"      : "Cook vegetables in the pan",
			"item_id"    : "vegetables",
			"receiver_id": "cooking_pan"
		},
	]
