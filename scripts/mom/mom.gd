## mom.gd
## Attach to: CharacterBody2D (root of Mom.tscn)
#extends CharacterBody2D
#
## ── Tuning ──────────────────────────────────────────
#const MOVE_SPEED      := 55.0    # slower than player (80)
#const THROW_RANGE     := 260.0   # px — start throwing when this close
#const THROW_COOLDOWN  := 2.5     # seconds between throws (after weapon returns)
#const DETECTION_RANGE := 600.0   # px — Mom starts chasing beyond this distance too
#
#@export var weapon_scene : PackedScene   # drag Weapon.tscn in Inspector
#
## ── State machine ───────────────────────────────────
#enum State { CHASE, THROW, WAIT_RETURN, COOLDOWN }
#var state : State = State.CHASE
#
#var player_ref    : CharacterBody2D = null
#var weapon_instance : Node2D        = null
#var _cooldown_timer := 0.0
#var _weapon_in_air  := false
#
#@onready var anim  : AnimatedSprite2D  = $AnimatedSprite2D
#@onready var nav   : NavigationAgent2D = $NavigationAgent2D
#@onready var throw_point : Marker2D    = $ThrowPoint
#
#
#func _ready() -> void:
	#add_to_group("mom")
	## Find player
	#await get_tree().process_frame
	#var players := get_tree().get_nodes_in_group("player")
	#if players.size() > 0:
		#player_ref = players[0]
#
#
#func _physics_process(delta: float) -> void:
	#if player_ref == null:
		#return
#
	#match state:
		#State.CHASE:
			#_do_chase(delta)
		#State.THROW:
			#_do_throw()
		#State.WAIT_RETURN:
			#_do_wait_idle()
		#State.COOLDOWN:
			#_do_cooldown(delta)
#
#
## ── CHASE ────────────────────────────────────────────
#func _do_chase(delta: float) -> void:
	#var dist := global_position.distance_to(player_ref.global_position)
#
	#if dist <= THROW_RANGE:
		#state = State.THROW
		#return
#
	## Navigate toward player
	#nav.target_position = player_ref.global_position
	#var next_pos := nav.get_next_path_position()
	#var dir      := (next_pos - global_position).normalized()
	#velocity     = dir * MOVE_SPEED
	#move_and_slide()
	#_play_walk_anim(dir)
#
#
## ── THROW ────────────────────────────────────────────
#func _do_throw() -> void:
	## Stop moving, face player, throw
	#velocity = Vector2.ZERO
	#_play_throw_anim()
#
	#if weapon_instance == null and weapon_scene != null:
		#weapon_instance = weapon_scene.instantiate()
		#get_parent().add_child(weapon_instance)
		#weapon_instance.launch(player_ref, self)
		#_weapon_in_air = true
		#state = State.WAIT_RETURN
#
#
## ── WAIT FOR RETURN ───────────────────────────────────
#func _do_wait_idle() -> void:
	#velocity = Vector2.ZERO
	#_play_idle_anim()
	## Transition handled by on_weapon_returned() callback
#
#
## ── COOLDOWN ─────────────────────────────────────────
#func _do_cooldown(delta: float) -> void:
	#_cooldown_timer -= delta
	#_play_idle_anim()
	#if _cooldown_timer <= 0.0:
		#state = State.CHASE
#
#
## Called by weapon.gd when the weapon arrives back at mom
#func on_weapon_returned() -> void:
	#_weapon_in_air  = false
	#weapon_instance = null
	#_cooldown_timer = THROW_COOLDOWN
	#state = State.COOLDOWN
#
## ── ANIMATIONS ───────────────────────────────────────
#func _play_walk_anim(dir: Vector2) -> void:
	#var suffix := _dir_suffix(dir)
	#var name_  := "walk_" + suffix
	#if anim.animation != name_:
		#anim.play(name_)
#
#func _play_throw_anim() -> void:
	#var suffix := _dir_suffix(
		#(player_ref.global_position - global_position).normalized()
	#)
	#var name_ := "throw_" + suffix
	#if anim.animation != name_:
		#anim.play(name_)
#
#func _play_idle_anim() -> void:
	#var suffix := _dir_suffix(
		#(player_ref.global_position - global_position).normalized()
	#)
	#var name_ := "idle_" + suffix
	#if anim.animation != name_:
		#anim.play(name_)
#
#func _dir_suffix(dir: Vector2) -> String:
	#if abs(dir.y) >= abs(dir.x):
		#return "down" if dir.y > 0 else "up"
	#return "right" if dir.x > 0 else "left"
#
#func set_target(player: CharacterBody2D) -> void:
	#player_ref = player
# mom.gd
# Attach to: CharacterBody2D (root of Mom.tscn)
extends CharacterBody2D

# ── Tuning ──────────────────────────────────────────
const MOVE_SPEED      := 40.0    # slower than player (80)
const THROW_RANGE     := 100.0   # px — start throwing when this close
const THROW_COOLDOWN  := 2.5     # seconds between throws (after weapon returns)
const DETECTION_RANGE := 600.0   # px — Mom starts chasing beyond this distance too

@export var weapon_scene : PackedScene   # drag Weapon.tscn in Inspector

# ── State machine ───────────────────────────────────
enum State { CHASE, THROW, WAIT_RETURN, COOLDOWN }
var state : State = State.CHASE

var player_ref    : CharacterBody2D = null
var weapon_instance : Node2D        = null
var _cooldown_timer := 0.0
var _weapon_in_air  := false

@onready var anim  : AnimatedSprite2D  = $AnimatedSprite2D
@onready var nav   : NavigationAgent2D = $NavigationAgent2D
@onready var throw_point : Marker2D    = $ThrowPoint


func _ready() -> void:
	add_to_group("mom")
	# Find player
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]


func _physics_process(delta: float) -> void:
	if player_ref == null:
		return

	match state:
		State.CHASE:
			_do_chase(delta)
		State.THROW:
			_do_throw()
		State.WAIT_RETURN:
			_do_wait_idle()
		State.COOLDOWN:
			_do_cooldown(delta)


# ── CHASE ────────────────────────────────────────────
#func _do_chase(delta: float) -> void:
	#var dist := global_position.distance_to(player_ref.global_position)
#
	#if dist <= THROW_RANGE:
		#state = State.THROW
		#return
#
	## Navigate toward player
	#nav.target_position = player_ref.global_position
	#var next_pos := nav.get_next_path_position()
	#var dir      := (next_pos - global_position).normalized()
	#velocity     = dir * MOVE_SPEED
	#move_and_slide()
	#_play_walk_anim(dir)
func _do_chase(delta: float) -> void:
	var dist := global_position.distance_to(player_ref.global_position)
	print("dist: ", dist, " THROW_RANGE: ", THROW_RANGE)  # add this

	if dist <= THROW_RANGE:
		state = State.THROW
		return

	var dir := (player_ref.global_position - global_position).normalized()
	velocity = dir * MOVE_SPEED
	print("velocity: ", velocity, " dir: ", dir)  # add this
	move_and_slide()
	_play_walk_anim(dir)
# ── THROW ────────────────────────────────────────────
func _do_throw() -> void:
	# Stop moving, face player, throw
	velocity = Vector2.ZERO
	_play_throw_anim()

	if weapon_instance == null and weapon_scene != null:
		weapon_instance = weapon_scene.instantiate()
		get_parent().add_child(weapon_instance)
		weapon_instance.launch(player_ref, self)
		_weapon_in_air = true
		state = State.WAIT_RETURN


# ── WAIT FOR RETURN ───────────────────────────────────
func _do_wait_idle() -> void:
	velocity = Vector2.ZERO
	_play_idle_anim()
	# Transition handled by on_weapon_returned() callback


# ── COOLDOWN ─────────────────────────────────────────
func _do_cooldown(delta: float) -> void:
	_cooldown_timer -= delta
	_play_idle_anim()
	if _cooldown_timer <= 0.0:
		state = State.CHASE


# Called by weapon.gd when the weapon arrives back at mom
func on_weapon_returned() -> void:
	_weapon_in_air  = false
	weapon_instance = null
	_cooldown_timer = THROW_COOLDOWN
	state = State.COOLDOWN

# ── ANIMATIONS ───────────────────────────────────────
func _play_walk_anim(dir: Vector2) -> void:
	var suffix := _dir_suffix(dir)
	var name_  := "walk_" + suffix
	if anim.animation != name_:
		anim.play(name_)

func _play_throw_anim() -> void:
	var suffix := _dir_suffix(
		(player_ref.global_position - global_position).normalized()
	)
	var name_ := "throw_" + suffix
	if anim.animation != name_:
		anim.play(name_)

func _play_idle_anim() -> void:
	var suffix := _dir_suffix(
		(player_ref.global_position - global_position).normalized()
	)
	var name_ := "idle_" + suffix
	if anim.animation != name_:
		anim.play(name_)

func _dir_suffix(dir: Vector2) -> String:
	if abs(dir.y) >= abs(dir.x):
		return "down" if dir.y > 0 else "up"
	return "right" if dir.x > 0 else "left"

func set_target(player: CharacterBody2D) -> void:
	player_ref = player
