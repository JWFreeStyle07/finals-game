extends StaticBody2D

# ═══════════════════════════════════════════════════════════════════
#  RECEIVER OBJECT — TrashBin, ToyBox, LaundryBasket, Pan, Sink…
#
#  Scene structure:
#    ReceiverObject (StaticBody2D)
#    ├── Sprite2D
#    ├── CollisionShape2D          ← physical body (blocks movement)
#    ├── InteractZone (Area2D)     ← slightly bigger, detects player
#    │   └── CollisionShape2D
#    └── PromptLabel (Label)       ← "[E] Place item here"
#
#  Set receiver_id in the Inspector to match the task's "receiver_id".
#  e.g. "trash_bin", "toy_box", "laundry_basket", "cooking_pan", "kitchen_sink"
# ═══════════════════════════════════════════════════════════════════

## Must match the "receiver_id" field in GameManager tasks
@export var receiver_id : String = "trash_bin"

## Which item IDs this receiver accepts (leave empty to accept anything)
@export var accepted_item_ids : Array[String] = []

@onready var interact_zone  : Area2D = $InteractZone
@onready var prompt_label   : Label  = $PromptLabel

func _ready() -> void:
	prompt_label.visible = false
	interact_zone.body_entered.connect(_on_body_entered)
	interact_zone.body_exited.connect(_on_body_exited)


## Called by Player._try_interact() to check if it can accept the held item
func can_receive_item(item: Dictionary) -> bool:
	if accepted_item_ids.is_empty():
		return true   # accepts anything
	return item.get("id", "") in accepted_item_ids


## Called by Player._place_item() after can_receive_item() returns true
func receive_item(item: Dictionary) -> void:
	# Notify GameManager so it can mark the task complete
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		gm.try_complete_task(item.get("id", ""), receiver_id)

	# Visual feedback — you can swap this for an animation
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	# Update prompt
	prompt_label.visible = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = true
		# Tell HUD to show the interact prompt too
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(true, "[E] Place item here")


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		prompt_label.visible = false
		var hud = get_tree().get_first_node_in_group("hud")
		if hud:
			hud.show_interact_prompt(false)
