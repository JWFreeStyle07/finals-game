#extends Area2D
#
## ─────────────────────────────────────────────
##  TUNING — adjust these to feel right
## ─────────────────────────────────────────────
#const TRAVEL_SPEED  := 200.0   # px/sec while flying
#const SPIN_SPEED    := 35.0    # radians/sec — shuriken visual spin
#const DAMAGE        := 25.0    # damage per hit
#const SLOW_FACTOR   := 0.4     # player speed multiplier when hit
#const SLOW_DURATION := 3.0     # seconds the slow lasts
#const ARRIVE_DIST   := 1.0    # px — close enough to player to start returning
#const RETURN_DIST   := 5.0    # px — close enough to mom to deactivate
#
## ─────────────────────────────────────────────
##  STATE
## ─────────────────────────────────────────────
#enum Phase { IDLE, FLYING_OUT, RETURNING }
#var phase : Phase = Phase.IDLE
#
#var _fly_direction   : Vector2 = Vector2.ZERO  # locked at launch, never changes
#var target_player    : CharacterBody2D = null
#var mom_ref          : Node2D          = null
#var _hit_on_outward  : bool = false
#var _hit_on_return   : bool = false
#
#@onready var anim : AnimatedSprite2D = $AnimatedSprite2D
#
#
## ═════════════════════════════════════════════
##  LIFECYCLE
## ═════════════════════════════════════════════
#
#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
	#visible = false
#
#
## ═════════════════════════════════════════════
##  MAIN LOOP
## ═════════════════════════════════════════════
#
#func _physics_process(delta: float) -> void:
	#if phase == Phase.IDLE:
		#return
#
	## Spin the node visually like a shuriken every frame
	#rotation += SPIN_SPEED * delta
#
	#match phase:
		#Phase.FLYING_OUT:
			## Straight line — direction locked at launch, never changes
			#global_position += _fly_direction * TRAVEL_SPEED * delta
#
			## Begin return once close enough to player
			#if is_instance_valid(target_player):
				#if global_position.distance_to(target_player.global_position) < ARRIVE_DIST:
					#phase = Phase.RETURNING
			## Safety fallback: return if weapon flies too far with no contact
			#if global_position.distance_to(mom_ref.global_position) > 80.0:
				#phase = Phase.RETURNING
#
		#Phase.RETURNING:
			#if not is_instance_valid(mom_ref):
				#_deactivate()
				#return
#
			## Return straight toward mom's current position
			#var to_mom := (mom_ref.global_position - global_position).normalized()
			#global_position += to_mom * TRAVEL_SPEED * delta
#
			#if global_position.distance_to(mom_ref.global_position) < RETURN_DIST:
				#_deactivate()
				#mom_ref.on_weapon_returned()
#
#
## ═════════════════════════════════════════════
##  LAUNCH  (called by mom.gd)
## ═════════════════════════════════════════════
#
#func launch(player: CharacterBody2D, mom: Node2D) -> void:
	#target_player   = player
	#mom_ref         = mom
	#visible         = true
	#phase           = Phase.FLYING_OUT
	#_hit_on_outward = false
	#_hit_on_return  = false
#
	## Start at ThrowPoint
	#global_position = mom_ref.get_node("ThrowPoint").global_position
#
	## Lock direction at the moment of launch — straight line forever
	#_fly_direction  = (target_player.global_position - global_position).normalized()
#
	## Play spin animation if available — rotation handles spin otherwise
	#if anim.sprite_frames and anim.sprite_frames.has_animation("spin"):
		#anim.play("spin")
#
#
## ═════════════════════════════════════════════
##  HIT DETECTION
## ═════════════════════════════════════════════
#
#func _on_body_entered(body: Node) -> void:
	#if not body.is_in_group("player"):
		#return
#
	#if phase == Phase.FLYING_OUT and not _hit_on_outward:
		#_hit_on_outward = true
		#_apply_hit(body)
		## Return immediately after hitting player on the way out
		#phase = Phase.RETURNING
#
	#elif phase == Phase.RETURNING and not _hit_on_return:
		#_hit_on_return = true
		#_apply_hit(body)
#
#
#func _apply_hit(player: CharacterBody2D) -> void:
	#player.take_damage(DAMAGE)
	#_apply_slow(player)
#
#
#func _apply_slow(player: CharacterBody2D) -> void:
	#if player.get("_slow_timer_active"):
		#return
#
	#player.set("_slow_timer_active", true)
	#player.set("_original_move_speed", player.MOVE_SPEED)
	#player.set("_current_move_speed",  player.MOVE_SPEED * SLOW_FACTOR)
#
	#get_tree().create_timer(SLOW_DURATION).timeout.connect(
		#func() -> void:
			#if is_instance_valid(player):
				#player.set("_current_move_speed", player.MOVE_SPEED)
				#player.set("_slow_timer_active",  false)
	#)
#
#
## ═════════════════════════════════════════════
##  DEACTIVATE
## ═════════════════════════════════════════════
#
#func _deactivate() -> void:
	#phase    = Phase.IDLE
	#visible  = false
	#rotation = 0.0
extends Area2D

# ─────────────────────────────────────────────
#  TUNING
# ─────────────────────────────────────────────
const TRAVEL_SPEED  := 500.0
const SPIN_SPEED    := 1.0
const DAMAGE        := 25.0
const SLOW_FACTOR   := 0.4
const SLOW_DURATION := 1.0
const ARRIVE_DIST   := 1.0
const RETURN_DIST   := 5.0

# ── New orbit tuning ──
const ORBIT_RADIUS  := 1.0    # px — how tight the circle is around Mom
const ORBIT_SPEED   := 2.0     # radians/sec — how fast it orbits
const ORBIT_DURATION := 0.5    # seconds of orbiting before flying out

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
enum Phase { IDLE, ORBITING, FLYING_OUT, RETURNING }  # ← added ORBITING
var phase : Phase = Phase.IDLE

var _fly_direction   : Vector2 = Vector2.ZERO
var target_player    : CharacterBody2D = null
var mom_ref          : Node2D          = null
var _hit_on_outward  : bool = false
var _hit_on_return   : bool = false

# ── New orbit state ──
var _orbit_angle  : float = 0.0   # current angle around Mom
var _orbit_timer  : float = 0.0   # counts up to ORBIT_DURATION

@onready var anim : AnimatedSprite2D = $AnimatedSprite2D


# ═════════════════════════════════════════════
#  LIFECYCLE
# ═════════════════════════════════════════════

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	visible = false


# ═════════════════════════════════════════════
#  MAIN LOOP
# ═════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if phase == Phase.IDLE:
		return

	rotation += SPIN_SPEED * delta

	match phase:
		Phase.ORBITING:
			_do_orbit(delta)

		Phase.FLYING_OUT:
			global_position += _fly_direction * TRAVEL_SPEED * delta

			if is_instance_valid(target_player):
				if global_position.distance_to(target_player.global_position) < ARRIVE_DIST:
					phase = Phase.RETURNING
			if global_position.distance_to(mom_ref.global_position) > 800.0:
				phase = Phase.RETURNING

		Phase.RETURNING:
			if not is_instance_valid(mom_ref):
				_deactivate()
				return

			var to_mom := (mom_ref.global_position - global_position).normalized()
			global_position += to_mom * TRAVEL_SPEED * delta

			if global_position.distance_to(mom_ref.global_position) < RETURN_DIST:
				_deactivate()
				mom_ref.on_weapon_returned()


# ─────────────────────────────────────────────
#  ORBIT LOGIC
# ─────────────────────────────────────────────

func _do_orbit(delta: float) -> void:
	_orbit_timer += delta
	_orbit_angle  += ORBIT_SPEED * delta

	# Circle around Mom's position
	global_position = mom_ref.global_position + Vector2(
		cos(_orbit_angle) * ORBIT_RADIUS,
		sin(_orbit_angle) * ORBIT_RADIUS
	)

	# After orbiting long enough, lock direction and fly out
	if _orbit_timer >= ORBIT_DURATION:
		_fly_direction = (target_player.global_position - global_position).normalized()
		phase = Phase.FLYING_OUT


# ═════════════════════════════════════════════
#  LAUNCH  (called by mom.gd)
# ═════════════════════════════════════════════

func launch(player: CharacterBody2D, mom: Node2D) -> void:
	target_player   = player
	mom_ref         = mom
	visible         = true
	_hit_on_outward = false
	_hit_on_return  = false

	# ── Start orbiting instead of flying immediately ──
	_orbit_angle  = 0.0
	_orbit_timer  = 0.0
	phase         = Phase.ORBITING

	global_position = mom_ref.global_position + Vector2(ORBIT_RADIUS, -1)

	if anim.sprite_frames and anim.sprite_frames.has_animation("spin"):
		anim.play("spin")


# ═════════════════════════════════════════════
#  HIT DETECTION
# ═════════════════════════════════════════════

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if phase == Phase.FLYING_OUT and not _hit_on_outward:
		_hit_on_outward = true
		_apply_hit(body)
		phase = Phase.RETURNING

	elif phase == Phase.RETURNING and not _hit_on_return:
		_hit_on_return = true
		_apply_hit(body)


func _apply_hit(player: CharacterBody2D) -> void:
	player.take_damage(DAMAGE)
	_apply_slow(player)


func _apply_slow(player: CharacterBody2D) -> void:
	if player.get("_slow_timer_active"):
		return

	player.set("_slow_timer_active", true)
	player.set("_original_move_speed", player.MOVE_SPEED)
	player.set("_current_move_speed",  player.MOVE_SPEED * SLOW_FACTOR)

	get_tree().create_timer(SLOW_DURATION).timeout.connect(
		func() -> void:
			if is_instance_valid(player):
				player.set("_current_move_speed", player.MOVE_SPEED)
				player.set("_slow_timer_active",  false)
	)


# ═════════════════════════════════════════════
#  DEACTIVATE
# ═════════════════════════════════════════════

func _deactivate() -> void:
	phase    = Phase.IDLE
	visible  = false
	rotation = 0.0
