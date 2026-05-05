#extends Node
#
## ═════════════════════════════════════════════════════════════════════════════
##  GAME MANAGER
##  Attach to a Node named "GameManager" in your Level scene.
##  Add it to the group "game_manager" (Node tab → Groups → "game_manager").
## ═════════════════════════════════════════════════════════════════════════════
#
#@export var level_time_seconds  : int    = 300
#@export var level_index         : int    = 1
#@export var level_display_name  : String = "LEVEL 1"
#@export var next_level_scene    : String = "res://scenes/Level2.tscn"
#@export var game_over_scene     : String = "res://scenes/GameOver.tscn"
#@export var win_scene           : String = "res://scenes/Win.tscn"
#@export var deadline_scene      : String = "res://scenes/Deadline.tscn"
#@export var deadline_spawn_position : Vector2 = Vector2(-64, 300)
#
#@export var tasks : Array[Dictionary] = []
#
## ── Node refs ──
#@onready var hud    : CanvasLayer     = $"../HUD"
#@onready var player : CharacterBody2D = $"../Player"
#
#var _timer_node       : Timer
#var time_left         : int  = 0
#var deadline_spawned  : bool = false
#var deadline_instance : Node = null
#var game_active       : bool = true
#var tasks_done        : Array[bool] = []
#
#
## ═════════════════════════════════════════════
##  LIFECYCLE
## ═════════════════════════════════════════════
#
#func _ready() -> void:
	#add_to_group("game_manager")
#
	## IMPORTANT: This node must NOT be paused when the game pauses,
	## so the HUD can still receive input to unpause.
	## Set process_mode to PROCESS_MODE_ALWAYS so _input still fires on HUD.
	## The Timer node below uses PROCESS_MODE_PAUSABLE (default) so it stops
	## automatically when get_tree().paused = true.
#
	#player.stats_changed.connect(hud.update_stats)
	#player.inventory_changed.connect(hud.update_inventory)
	#player.stat_depleted.connect(_on_stat_depleted)
#
	#if tasks.is_empty():
		#tasks = _get_level_tasks()
#
	#tasks_done.resize(tasks.size())
	#tasks_done.fill(false)
#
	#var task_labels : Array[String] = []
	#for t in tasks:
		#task_labels.append(t.get("label", "???"))
	#hud.setup_tasks(task_labels)
#
	#time_left = level_time_seconds
	#hud.setup_timer(time_left, level_display_name)
#
	## Timer uses PAUSABLE mode by default — stops when tree is paused
	#_timer_node = Timer.new()
	#_timer_node.wait_time = 1.0
	#_timer_node.autostart = true
	#_timer_node.one_shot  = false
	#_timer_node.timeout.connect(_on_timer_tick)
	#add_child(_timer_node)
#
	#hud.update_stats(player.health, player.energy, player.happiness)
#
#
## ═════════════════════════════════════════════
##  TIMER
## ═════════════════════════════════════════════
#
#func _on_timer_tick() -> void:
	## get_tree().paused stops the Timer automatically, but guard anyway
	#if not game_active or get_tree().paused:
		#return
#
	#time_left = max(0, time_left - 1)
	#hud.tick_timer(time_left)
#
	#if time_left == 0 and not deadline_spawned:
		#_spawn_deadline()
#
#
## ═════════════════════════════════════════════
##  TASK COMPLETION
## ═════════════════════════════════════════════
#
#func try_complete_task(item_id: String, receiver_id: String) -> void:
	#if not game_active:
		#return
	#for i in tasks.size():
		#if tasks_done[i]:
			#continue
		#var t : Dictionary = tasks[i]
		#if t.get("item_id","") == item_id and t.get("receiver_id","") == receiver_id:
			#tasks_done[i] = true
			#hud.complete_task(i)
			#_on_task_completed(i)
			#break
	#_check_win()
#
#
#func _on_task_completed(index: int) -> void:
	#player.restore_stats(0.0, 0.0, 15.0)
	#print("Task %d completed!" % index)
#
#
#func _check_win() -> void:
	#if tasks_done.all(func(d): return d):
		#_trigger_win()
#
#
## ═════════════════════════════════════════════
##  WIN / LOSE
## ═════════════════════════════════════════════
#
#func _trigger_win() -> void:
	#if not game_active:
		#return
	#game_active = false
	#_timer_node.stop()
	#await get_tree().create_timer(1.5).timeout
	## ── Show win UI instead of changing scene ──
	#var win_menu = get_tree().get_first_node_in_group("win_menu")
	#if win_menu:
		#win_menu.show_win(current_score)  # pass your score variable here
	#else:
		#push_warning("GameManager: no node in group 'win_menu' found.")
#
#
#func _trigger_lose(reason: String) -> void:
	#if not game_active:
		#return
	#game_active = false
	#_timer_node.stop()
	#print("GAME OVER — reason: " + reason)
	#await get_tree().create_timer(1.2).timeout
	#get_tree().change_scene_to_file(game_over_scene)
#
#
#func _on_stat_depleted(stat_name: String) -> void:
	#_trigger_lose("Stat depleted: " + stat_name)
#
#
#func on_player_died() -> void:
	#_trigger_lose("Player died")
#
#
## ═════════════════════════════════════════════
##  DEADLINE
## ═════════════════════════════════════════════
#
#func _spawn_deadline() -> void:
	#deadline_spawned = true
	#if deadline_scene == "" or not ResourceLoader.exists(deadline_scene):
		#push_warning("GameManager: deadline_scene path not set.")
		#return
	#var packed : PackedScene = load(deadline_scene)
	#deadline_instance = packed.instantiate()
	#deadline_instance.global_position = deadline_spawn_position
	#if deadline_instance.has_method("set_target"):
		#deadline_instance.set_target(player)
	#get_parent().add_child(deadline_instance)
#
#
## ═════════════════════════════════════════════
##  LEVEL TASKS
## ═════════════════════════════════════════════
#
#func _get_level_tasks() -> Array[Dictionary]:
	#return [
		#{"id":"task_trash",   "label":"Put crumpled paper in trash bin",    "item_id":"crumpled_paper", "receiver_id":"trash_bin"},
		#{"id":"task_toys",    "label":"Put toys in the toy box",             "item_id":"toy",            "receiver_id":"toy_box"},
		#{"id":"task_laundry", "label":"Put clothes in the laundry basket",   "item_id":"clothes",        "receiver_id":"laundry_basket"},
		#{"id":"task_dishes",  "label":"Put dishes in the kitchen sink",       "item_id":"dish",           "receiver_id":"kitchen_sink"},
		#{"id":"task_veggies", "label":"Cook vegetables in the pan",           "item_id":"vegetables",     "receiver_id":"cooking_pan"},
	#]
extends Node

# ═════════════════════════════════════════════════════════════════════════════
#  GAME MANAGER
# ═════════════════════════════════════════════════════════════════════════════

@export var level_time_seconds      : int    = 300
@export var level_index             : int    = 1
@export var level_display_name      : String = "LEVEL 1"
@export var next_level_scene        : String = "res://scenes/Level2.tscn"
@export var game_over_scene         : String = "res://scenes/GameOver.tscn"
@export var win_scene               : String = "res://scenes/Win.tscn"
@export var deadline_scene          : String = "res://scenes/Deadline.tscn"
@export var deadline_spawn_position : Vector2 = Vector2(-64, 300)

# ── Score thresholds (auto-calculated, but override in Inspector if needed) ──
# Leave all at 0 to use auto quartile calculation based on level_time_seconds.
# Set manually if you want fixed thresholds per level.
@export var score_q1 : int = 0
@export var score_q2 : int = 0
@export var score_q3 : int = 0

@export var tasks : Array[Dictionary] = []

# ── Node refs ──
@onready var hud    : CanvasLayer     = $"../HUD"
@onready var win_menu = $"../HUD/WinMenu"
@onready var player : CharacterBody2D = $"../Player"

var _timer_node       : Timer
var time_left         : int  = 0
var deadline_spawned  : bool = false
var deadline_instance : Node = null
var game_active       : bool = true
var tasks_done        : Array[bool] = []

# ── Score ──
var current_score     : int  = 0


# ═════════════════════════════════════════════
#  LIFECYCLE
# ═════════════════════════════════════════════

func _ready() -> void:
	add_to_group("game_manager")

	player.stats_changed.connect(hud.update_stats)
	player.inventory_changed.connect(hud.update_inventory)
	player.stat_depleted.connect(_on_stat_depleted)

	if tasks.is_empty():
		tasks = _get_level_tasks()

	tasks_done.resize(tasks.size())
	tasks_done.fill(false)

	var task_labels : Array[String] = []
	for t in tasks:
		task_labels.append(t.get("label", "???"))
	hud.setup_tasks(task_labels)

	time_left = level_time_seconds
	hud.setup_timer(time_left, level_display_name)

	_timer_node = Timer.new()
	_timer_node.wait_time = 1.0
	_timer_node.autostart = true
	_timer_node.one_shot  = false
	_timer_node.timeout.connect(_on_timer_tick)
	add_child(_timer_node)

	# Auto-calculate quartile thresholds if not set manually in Inspector
	if score_q1 == 0 and score_q2 == 0 and score_q3 == 0:
		_calculate_thresholds()

	hud.update_stats(player.health, player.energy, player.happiness)


# ═════════════════════════════════════════════
#  SCORE SYSTEM
# ═════════════════════════════════════════════

# ── How scoring works ──────────────────────────────────────────────────────
#
#  time_score  = (time_left / level_time_seconds) * 1000
#                → Full time remaining = 1000 pts, no time left = 0 pts
#
#  stats_score = mean(health, energy, happiness) * 10
#                → All stats at 100 = 1000 pts, all at 0 = 0 pts
#
#  total       = time_score + stats_score
#                → Max possible = 2000 pts
#
#  Quartiles are computed from the max (2000) and split into 4 equal bands:
#    Q1 = 500   (bottom 25%) → 0 stars
#    Q2 = 1000  (25–50%)     → 1 star
#    Q3 = 1500  (50–75%)     → 2 stars
#    > Q3                    → 3 stars
#
# ──────────────────────────────────────────────────────────────────────────

func _calculate_thresholds() -> void:
	# Max possible score is 2000 (1000 time + 1000 stats)
	var max_score := 2000
	score_q1 = max_score / 4        # 500
	score_q2 = max_score / 2        # 1000
	score_q3 = (max_score * 3) / 4  # 1500


func _compute_score() -> int:
	# Time component: ratio of remaining time scaled to 1000
	var time_ratio  : float = float(time_left) / float(level_time_seconds)
	var time_score  : int   = int(time_ratio * 1000.0)

	# Stats component: mean of the three player stats scaled to 1000
	var stats_mean  : float = (player.health + player.energy + player.happiness) / 3.0
	var stats_score : int   = int((stats_mean / 100.0) * 1000.0)

	return time_score + stats_score


func _score_to_stars(score: int) -> int:
	if score > score_q3:
		return 3
	elif score > score_q2:
		return 2
	elif score > score_q1:
		return 1
	return 0


# ═════════════════════════════════════════════
#  TIMER
# ═════════════════════════════════════════════

func _on_timer_tick() -> void:
	if not game_active or get_tree().paused:
		return

	time_left = max(0, time_left - 1)
	hud.tick_timer(time_left)

	if time_left == 0 and not deadline_spawned:
		_spawn_deadline()


# ═════════════════════════════════════════════
#  TASK COMPLETION
# ═════════════════════════════════════════════

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
	player.restore_stats(0.0, 0.0, 15.0)
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
	await get_tree().create_timer(1.5).timeout

	current_score = _compute_score()

	if win_menu:
		win_menu.show_win(current_score, _score_to_stars(current_score))
	else:
		push_warning("GameManager: WinMenu node not found at ../HUD/WinMenu")

func _trigger_lose(reason: String) -> void:
	if not game_active:
		return
	game_active = false
	_timer_node.stop()
	print("GAME OVER — reason: " + reason)
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file(game_over_scene)


func _on_stat_depleted(stat_name: String) -> void:
	_trigger_lose("Stat depleted: " + stat_name)


func on_player_died() -> void:
	_trigger_lose("Player died")


# ═════════════════════════════════════════════
#  DEADLINE
# ═════════════════════════════════════════════

func _spawn_deadline() -> void:
	deadline_spawned = true
	if deadline_scene == "" or not ResourceLoader.exists(deadline_scene):
		push_warning("GameManager: deadline_scene path not set.")
		return
	var packed : PackedScene = load(deadline_scene)
	deadline_instance = packed.instantiate()
	deadline_instance.global_position = deadline_spawn_position
	if deadline_instance.has_method("set_target"):
		deadline_instance.set_target(player)
	get_parent().add_child(deadline_instance)


# ═════════════════════════════════════════════
#  LEVEL TASKS
# ═════════════════════════════════════════════

func _get_level_tasks() -> Array[Dictionary]:
	return [
		{"id":"task_trash",   "label":"Put crumpled paper in trash bin",    "item_id":"crumpled_paper", "receiver_id":"trash_bin"},
		{"id":"task_toys",    "label":"Put toys in the toy box",             "item_id":"toy",            "receiver_id":"toy_box"},
		{"id":"task_laundry", "label":"Put clothes in the laundry basket",   "item_id":"clothes",        "receiver_id":"laundry_basket"},
		{"id":"task_dishes",  "label":"Put dishes in the kitchen sink",       "item_id":"dish",           "receiver_id":"kitchen_sink"},
		{"id":"task_veggies", "label":"Cook vegetables in the pan",           "item_id":"vegetables",     "receiver_id":"cooking_pan"},
	]
