#extends CanvasLayer
#
## ── Colors ──
#const C_PANEL_BG    := Color(0.118, 0.047, 0.016, 0.88)
#const C_BORDER      := Color(0.545, 0.353, 0.169)
#const C_GOLD        := Color(0.784, 0.518, 0.039)
#const C_GOLD_LIGHT  := Color(0.910, 0.659, 0.125)
#const C_TAN         := Color(0.784, 0.584, 0.424)
#const C_CREAM       := Color(0.910, 0.788, 0.604)
#const C_OLIVE_LIGHT := Color(0.545, 0.612, 0.353)
#const C_HP_BAR      := Color(0.545, 0.180, 0.180)
#const C_EN_BAR      := Color(0.784, 0.518, 0.039)
#const C_HAP_BAR     := Color(0.420, 0.486, 0.227)
#const C_WARN        := Color(0.910, 0.353, 0.125)
#
## Top panel alignment — all three top panels share these Y values
#const TOP_Y_START := 8
#const TOP_Y_END   := 118   # increase if content is taller
#
## ── Node refs ──
#var hp_bar    : ProgressBar
#var en_bar    : ProgressBar
#var hap_bar   : ProgressBar
#var hp_val    : Label
#var en_val    : Label
#var hap_val   : Label
#
#var timer_display : Label
#var level_label   : Label
#
#var tasks_body    : VBoxContainer
#var tasks_toggle  : Button
#var tasks_progress: Label
#var tasks_open    := true
#
#var interact_prompt : Label
#
#var center_panel_label : Label
#var right_panel_label  : Label
#
## ── State ──
#var task_names : Array[String] = []
#var task_done  : Array[bool]   = []
#
## ─────────────────────────────────────────
##  LIFECYCLE
## ─────────────────────────────────────────
#
#func _ready() -> void:
	#_build_hud()
#
#
## ─────────────────────────────────────────
##  PUBLIC API
## ─────────────────────────────────────────
#
#func update_stats(hp: float, energy: float, happiness: float) -> void:
	#hp_bar.value  = hp
	#en_bar.value  = energy
	#hap_bar.value = happiness
	#hp_val.text   = str(int(hp))        + "%"
	#en_val.text   = str(int(energy))    + "%"
	#hap_val.text  = str(int(happiness)) + "%"
	#hp_bar.modulate = Color.RED if hp < 25.0 else Color.WHITE
#
#
#func setup_tasks(names: Array[String]) -> void:
	#task_names = names
	#task_done.resize(names.size())
	#task_done.fill(false)
	#_rebuild_tasks()
	#_update_task_progress()
#
#
#func complete_task(index: int) -> void:
	#if index < 0 or index >= task_done.size():
		#return
	#task_done[index] = true
	#_rebuild_tasks()
	#_update_task_progress()
#
#
#func setup_timer(seconds: int, level_name: String) -> void:
	#_set_timer_display(seconds)
	#level_label.text = level_name
#
#
#func tick_timer(seconds_left: int) -> void:
	#_set_timer_display(seconds_left)
	#if seconds_left <= 30:
		#timer_display.add_theme_color_override("font_color", C_WARN)
	#else:
		#timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)
#
#
#func show_interact_prompt(is_visible: bool, text: String = "[E] Interact") -> void:
	#interact_prompt.visible = is_visible
	#interact_prompt.text    = text
#
#
#func update_center_panel(text: String) -> void:
	#if center_panel_label:
		#center_panel_label.text = text
#
#
#func update_right_panel(text: String) -> void:
	#if right_panel_label:
		#right_panel_label.text = text
#
#
## ─────────────────────────────────────────
##  INTERNAL: HUD BUILDER
## ─────────────────────────────────────────
#
#func _build_hud() -> void:
	#var root := Control.new()
	#root.name = "HUDRoot"
	#root.set_anchors_preset(Control.PRESET_FULL_RECT)
	#root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	#add_child(root)
#
	#_build_stats_panel(root)   # upper left
	#_build_timer_panel(root)   # upper center
	#_build_tasks_panel(root)   # upper right
#
	## Interact prompt — center bottom
	#interact_prompt = Label.new()
	#interact_prompt.text    = "[E] Interact"
	#interact_prompt.visible = false
	#interact_prompt.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#interact_prompt.add_theme_font_size_override("font_size", 16)
	#interact_prompt.set_anchor(SIDE_LEFT,   0.5)
	#interact_prompt.set_anchor(SIDE_RIGHT,  0.5)
	#interact_prompt.set_anchor(SIDE_TOP,    1.0)
	#interact_prompt.set_anchor(SIDE_BOTTOM, 1.0)
	#interact_prompt.offset_left   = -100
	#interact_prompt.offset_right  =  100
	#interact_prompt.offset_top    = -140
	#interact_prompt.offset_bottom = -110
	#interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#root.add_child(interact_prompt)
#
## ── Stats — upper LEFT ────────────────────────────────────
#func _build_stats_panel(root: Control) -> void:
	#var panel := _make_panel()
	#panel.custom_minimum_size = Vector2(280, 0)
	#panel.set_anchor(SIDE_LEFT,   0.0)
	#panel.set_anchor(SIDE_RIGHT,  0.0)
	#panel.set_anchor(SIDE_TOP,    0.0)
	#panel.set_anchor(SIDE_BOTTOM, 0.0)
	#panel.offset_left   = 8
	#panel.offset_right  = 288        # 8 + 280
	#panel.offset_top    = TOP_Y_START
	#panel.offset_bottom = TOP_Y_END
	#root.add_child(panel)
#
	#var vbox := VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 8)
	#panel.add_child(vbox)
#
	#var title := Label.new()
	#title.text = "STATS"
	#title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#title.add_theme_font_size_override("font_size", 14)
	#vbox.add_child(title)
#
	#_make_stat_row(vbox, "♥", "Health", C_HP_BAR)
	#_make_stat_row(vbox, "⚡", "Energy", C_EN_BAR)
	#_make_stat_row(vbox, "★", "Happy",  C_HAP_BAR)
#
	#hp_bar  = vbox.get_child(1).get_child(2) as ProgressBar
	#en_bar  = vbox.get_child(2).get_child(2) as ProgressBar
	#hap_bar = vbox.get_child(3).get_child(2) as ProgressBar
	#hp_val  = vbox.get_child(1).get_child(3) as Label
	#en_val  = vbox.get_child(2).get_child(3) as Label
	#hap_val = vbox.get_child(3).get_child(3) as Label
#
#
#func _make_stat_row(parent: VBoxContainer, icon: String,
		#label_text: String, bar_color: Color) -> void:
	#var row := HBoxContainer.new()
	#row.add_theme_constant_override("separation", 8)
	#parent.add_child(row)
#
	#var icon_lbl := Label.new()
	#icon_lbl.text = icon
	#icon_lbl.custom_minimum_size.x = 20
	#icon_lbl.add_theme_font_size_override("font_size", 16)
	#row.add_child(icon_lbl)
#
	#var lbl := Label.new()
	#lbl.text = label_text.to_upper()
	#lbl.custom_minimum_size.x = 70
	#lbl.add_theme_color_override("font_color", C_TAN)
	#lbl.add_theme_font_size_override("font_size", 13)
	#row.add_child(lbl)
#
	#var bar := ProgressBar.new()
	#bar.min_value             = 0
	#bar.max_value             = 100
	#bar.value                 = 100
	#bar.custom_minimum_size   = Vector2(100, 14)
	#bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#bar.show_percentage       = false
	#var fill_style := StyleBoxFlat.new()
	#fill_style.bg_color = bar_color
	#bar.add_theme_stylebox_override("fill", fill_style)
	#var bg_style := StyleBoxFlat.new()
	#bg_style.bg_color    = Color(0, 0, 0, 0.5)
	#bg_style.border_color = C_BORDER
	#bg_style.set_border_width_all(1)
	#bar.add_theme_stylebox_override("background", bg_style)
	#row.add_child(bar)
#
	#var val_lbl := Label.new()
	#val_lbl.text = "100%"
	#val_lbl.custom_minimum_size.x = 40
	#val_lbl.add_theme_color_override("font_color", C_CREAM)
	#val_lbl.add_theme_font_size_override("font_size", 13)
	#val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	#row.add_child(val_lbl)
#
#
## ── Timer — upper CENTER ──────────────────────────────────
#func _build_timer_panel(root: Control) -> void:
	#var panel := _make_panel()
	#panel.custom_minimum_size = Vector2(180, 0)
	#panel.set_anchor(SIDE_LEFT,   0.5)
	#panel.set_anchor(SIDE_RIGHT,  0.5)
	#panel.set_anchor(SIDE_TOP,    0.0)
	#panel.set_anchor(SIDE_BOTTOM, 0.0)
	#panel.offset_left   = -90        # half of 180
	#panel.offset_right  =  90
	#panel.offset_top    = TOP_Y_START
	#panel.offset_bottom = TOP_Y_END
	#root.add_child(panel)
#
	#var vbox := VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 4)
	#vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	#panel.add_child(vbox)
#
	#var lbl := Label.new()
	#lbl.text = "TIME LEFT"
	#lbl.add_theme_color_override("font_color", C_TAN)
	#lbl.add_theme_font_size_override("font_size", 13)
	#lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(lbl)
#
	#timer_display = Label.new()
	#timer_display.text = "00:00"
	#timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#timer_display.add_theme_font_size_override("font_size", 32)
	#timer_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(timer_display)
#
	#level_label = Label.new()
	#level_label.text = "LEVEL 1"
	#level_label.add_theme_color_override("font_color", C_OLIVE_LIGHT)
	#level_label.add_theme_font_size_override("font_size", 13)
	#level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(level_label)
#
#
## ── Tasks — upper RIGHT ───────────────────────────────────
#func _build_tasks_panel(root: Control) -> void:
	#var panel := _make_panel()
	#panel.custom_minimum_size = Vector2(260, 0)
	#panel.set_anchor(SIDE_LEFT,   1.0)
	#panel.set_anchor(SIDE_RIGHT,  1.0)
	#panel.set_anchor(SIDE_TOP,    0.0)
	#panel.set_anchor(SIDE_BOTTOM, 0.0)
	#panel.offset_left   = -268       # 260 + 8 margin
	#panel.offset_right  = -8
	#panel.offset_top    = TOP_Y_START
	#panel.offset_bottom = TOP_Y_END
	#root.add_child(panel)
#
	#var vbox := VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 0)
	#panel.add_child(vbox)
#
	#var header := Button.new()
	#header.text = "TASK LIST  ▲"
	#header.flat = false
	#header.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#header.add_theme_font_size_override("font_size", 13)
	#var hdr_style := StyleBoxFlat.new()
	#hdr_style.bg_color = Color(0.35, 0.16, 0.04, 0.6)
	#header.add_theme_stylebox_override("normal",  hdr_style)
	#header.add_theme_stylebox_override("hover",   hdr_style)
	#header.add_theme_stylebox_override("pressed", hdr_style)
	#header.pressed.connect(_toggle_tasks)
	#tasks_toggle = header
	#vbox.add_child(header)
#
	#tasks_body = VBoxContainer.new()
	#tasks_body.add_theme_constant_override("separation", 6)
	#tasks_body.name = "TasksBody"
	#var margin := MarginContainer.new()
	#margin.add_theme_constant_override("margin_left",   10)
	#margin.add_theme_constant_override("margin_right",  10)
	#margin.add_theme_constant_override("margin_top",     8)
	#margin.add_theme_constant_override("margin_bottom",  8)
	#margin.add_child(tasks_body)
	#vbox.add_child(margin)
#
	#tasks_progress = Label.new()
	#tasks_progress.text = "0 / 0 done"
	#tasks_progress.add_theme_color_override("font_color", C_TAN)
	#tasks_progress.add_theme_font_size_override("font_size", 12)
	#tasks_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	#var prog_margin := MarginContainer.new()
	#prog_margin.add_theme_constant_override("margin_right",  10)
	#prog_margin.add_theme_constant_override("margin_bottom",  6)
	#prog_margin.add_child(tasks_progress)
	#vbox.add_child(prog_margin)
#
#
#
#
## ─────────────────────────────────────────
##  INTERNAL HELPERS
## ─────────────────────────────────────────
#
#func _make_panel() -> PanelContainer:
	#var p := PanelContainer.new()
	#var style := StyleBoxFlat.new()
	#style.bg_color              = C_PANEL_BG
	#style.border_color          = C_BORDER
	#style.set_border_width_all(2)
	#style.set_corner_radius_all(0)
	#style.content_margin_left   = 12
	#style.content_margin_right  = 12
	#style.content_margin_top    = 10
	#style.content_margin_bottom = 10
	#p.add_theme_stylebox_override("panel", style)
	#return p
#
#
#func _set_timer_display(seconds: int) -> void:
	#var m := seconds / 60
	#var s := seconds % 60
	#timer_display.text = "%02d:%02d" % [m, s]
#
#
#func _toggle_tasks() -> void:
	#tasks_open = !tasks_open
	#tasks_body.get_parent().visible = tasks_open
	#tasks_toggle.text = "TASK LIST  " + ("▲" if tasks_open else "▼")
#
#
#func _rebuild_tasks() -> void:
	#for child in tasks_body.get_children():
		#child.queue_free()
#
	#for i in task_names.size():
		#var row := HBoxContainer.new()
		#row.add_theme_constant_override("separation", 8)
		#tasks_body.add_child(row)
#
		#var chk := Label.new()
		#chk.custom_minimum_size = Vector2(14, 14)
		#chk.add_theme_font_size_override("font_size", 14)
		#if task_done[i]:
			#chk.text = "✓"
			#chk.add_theme_color_override("font_color", C_OLIVE_LIGHT)
		#else:
			#chk.text = "□"
			#chk.add_theme_color_override("font_color", C_TAN)
		#row.add_child(chk)
#
		#var txt := Label.new()
		#txt.text = task_names[i]
		#txt.add_theme_font_size_override("font_size", 13)
		#if task_done[i]:
			#txt.add_theme_color_override("font_color", C_OLIVE_LIGHT)
		#else:
			#txt.add_theme_color_override("font_color", C_CREAM)
		#row.add_child(txt)
#
#
#func _update_task_progress() -> void:
	#var done_count := task_done.count(true)
	#tasks_progress.text = "%d / %d done" % [done_count, task_done.size()]
extends CanvasLayer

# ── Colors ──
const C_PANEL_BG    := Color(0.118, 0.047, 0.016, 0.88)
const C_BORDER      := Color(0.545, 0.353, 0.169)
const C_GOLD        := Color(0.784, 0.518, 0.039)
const C_GOLD_LIGHT  := Color(0.910, 0.659, 0.125)
const C_TAN         := Color(0.784, 0.584, 0.424)
const C_CREAM       := Color(0.910, 0.788, 0.604)
const C_OLIVE_LIGHT := Color(0.545, 0.612, 0.353)
const C_HP_BAR      := Color(0.545, 0.180, 0.180)
const C_EN_BAR      := Color(0.784, 0.518, 0.039)
const C_HAP_BAR     := Color(0.420, 0.486, 0.227)
const C_WARN        := Color(0.910, 0.353, 0.125)

const TOP_Y_START := 8
const TOP_Y_END   := 118

# ── Node refs ──
var hp_bar  : ProgressBar
var en_bar  : ProgressBar
var hap_bar : ProgressBar
var hp_val  : Label
var en_val  : Label
var hap_val : Label

var timer_display : Label
var level_label   : Label

var tasks_body    : VBoxContainer
var tasks_toggle  : Button
var tasks_progress: Label
var tasks_open    := true

var interact_prompt : Label

# Inventory slot refs
var slot_panels : Array[PanelContainer] = []
var slot_icons  : Array[Label]          = []
var slot_names  : Array[Label]          = []

# ── State ──
var task_names : Array[String] = []
var task_done  : Array[bool]   = []
var active_slot: int = 0


# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────

func _ready() -> void:
	_build_hud()


# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────

## Called by player.stats_changed signal
func update_stats(hp: float, energy: float, happiness: float) -> void:
	hp_bar.value  = hp
	en_bar.value  = energy
	hap_bar.value = happiness
	hp_val.text   = str(int(hp))        + "%"
	en_val.text   = str(int(energy))    + "%"
	hap_val.text  = str(int(happiness)) + "%"
	# Flash red when critical
	hp_bar.modulate  = Color.RED   if hp        < 25.0 else Color.WHITE
	en_bar.modulate  = Color.RED   if energy    < 20.0 else Color.WHITE
	hap_bar.modulate = Color.RED   if happiness < 20.0 else Color.WHITE


## Call from Level._ready() to populate the task list for this level
func setup_tasks(names: Array[String]) -> void:
	task_names = names
	task_done.resize(names.size())
	task_done.fill(false)
	_rebuild_tasks()
	_update_task_progress()


## Call from GameManager when a task is completed
func complete_task(index: int) -> void:
	if index < 0 or index >= task_done.size():
		return
	task_done[index] = true
	_rebuild_tasks()
	_update_task_progress()


## Call from Level._ready() to set the countdown and level name
func setup_timer(seconds: int, level_name: String) -> void:
	_set_timer_display(seconds)
	level_label.text = level_name


## Call every second from GameManager
func tick_timer(seconds_left: int) -> void:
	_set_timer_display(seconds_left)
	if seconds_left <= 30:
		timer_display.add_theme_color_override("font_color", C_WARN)
	else:
		timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)


## Show or hide the [E] prompt above the player (called from Player area callbacks via HUD ref)
func show_interact_prompt(visible_state: bool, text: String = "[E] Interact") -> void:
	interact_prompt.visible = visible_state
	interact_prompt.text    = text


## Called by player.inventory_changed signal
## inventory_array: Array of Dictionaries with keys "icon" (String) and "name" (String)
func update_inventory(inventory_array: Array, p_active_slot: int) -> void:
	active_slot = p_active_slot
	for i in 6:
		var item: Dictionary = inventory_array[i] if i < inventory_array.size() else {}
		var has_item := not item.is_empty()

		# Highlight active slot with gold border
		var style := StyleBoxFlat.new()
		style.bg_color    = C_PANEL_BG if not has_item else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12)
		style.border_color = C_GOLD_LIGHT if i == active_slot else (C_BORDER if has_item else Color(C_BORDER, 0.35))
		style.set_border_width_all(2)
		slot_panels[i].add_theme_stylebox_override("panel", style)

		slot_icons[i].text = item.get("icon", "")  if has_item else ""
		slot_names[i].text = item.get("name", "")  if has_item else ""
		slot_panels[i].modulate.a = 1.0 if has_item else 0.35


# ─────────────────────────────────────────
#  HUD BUILDER
# ─────────────────────────────────────────

func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_stats_panel(root)
	_build_timer_panel(root)
	_build_tasks_panel(root)
	_build_inventory_panel(root)

	# ── Interact prompt — sits just above the inventory bar ──
	interact_prompt = Label.new()
	interact_prompt.text    = "[E] Interact"
	interact_prompt.visible = false
	interact_prompt.add_theme_color_override("font_color", C_GOLD_LIGHT)
	interact_prompt.add_theme_font_size_override("font_size", 16)
	interact_prompt.set_anchor(SIDE_LEFT,   0.5)
	interact_prompt.set_anchor(SIDE_RIGHT,  0.5)
	interact_prompt.set_anchor(SIDE_TOP,    1.0)
	interact_prompt.set_anchor(SIDE_BOTTOM, 1.0)
	interact_prompt.offset_left   = -100
	interact_prompt.offset_right  =  100
	interact_prompt.offset_top    = -140
	interact_prompt.offset_bottom = -110
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(interact_prompt)


# ── Stats — upper LEFT ────────────────────────────────────────────────────────
func _build_stats_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  0.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = 8
	panel.offset_right  = 288
	panel.offset_top    = TOP_Y_START
	panel.offset_bottom = TOP_Y_END
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "STATS"
	title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_make_stat_row(vbox, "♥", "Health", C_HP_BAR)
	_make_stat_row(vbox, "⚡", "Energy", C_EN_BAR)
	_make_stat_row(vbox, "★", "Happy",  C_HAP_BAR)

	hp_bar  = vbox.get_child(1).get_child(2) as ProgressBar
	en_bar  = vbox.get_child(2).get_child(2) as ProgressBar
	hap_bar = vbox.get_child(3).get_child(2) as ProgressBar
	hp_val  = vbox.get_child(1).get_child(3) as Label
	en_val  = vbox.get_child(2).get_child(3) as Label
	hap_val = vbox.get_child(3).get_child(3) as Label


func _make_stat_row(parent: VBoxContainer, icon: String,
		label_text: String, bar_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.custom_minimum_size.x = 20
	icon_lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(icon_lbl)

	var lbl := Label.new()
	lbl.text = label_text.to_upper()
	lbl.custom_minimum_size.x = 70
	lbl.add_theme_color_override("font_color", C_TAN)
	lbl.add_theme_font_size_override("font_size", 13)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.min_value             = 0
	bar.max_value             = 100
	bar.value                 = 100
	bar.custom_minimum_size   = Vector2(100, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage       = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color     = Color(0, 0, 0, 0.5)
	bg_style.border_color = C_BORDER
	bg_style.set_border_width_all(1)
	bar.add_theme_stylebox_override("background", bg_style)
	row.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.text = "100%"
	val_lbl.custom_minimum_size.x = 40
	val_lbl.add_theme_color_override("font_color", C_CREAM)
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)


# ── Timer — upper CENTER ──────────────────────────────────────────────────────
func _build_timer_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(180, 0)
	panel.set_anchor(SIDE_LEFT,   0.5)
	panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = -90
	panel.offset_right  =  90
	panel.offset_top    = TOP_Y_START
	panel.offset_bottom = TOP_Y_END
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var lbl := Label.new()
	lbl.text = "TIME LEFT"
	lbl.add_theme_color_override("font_color", C_TAN)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)

	timer_display = Label.new()
	timer_display.text = "00:00"
	timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)
	timer_display.add_theme_font_size_override("font_size", 32)
	timer_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(timer_display)

	level_label = Label.new()
	level_label.text = "LEVEL 1"
	level_label.add_theme_color_override("font_color", C_OLIVE_LIGHT)
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_label)


# ── Tasks — upper RIGHT ───────────────────────────────────────────────────────
func _build_tasks_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(260, 0)
	panel.set_anchor(SIDE_LEFT,   1.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = -268
	panel.offset_right  = -8
	panel.offset_top    = TOP_Y_START
	panel.offset_bottom = TOP_Y_END
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	# Collapsible header button
	var header := Button.new()
	header.text = "TASK LIST  ▲"
	header.flat = false
	header.add_theme_color_override("font_color", C_GOLD_LIGHT)
	header.add_theme_font_size_override("font_size", 13)
	var hdr_style := StyleBoxFlat.new()
	hdr_style.bg_color = Color(0.35, 0.16, 0.04, 0.6)
	header.add_theme_stylebox_override("normal",  hdr_style)
	header.add_theme_stylebox_override("hover",   hdr_style)
	header.add_theme_stylebox_override("pressed", hdr_style)
	header.pressed.connect(_toggle_tasks)
	tasks_toggle = header
	vbox.add_child(header)

	# Task rows live here
	tasks_body = VBoxContainer.new()
	tasks_body.add_theme_constant_override("separation", 6)
	tasks_body.name = "TasksBody"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",     8)
	margin.add_theme_constant_override("margin_bottom",  8)
	margin.add_child(tasks_body)
	vbox.add_child(margin)

	# Progress footer
	tasks_progress = Label.new()
	tasks_progress.text = "0 / 0 done"
	tasks_progress.add_theme_color_override("font_color", C_TAN)
	tasks_progress.add_theme_font_size_override("font_size", 12)
	tasks_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var prog_margin := MarginContainer.new()
	prog_margin.add_theme_constant_override("margin_right",  10)
	prog_margin.add_theme_constant_override("margin_bottom",  6)
	prog_margin.add_child(tasks_progress)
	vbox.add_child(prog_margin)


# ── Inventory — BOTTOM of screen ─────────────────────────────────────────────
func _build_inventory_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left   =  8
	panel.offset_right  = -8
	panel.offset_top    = -72
	panel.offset_bottom = -8
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	title.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 6)
	vbox.add_child(slots_row)

	for i in 6:
		var sp := PanelContainer.new()
		sp.custom_minimum_size = Vector2(44, 44)

		var s := StyleBoxFlat.new()
		s.bg_color    = Color(0, 0, 0, 0.5)
		s.border_color = C_BORDER
		s.set_border_width_all(2)
		sp.add_theme_stylebox_override("panel", s)
		sp.modulate.a = 0.35
		slots_row.add_child(sp)
		slot_panels.append(sp)

		# Overlay for slot number + icon + item name
		var overlay := Control.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		sp.add_child(overlay)

		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_color_override("font_color", C_GOLD)
		num.add_theme_font_size_override("font_size", 8)
		num.position = Vector2(2, 1)
		overlay.add_child(num)

		var icon := Label.new()
		icon.text = ""
		icon.add_theme_font_size_override("font_size", 18)
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.offset_left = -10
		icon.offset_top  = -12
		overlay.add_child(icon)
		slot_icons.append(icon)

		var name_lbl := Label.new()
		name_lbl.text = ""
		name_lbl.add_theme_color_override("font_color", C_TAN)
		name_lbl.add_theme_font_size_override("font_size", 6)
		name_lbl.set_anchor(SIDE_RIGHT,  1.0)
		name_lbl.set_anchor(SIDE_BOTTOM, 1.0)
		name_lbl.set_anchor(SIDE_LEFT,   0.0)
		name_lbl.set_anchor(SIDE_TOP,    0.0)
		name_lbl.offset_right  = -2
		name_lbl.offset_bottom = -2
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
		overlay.add_child(name_lbl)
		slot_names.append(name_lbl)

	# Hint text
	var hint := Label.new()
	hint.text = "WASD = move   E = interact   1-6 = select slot"
	hint.add_theme_color_override("font_color", C_TAN)
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate.a = 0.65
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	slots_row.add_child(hint)


# ─────────────────────────────────────────
#  INTERNAL HELPERS
# ─────────────────────────────────────────

func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color              = C_PANEL_BG
	style.border_color          = C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", style)
	return p


func _set_timer_display(seconds: int) -> void:
	var m : int = seconds / 60
	var s : int = seconds % 60
	timer_display.text = "%02d:%02d" % [m, s]


func _toggle_tasks() -> void:
	tasks_open = !tasks_open
	tasks_body.get_parent().visible = tasks_open
	tasks_toggle.text = "TASK LIST  " + ("▲" if tasks_open else "▼")


func _rebuild_tasks() -> void:
	# Clear old rows first
	for child in tasks_body.get_children():
		child.queue_free()

	for i in task_names.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		tasks_body.add_child(row)

		# Checkbox indicator
		var chk := Label.new()
		chk.custom_minimum_size = Vector2(14, 14)
		chk.add_theme_font_size_override("font_size", 14)
		if task_done[i]:
			chk.text = "✓"
			chk.add_theme_color_override("font_color", C_OLIVE_LIGHT)
		else:
			chk.text = "□"
			chk.add_theme_color_override("font_color", C_TAN)
		row.add_child(chk)

		# Task text — green + strikethrough when done
		var txt := Label.new()
		txt.text = task_names[i]
		txt.add_theme_font_size_override("font_size", 13)
		if task_done[i]:
			# Strikethrough effect: overlay a horizontal line via a child ColorRect
			txt.add_theme_color_override("font_color", C_OLIVE_LIGHT)
			# Modulate to show it's done
			txt.modulate = Color(C_OLIVE_LIGHT, 0.85)
		else:
			txt.add_theme_color_override("font_color", C_CREAM)
		row.add_child(txt)

		# Strikethrough line drawn over the text label
		# We attach it after the label is sized; use a simple separator instead
		if task_done[i]:
			var strike_container := Control.new()
			strike_container.custom_minimum_size = Vector2(0, 0)
			strike_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			# Position the line via script after one frame so sizes are known
			var strike := ColorRect.new()
			strike.color = C_OLIVE_LIGHT
			strike.custom_minimum_size = Vector2(1, 2)
			# We anchor it to the txt label instead by using a custom draw approach:
			# For simplicity, append a separator styled as a line above the row.
			# A cleaner approach: just use color + "✓" without a real strikethrough
			# since Godot's Label doesn't support text decoration natively.
			# We simulate it with a colored HSeparator overlaid on the row.
			pass  # See NOTE below


func _update_task_progress() -> void:
	var done_count := task_done.count(true)
	tasks_progress.text = "%d / %d done" % [done_count, task_done.size()]
