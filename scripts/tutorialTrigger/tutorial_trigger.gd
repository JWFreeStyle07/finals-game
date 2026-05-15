extends Area2D

@export var trigger_once     : bool      = true
@export var sign_node_path   : NodePath
@export var triggered_texture: Texture2D

var _triggered := false
var _sign      : Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sign_node_path:
		_sign = get_node(sign_node_path)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	if trigger_once:
		_triggered = true

	# ── Hide the bobbing sign immediately ────────
	if _sign:
		_sign.hide_sign()

	# ── Swap the trigger Area2D's sprite ─────────
	var spr := get_node_or_null("Sprite2D")
	if spr and triggered_texture:
		spr.texture = triggered_texture

	# ── Start conversation ───────────────────────
	var ui := get_tree().get_first_node_in_group("conversation_ui")
	if ui == null:
		push_warning("TutorialTrigger: no node in group 'conversation_ui' found.")
		return

	ui.start_conversation(_get_tutorial_pages(), "Tilapia sa Lagayan ng Ice Cream")


func _get_tutorial_pages() -> Array[String]:
	return [
		"Kala mo ice cream no. Ako lang to, tilapia",

		"Like is this tagaleg?.\n" + \
		"blub.",

		"eme bilisan mo!,\n" + \
		"baka mahuli ka ng mama mo!! ⚠️👸🏻\nblub.",

		"Hindi ka marunong maglakad? Pindot pindot lang yan\n" + \
		"[color=gold]Movement:[/color]  [W] Up   [S] Down   [A] Left   [D] Right\n",

		"Kita mo yung nasa taas kaliwa\n" + \
		"[color=gold]Stats[/color] mo yan! — Health ♥, Energy ⚡, and Happiness ★.\n" + \
		"Bawal bumaba sa zero yan, ☠️ ka!",

		"Kain ka ng 🍎 at inom ng 🍵 para tumaas energy.\nKusa yang nababawasan pag naglalakad ka!",

		"Kita mo yang [color=gold]Timer[/color] sa taas?\n" + \
		"Kailangan mong matapos mga task bago mag 0! Papaluin ka sige! 👀",

		"Pag napalo ka, mababawasan health mo! 💔💔💔",

		"Kita mo yang [color=gold]Task List[/color] sa taas kanan?.\n" + \
		"Basahin mo para alam mo gagawin di ba? 🎯",

		"Bawal ang walang ginagawa, automatic na bumababa ang happiness. \nTataas lang yan pag may nagawa kang task!!!",

		"May [color=gold]Inventory slot[/color] din sa baba.\n" + \
		"Jan nakikita ang hawak mo! 💼",

		"Di mo alam pumulot? Press [color=gold][E][/color] lang. Simple!!!\n" + \
		"Mapupunta yan sa inventory mo.",

		"Nakikita mo yang [color=gold]kalat[/color] on the floor?\n" + \
		"Walk over to it, pindot [color=gold][E][/color] Tapos . . .",

		"Lagay mo yan sa [color=gold]trash bin[/color] sa tabi ng ref, tapos pindot [color=gold][E][/color] again\n" + \
		"Ganun lang kasimple maglinis ng bahay, tamad ka kasi!!!",

		"Pagkatapos, makikita mo na nag-update ung task list. [color=green]checked off ✓[/color]!\n" + \
		"Kailangan magawa mo lahat yan, bawal tamad. 😡",

		"May tanong pa? \n" + \
		"Bilisan mo mapapalo ka! 🩴🩴🩴",
	]
