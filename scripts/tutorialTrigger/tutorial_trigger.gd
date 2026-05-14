extends Area2D

# ─────────────────────────────────────────────
#  TutorialTrigger
#
#  Scene structure:
#  TutorialTrigger (Area2D)
#  └─ CollisionShape2D    ← set to a large rectangle covering spawn area
#
#  Place this in the tutorial scene. When the player walks in,
#  it fires the conversation once, then disables itself.
# ─────────────────────────────────────────────

@export var trigger_once : bool = true   # fire only once

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	if trigger_once:
		_triggered = true

	var ui := get_tree().get_first_node_in_group("conversation_ui")
	if ui == null:
		push_warning("TutorialTrigger: no node in group 'conversation_ui' found.")
		return

	ui.start_conversation(_get_tutorial_pages(), "Mom")


func _get_tutorial_pages() -> Array[String]:
	return [
		# ── Story intro (3 pages) ──────────────────────────────────
		"Oh sweetie, you're finally awake! Today is a very special day...\n" + \
		"Mom has a lot of errands to run outside.",

		"While I'm gone, I need you to help keep the house tidy.\n" + \
		"Can you do that for me? I know you can!",

		"The house isn't going to clean itself — and between us,\n" + \
		"your little sister already made a mess in the living room. 😅",

		# ── Controls ──────────────────────────────────────────────
		"Let's start with the basics!\n\n" + \
		"[color=gold]Movement:[/color]  [W] Up   [S] Down   [A] Left   [D] Right\n" + \
		"Walk around the room to explore.",

		# ── HUD panels ────────────────────────────────────────────
		"See the panel on the [color=gold]upper-left[/color]?\n" + \
		"Those are your [color=gold]Stats[/color] — Health ♥, Energy ⚡, and Happiness ★.\n" + \
		"Keep them from hitting zero!",

		"The clock in the [color=gold]upper-center[/color] is your [color=gold]Timer[/color].\n" + \
		"Finish all tasks before time runs out, or something bad will happen... 👀",

		"On the [color=gold]upper-right[/color] is your [color=gold]Task List[/color].\n" + \
		"Each chore you complete gets checked off. Finish them all to win the level!",

		"At the [color=gold]bottom-center[/color] is your [color=gold]Inventory slot[/color].\n" + \
		"It shows whatever item you're currently holding.",

		# ── Interaction ───────────────────────────────────────────
		"Walk up to an item on the floor and press [color=gold][E][/color] to pick it up.\n" + \
		"Your inventory slot will light up when you're holding something.",

		# ── Pick up ───────────────────────────────────────────────
		"See that [color=gold]crumpled paper[/color] on the floor nearby?\n" + \
		"Walk over to it and press [color=gold][E][/color] to pick it up. Go ahead!",

		# ── Deliver ───────────────────────────────────────────────
		"Great! Now carry it to the [color=gold]trash bin[/color] and press [color=gold][E][/color] again\n" + \
		"to place it inside. That's how you complete a chore!",

		# ── Task list update ──────────────────────────────────────
		"Did you see that? The Task List updated — one chore [color=green]checked off ✓[/color]!\n" + \
		"That's how you know you're making progress.",

		# ── Wrap up ───────────────────────────────────────────────
		"You're all set! Remember:\n" + \
		"• Pick up items with [color=gold][E][/color]\n" + \
		"• Bring them to the right place and press [color=gold][E][/color]\n" + \
		"• Watch your Stats and Timer!\n\n" + \
		"Now go clean up this house. Mom's counting on you! 💪",
	]
