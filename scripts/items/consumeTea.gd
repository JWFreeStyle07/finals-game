extends StaticBody2D

# ═══════════════════════════════════════════════════════════════════
#  CONSUMABLE ITEM — Apple (energy), Toy/Music (happiness)…
#
#  Scene structure:
#    ConsumableItem (StaticBody2D)
#    ├── Sprite2D
#    ├── CollisionShape2D
#    ├── InteractZone (Area2D)
#    │   └── CollisionShape2D
#    └── PromptLabel (Label)   "[E] Eat Apple"
#
#  The player calls get_consumable_data() then on_consumed().
#  Set the restore values in the Inspector per item.
# ═══════════════════════════════════════════════════════════════════

@export var item_name          : String = "Apple"
@export var consume_prompt     : String = "[E] Eat"
@export var energy_restore     : float  = 30.0
@export var health_restore     : float  = 0.0
@export var happiness_restore  : float  = 0.0

@onready var interact_zone : Area2D = $InteractZone
@onready var prompt_label  : Label  = $PromptLabel


func _ready() -> void:
	prompt_label.visible = false
	interact_zone.body_entered.connect(_on_body_entered)
	interact_zone.body_exited.connect(_on_body_exited)


## Called by Player._consume()
func get_consumable_data() -> Dictionary:
	return {
		"label"              : item_name,
		"energy_restore"     : energy_restore,
		"health_restore"     : health_restore,
		"happiness_restore"  : happiness_restore,
	}


## Called by Player after consuming — hide the item
func on_consumed() -> void:
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractZone/CollisionShape2D.set_deferred("disabled", true)
	prompt_label.visible = false
	# Optional: respawn after a delay
	# await get_tree().create_timer(30.0).timeout
	# show(); $CollisionShape2D.set_deferred("disabled", false)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = true
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(true, consume_prompt + " " + item_name)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(false)
