extends StaticBody2D

# ═══════════════════════════════════════════════════════════════════
#  PICKUP ITEM — CrumpledPaper, Toy, Dish, Clothes, Vegetables…
#
#  Scene structure:
#    PickupItem (StaticBody2D)
#    ├── Sprite2D
#    ├── CollisionShape2D
#    ├── InteractZone (Area2D)
#    │   └── CollisionShape2D
#    └── PromptLabel (Label)       "[E] Pick up"
#
#  Fill in item_id, item_name, item_icon in the Inspector.
#  item_id MUST match the "item_id" field in GameManager tasks.
# ═══════════════════════════════════════════════════════════════════

@export var item_id   : String = "crumpled_paper"
@export var item_name : String = "Crumpled Paper"
@export var item_icon : String = "🗒️"   # emoji shown in inventory slot

@onready var interact_zone : Area2D = $InteractZone
@onready var prompt_label  : Label  = $PromptLabel

var _is_picked_up := false


func _ready() -> void:
	prompt_label.visible = false
	interact_zone.body_entered.connect(_on_body_entered)
	interact_zone.body_exited.connect(_on_body_exited)
	add_to_group("pickup_item")


## Called by Player._try_interact() — returns item data Dictionary
func get_item_data() -> Dictionary:
	return {
		"id"  : item_id,
		"name": item_name,
		"icon": item_icon,
	}


## Called by Player after pickup — hide the item from the world
func on_picked_up(_hold_point: Marker2D) -> void:
	_is_picked_up = true
	hide()
	# Disable collision so it doesn't block movement while held
	$CollisionShape2D.set_deferred("disabled", true)
	$InteractZone/CollisionShape2D.set_deferred("disabled", true)
	prompt_label.visible = false


## Re-show the item if the player drops it without placing it
## Call this from Player if you add a "drop" action later
func on_dropped(drop_position: Vector2) -> void:
	_is_picked_up = false
	global_position = drop_position
	show()
	$CollisionShape2D.set_deferred("disabled", false)
	$InteractZone/CollisionShape2D.set_deferred("disabled", false)


func _on_body_entered(body: Node) -> void:
	if not _is_picked_up and body.is_in_group("player"):
		prompt_label.visible = true
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(true, "[E] Pick up " + item_name)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(false)
