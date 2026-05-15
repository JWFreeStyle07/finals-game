extends CharacterBody2D

# ─────────────────────────────────────────────
#  PLAYER STATS
# ─────────────────────────────────────────────
const MAX_HEALTH    := 100.0
const MAX_ENERGY    := 100.0
const MAX_HAPPINESS := 100.0

var health    := MAX_HEALTH
var energy    := MAX_ENERGY
var happiness := MAX_HAPPINESS

# Passive drain per second — happiness drains slowly over time
const HAPPINESS_DRAIN := 0.8

# Energy drain per second ONLY while moving
const ENERGY_MOVE_DRAIN := 2.0

# Energy cost when performing an action (pickup/drop)
const ACTION_ENERGY_COST := 3.0

# Emitted whenever any stat changes — HUD listens to this
signal stats_changed(health: float, energy: float, happiness: float)

# Emitted when a stat hits zero so GameManager can react
signal stat_depleted(stat_name: String)   # "health" | "energy" | "happiness"

# ─────────────────────────────────────────────
#  MOVEMENT
# ─────────────────────────────────────────────
const MOVE_SPEED := 80.0

# ─────────────────────────────────────────────
#  INVENTORY
# ─────────────────────────────────────────────
const INVENTORY_SIZE := 6

var inventory  : Array      = []
var held_item  : Dictionary = {}
var active_slot: int        = 0

signal inventory_changed(inventory: Array, active_slot: int)
signal item_picked_up(item: Dictionary)
signal item_dropped(item: Dictionary, drop_position: Vector2)

# ─────────────────────────────────────────────
#  INTERACTION
# ─────────────────────────────────────────────
var nearby_interactable: Node2D = null

signal interaction_attempted(target: Node)

# ─────────────────────────────────────────────
#  NODE REFERENCES
# ─────────────────────────────────────────────
@onready var animated_sprite : AnimatedSprite2D    = $AnimatedSprite2D
@onready var interaction_area: Area2D              = $InteractionArea
@onready var hold_point      : Marker2D            = $HoldPoint
@onready var step_sound      : AudioStreamPlayer2D = $StepSound
@onready var pickup_sound    : AudioStreamPlayer2D = $PickupSound
@onready var camera          : Camera2D            = $Camera2D

# ─────────────────────────────────────────────
#  STATE MACHINE
# ─────────────────────────────────────────────
enum State { IDLE, MOVING, INTERACTING, DEAD }
var state: State = State.IDLE

var last_direction := Vector2.DOWN
var _is_moving     := false   # tracked to drain energy only while moving


# ═════════════════════════════════════════════
#  LIFECYCLE
# ═════════════════════════════════════════════

func _ready() -> void:
	interaction_area.body_entered.connect(_on_interactable_entered)
	interaction_area.body_exited.connect(_on_interactable_exited)
	interaction_area.area_entered.connect(_on_interactable_area_entered)
	interaction_area.area_exited.connect(_on_interactable_area_exited)

	inventory.resize(INVENTORY_SIZE)
	for i in INVENTORY_SIZE:
		inventory[i] = {}

	add_to_group("player")
	_setup_animations()
	_setup_camera()


# ═════════════════════════════════════════════
#  CAMERA
# ═════════════════════════════════════════════

func _setup_camera() -> void:
	camera.make_current()

func set_camera_limits(used_rect: Rect2i, tile_size: Vector2i) -> void:
	camera.limit_left   = used_rect.position.x * tile_size.x
	camera.limit_top    = used_rect.position.y * tile_size.y
	camera.limit_right  = used_rect.end.x      * tile_size.x
	camera.limit_bottom = used_rect.end.y      * tile_size.y

func set_camera_zoom(zoom_level: float) -> void:
	camera.zoom = Vector2(zoom_level, zoom_level)


# ═════════════════════════════════════════════
#  MAIN LOOP
# ═════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_drain_stats(delta)
	_handle_movement(delta)
	_handle_input()


# ═════════════════════════════════════════════
#  MOVEMENT
# ═════════════════════════════════════════════

func _handle_movement(delta: float) -> void:
	var dir := _get_input_direction()

	if dir != Vector2.ZERO:
		last_direction = dir
		var effective_speed: float = get("_current_move_speed") if get("_current_move_speed") else MOVE_SPEED
		velocity = dir * effective_speed
		state          = State.MOVING
		_is_moving     = true
		_play_walk_animation(dir)
	else:
		velocity   = Vector2.ZERO
		_is_moving = false
		if state == State.MOVING:
			state = State.IDLE
		_play_idle_animation(last_direction)

	move_and_collide(velocity * delta)


func _get_input_direction() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	return dir.normalized()


# ═════════════════════════════════════════════
#  INPUT
# ═════════════════════════════════════════════

func _handle_input() -> void:
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	if Input.is_action_just_pressed("slot_next"):
		_cycle_slot(1)
	if Input.is_action_just_pressed("slot_prev"):
		_cycle_slot(-1)

	for i in INVENTORY_SIZE:
		if Input.is_action_just_pressed("slot_" + str(i + 1)):
			_set_active_slot(i)


# ═════════════════════════════════════════════
#  INTERACTION
# ═════════════════════════════════════════════

func _try_interact() -> void:
	if nearby_interactable == null:
		return

	emit_signal("interaction_attempted", nearby_interactable)

	# ── Pick up a loose item ──
	if held_item.is_empty() and nearby_interactable.has_method("get_item_data"):
		_pickup(nearby_interactable)

	# ── Consume a consumable (apple, food, etc.) ──
	elif held_item.is_empty() and nearby_interactable.has_method("get_consumable_data"):
		_consume(nearby_interactable)

	# ── Place held item into a receiver (trash bin, toy box…) ──
	elif not held_item.is_empty() and nearby_interactable.has_method("can_receive_item"):
		if nearby_interactable.can_receive_item(held_item):
			_place_item(nearby_interactable)


func _pickup(item_node: Node) -> void:
	if not _has_inventory_space() or energy < ACTION_ENERGY_COST:
		return

	var item_data: Dictionary = item_node.get_item_data()
	held_item = item_data

	var slot := _find_empty_slot()
	if slot == -1:
		return
	inventory[slot] = item_data

	_modify_energy(-ACTION_ENERGY_COST)

	if item_node.has_method("on_picked_up"):
		item_node.on_picked_up(hold_point)

	if pickup_sound.stream:
		pickup_sound.play()

	emit_signal("item_picked_up", item_data)
	emit_signal("inventory_changed", inventory, active_slot)


func _place_item(target_node: Node2D) -> void:
	var drop_pos := target_node.global_position

	if target_node.has_method("receive_item"):
		target_node.receive_item(held_item)

	var slot := _find_slot_with_item(held_item)
	if slot != -1:
		inventory[slot] = {}

	emit_signal("item_dropped", held_item, drop_pos)

	held_item = {}
	_modify_energy(-ACTION_ENERGY_COST)

	emit_signal("inventory_changed", inventory, active_slot)


# ── Consuming food / happiness items ─────────────────────────────────────────
# The consumable object must implement get_consumable_data() → Dictionary
# with keys: "energy_restore" (float), "health_restore" (float),
#            "happiness_restore" (float), "label" (String)
#
# Example consumable item script:
#   func get_consumable_data() -> Dictionary:
#       return { "energy_restore": 30.0, "health_restore": 0.0,
#                "happiness_restore": 0.0, "label": "Apple" }

func _consume(consumable_node: Node) -> void:
	var data: Dictionary = consumable_node.get_consumable_data()

	restore_stats(
		data.get("health_restore",    0.0),
		data.get("energy_restore",    0.0),
		data.get("happiness_restore", 0.0)
	)

	# Tell the node to disappear / play effect
	if consumable_node.has_method("on_consumed"):
		consumable_node.on_consumed()


# ═════════════════════════════════════════════
#  INVENTORY HELPERS
# ═════════════════════════════════════════════

func _has_inventory_space() -> bool:
	return _find_empty_slot() != -1

func _find_empty_slot() -> int:
	for i in INVENTORY_SIZE:
		if inventory[i].is_empty():
			return i
	return -1

func _find_slot_with_item(item: Dictionary) -> int:
	for i in INVENTORY_SIZE:
		if inventory[i].get("id", "") == item.get("id", ""):
			return i
	return -1

func _cycle_slot(direction: int) -> void:
	_set_active_slot((active_slot + direction) % INVENTORY_SIZE)

func _set_active_slot(index: int) -> void:
	active_slot = clamp(index, 0, INVENTORY_SIZE - 1)
	held_item   = inventory[active_slot] if not inventory[active_slot].is_empty() else {}
	emit_signal("inventory_changed", inventory, active_slot)


# ═════════════════════════════════════════════
#  STATS
# ═════════════════════════════════════════════

func _drain_stats(delta: float) -> void:
	# Happiness drains passively over time, always
	_modify_happiness(-HAPPINESS_DRAIN * delta)

	# Energy only drains while the player is moving
	if _is_moving:
		_modify_energy(-ENERGY_MOVE_DRAIN * delta)

	# NOTE: Health does NOT drain passively.
	# It is only reduced by:
	#   - take_damage()  called by enemies / the Deadline entity
	#   - Any other hazard script that calls take_damage()


# Public — called by GameManager or enemy scripts to hurt the player
func take_damage(amount: float) -> void:
	_modify_health(-amount)


# Public — called by items/events to restore stats
func restore_stats(h: float = 0.0, e: float = 0.0, hap: float = 0.0) -> void:
	if h   != 0.0: _modify_health(h)
	if e   != 0.0: _modify_energy(e)
	if hap != 0.0: _modify_happiness(hap)


func _modify_health(amount: float) -> void:
	health = clamp(health + amount, 0.0, MAX_HEALTH)
	emit_signal("stats_changed", health, energy, happiness)
	if health <= 0.0:
		_on_stat_zero("health")

func _modify_energy(amount: float) -> void:
	energy = clamp(energy + amount, 0.0, MAX_ENERGY)
	emit_signal("stats_changed", health, energy, happiness)
	if energy <= 0.0:
		_on_stat_zero("energy")

func _modify_happiness(amount: float) -> void:
	happiness = clamp(happiness + amount, 0.0, MAX_HAPPINESS)
	emit_signal("stats_changed", health, energy, happiness)
	if happiness <= 0.0:
		_on_stat_zero("happiness")


func _on_stat_zero(stat_name: String) -> void:
	if state == State.DEAD:
		return
	emit_signal("stat_depleted", stat_name)
	# GameManager listens and triggers game-over; we just flag dead here
	# so the player stops moving while the game-over screen plays.
	state = State.DEAD
	animated_sprite.play("death")


# ═════════════════════════════════════════════
#  ANIMATIONS
# ═════════════════════════════════════════════

func _setup_animations() -> void:
	animated_sprite.play("idle_down")

func _play_walk_animation(dir: Vector2) -> void:
	var anim_name := "walk_" + _direction_to_anim_suffix(dir)
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _play_idle_animation(dir: Vector2) -> void:
	var anim_name := "idle_" + _direction_to_anim_suffix(dir)
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _direction_to_anim_suffix(dir: Vector2) -> String:
	if abs(dir.y) >= abs(dir.x):
		return "down" if dir.y > 0 else "up"
	else:
		return "right" if dir.x > 0 else "left"


# ═════════════════════════════════════════════
#  INTERACTABLE AREA CALLBACKS
# ═════════════════════════════════════════════

func _on_interactable_entered(body: Node) -> void:
	if body.has_method("get_item_data") or body.has_method("can_receive_item") \
			or body.has_method("get_consumable_data"):
		nearby_interactable = body

func _on_interactable_exited(body: Node) -> void:
	if body == nearby_interactable:
		nearby_interactable = null

func _on_interactable_area_entered(area: Area2D) -> void:
	if area.has_method("get_item_data") or area.has_method("can_receive_item") \
			or area.has_method("get_consumable_data"):
		nearby_interactable = area

func _on_interactable_area_exited(area: Area2D) -> void:
	if area == nearby_interactable:
		nearby_interactable = null
