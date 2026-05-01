extends CanvasLayer

# ── Colors matching your HTML prototype ──
const C_PANEL_BG    := Color(0.118, 0.047, 0.016, 0.88)
const C_BORDER      := Color(0.545, 0.353, 0.169)
const C_GOLD        := Color(0.784, 0.518, 0.039)
const C_GOLD_LIGHT  := Color(0.910, 0.659, 0.125)
const C_TAN         := Color(0.784, 0.584, 0.424)
const C_CREAM       := Color(0.910, 0.788, 0.604)
const C_OLIVE       := Color(0.420, 0.486, 0.227)
const C_OLIVE_LIGHT := Color(0.545, 0.612, 0.353)
const C_MAROON      := Color(0.545, 0.180, 0.180)
const C_HP_BAR      := Color(0.545, 0.180, 0.180)
const C_EN_BAR      := Color(0.784, 0.518, 0.039)
const C_HAP_BAR     := Color(0.420, 0.486, 0.227)
const C_WARN        := Color(0.910, 0.353, 0.125)

# ── Node refs (set in _build_hud) ──
var hp_bar    : ProgressBar
var en_bar    : ProgressBar
var hap_bar   : ProgressBar
var hp_val    : Label
var en_val    : Label
var hap_val   : Label

var timer_display : Label
var level_label   : Label

var tasks_body    : VBoxContainer
var tasks_toggle  : Button
var tasks_progress: Label
var tasks_open    := true

var slot_panels   : Array[PanelContainer] = []
var slot_icons    : Array[Label]          = []
var slot_labels   : Array[Label]          = []

var interact_prompt : Label

# ── Center / Right panel content refs (optional, expand as needed) ──
var center_panel_label : Label
var right_panel_label  : Label

# ── State ──
var task_names  : Array[String] = []
var task_done   : Array[bool]   = []
var active_slot : int = 0

# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────

func _ready() -> void:
	_build_hud()


# ─────────────────────────────────────────
#  PUBLIC API  (called by Player / GameManager)
# ─────────────────────────────────────────

## Called when player stats change
func update_stats(hp: float, energy: float, happiness: float) -> void:
	hp_bar.value  = hp
	en_bar.value  = energy
	hap_bar.value = happiness
	hp_val.text   = str(int(hp))  + "%"
	en_val.text   = str(int(energy))  + "%"
	hap_val.text  = str(int(happiness)) + "%"

	# Turn HP bar red when critical
	if hp < 25.0:
		hp_bar.modulate = Color.RED
	else:
		hp_bar.modulate = Color.WHITE


## Called at level start to set up tasks
func setup_tasks(names: Array[String]) -> void:
	task_names = names
	task_done.resize(names.size())
	task_done.fill(false)
	_rebuild_tasks()
	_update_task_progress()


## Mark a task as complete by index
func complete_task(index: int) -> void:
	if index < 0 or index >= task_done.size():
		return
	task_done[index] = true
	_rebuild_tasks()
	_update_task_progress()


## Called at level start to set timer and level name
func setup_timer(seconds: int, level_name: String) -> void:
	_set_timer_display(seconds)
	level_label.text = level_name


## Update countdown display (call every second from GameManager)
func tick_timer(seconds_left: int) -> void:
	_set_timer_display(seconds_left)
	if seconds_left <= 30:
		timer_display.add_theme_color_override("font_color", C_WARN)
	else:
		timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)


## Update inventory from Player's inventory array
## inventory_array: Array of Dictionaries — each dict has "icon" (String emoji/char) and "name"
func update_inventory(inventory_array: Array, p_active_slot: int) -> void:
	active_slot = p_active_slot
	for i in 6:
		var item: Dictionary = inventory_array[i] if i < inventory_array.size() else {}
		var has_item := not item.is_empty()

		var style := StyleBoxFlat.new()
		style.bg_color = C_PANEL_BG
		style.border_color = C_GOLD_LIGHT if i == active_slot else (C_BORDER if has_item else Color(C_BORDER, 0.35))
		style.set_border_width_all(2)
		style.set_corner_radius_all(0)
		slot_panels[i].add_theme_stylebox_override("panel", style)

		slot_icons[i].text  = item.get("icon", "") if has_item else ""
		slot_labels[i].text = item.get("name", "") if has_item else ""

		slot_panels[i].modulate.a = 1.0 if has_item else 0.35


## Show/hide the [E] interact prompt with a custom label
func show_interact_prompt(visible: bool, text: String = "[E] Interact") -> void:
	interact_prompt.visible = visible
	interact_prompt.text    = text


## Update center panel text (optional helper)
func update_center_panel(text: String) -> void:
	if center_panel_label:
		center_panel_label.text = text


## Update right panel text (optional helper)
func update_right_panel(text: String) -> void:
	if right_panel_label:
		right_panel_label.text = text


# ─────────────────────────────────────────
#  INTERNAL: HUD BUILDER
# ─────────────────────────────────────────

func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── TOP ROW ──
	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.add_theme_constant_override("separation", 12)
	top_row.set_anchor(SIDE_LEFT,   0.0)
	top_row.set_anchor(SIDE_RIGHT,  1.0)
	top_row.set_anchor(SIDE_TOP,    0.0)
	top_row.set_anchor(SIDE_BOTTOM, 0.0)
	top_row.offset_left   = 8
	top_row.offset_right  = -8
	top_row.offset_top    = 8
	top_row.offset_bottom = 110
	root.add_child(top_row)

	_build_stats_panel(top_row)
	_build_timer_panel(top_row)
	_build_tasks_panel(top_row)

	# ── INTERACT PROMPT (center bottom) ──
	interact_prompt = Label.new()
	interact_prompt.text = "[E] Interact"
	interact_prompt.visible = false
	interact_prompt.add_theme_color_override("font_color", C_GOLD_LIGHT)
	interact_prompt.add_theme_font_size_override("font_size", 16)
	interact_prompt.set_anchor(SIDE_LEFT,   0.5)
	interact_prompt.set_anchor(SIDE_RIGHT,  0.5)
	interact_prompt.set_anchor(SIDE_BOTTOM, 1.0)
	interact_prompt.set_anchor(SIDE_TOP,    1.0)
	interact_prompt.offset_left   = -100
	interact_prompt.offset_right  = 100
	interact_prompt.offset_bottom = -110
	interact_prompt.offset_top    = -140
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(interact_prompt)

	## ── CENTER PANEL ──
	#_build_center_panel(root)
#
	## ── RIGHT PANEL ──
	#_build_right_panel(root)

	# ── INVENTORY (bottom) ──
	_build_inventory_panel(root)


func _build_stats_panel(parent: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(280, 0)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "STATS"
	title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_make_stat_row(vbox, "♥", "Health",  C_HP_BAR,  "hp")
	_make_stat_row(vbox, "⚡", "Energy",  C_EN_BAR,  "en")
	_make_stat_row(vbox, "★", "Happy",   C_HAP_BAR, "hap")

	# Capture val label refs by child index
	hp_bar  = vbox.get_child(1).get_child(2) as ProgressBar
	en_bar  = vbox.get_child(2).get_child(2) as ProgressBar
	hap_bar = vbox.get_child(3).get_child(2) as ProgressBar
	hp_val  = vbox.get_child(1).get_child(3) as Label
	en_val  = vbox.get_child(2).get_child(3) as Label
	hap_val = vbox.get_child(3).get_child(3) as Label


func _make_stat_row(parent: VBoxContainer, icon: String, label_text: String,
		bar_color: Color, _key: String) -> void:
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
	bar.min_value = 0
	bar.max_value = 100
	bar.value     = 100
	bar.custom_minimum_size = Vector2(100, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
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


func _build_timer_panel(parent: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(180, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)

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


func _build_tasks_panel(parent: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(260, 0)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var header := Button.new()
	header.text = "TASK LIST  ▲"
	header.flat  = false
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

	tasks_body = VBoxContainer.new()
	tasks_body.add_theme_constant_override("separation", 6)
	tasks_body.name = "TasksBody"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   10)
	margin.add_theme_constant_override("margin_right",  10)
	margin.add_theme_constant_override("margin_top",    8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(tasks_body)
	vbox.add_child(margin)

	tasks_progress = Label.new()
	tasks_progress.text = "0 / 0 done"
	tasks_progress.add_theme_color_override("font_color", C_TAN)
	tasks_progress.add_theme_font_size_override("font_size", 12)
	tasks_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var prog_margin := MarginContainer.new()
	prog_margin.add_theme_constant_override("margin_right",  10)
	prog_margin.add_theme_constant_override("margin_bottom", 6)
	prog_margin.add_child(tasks_progress)
	vbox.add_child(prog_margin)


## ── NEW: Center Panel ─────────────────────────────────────
#func _build_center_panel(root: Control) -> void:
	#var panel := _make_panel()
	#panel.custom_minimum_size = Vector2(220, 130)
	#panel.set_anchor(SIDE_LEFT,   0.5)
	#panel.set_anchor(SIDE_RIGHT,  0.5)
	#panel.set_anchor(SIDE_TOP,    0.5)
	#panel.set_anchor(SIDE_BOTTOM, 0.5)
	#panel.offset_left   = -110
	#panel.offset_right  = 110
	#panel.offset_top    = -65
	#panel.offset_bottom = 65
	#root.add_child(panel)
#
	#var vbox := VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 8)
	#vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	#panel.add_child(vbox)
#
	#var title := Label.new()
	#title.text = "CENTER PANEL"
	#title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#title.add_theme_font_size_override("font_size", 14)
	#title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(title)
#
	#center_panel_label = Label.new()
	#center_panel_label.text = "Add your content here"
	#center_panel_label.add_theme_color_override("font_color", C_CREAM)
	#center_panel_label.add_theme_font_size_override("font_size", 13)
	#center_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#center_panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#vbox.add_child(center_panel_label)
#
#
## ── NEW: Right Panel ──────────────────────────────────────
#func _build_right_panel(root: Control) -> void:
	#var panel := _make_panel()
	#panel.custom_minimum_size = Vector2(210, 300)
	#panel.set_anchor(SIDE_LEFT,   1.0)
	#panel.set_anchor(SIDE_RIGHT,  1.0)
	#panel.set_anchor(SIDE_TOP,    0.0)
	#panel.set_anchor(SIDE_BOTTOM, 0.0)
	#panel.offset_left   = -218
	#panel.offset_right  = -8
	#panel.offset_top    = 120   # sits below the top row
	#panel.offset_bottom = 420
	#root.add_child(panel)
#
	#var vbox := VBoxContainer.new()
	#vbox.add_theme_constant_override("separation", 10)
	#panel.add_child(vbox)
#
	#var title := Label.new()
	#title.text = "RIGHT PANEL"
	#title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	#title.add_theme_font_size_override("font_size", 14)
	#title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(title)
#
	#var sep := HSeparator.new()
	#var sep_style := StyleBoxFlat.new()
	#sep_style.bg_color = C_BORDER
	#sep.add_theme_stylebox_override("separator", sep_style)
	#vbox.add_child(sep)
#
	#right_panel_label = Label.new()
	#right_panel_label.text = "Add your content here"
	#right_panel_label.add_theme_color_override("font_color", C_CREAM)
	#right_panel_label.add_theme_font_size_override("font_size", 13)
	#right_panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	#right_panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	#vbox.add_child(right_panel_label)


func _build_inventory_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.set_anchor(SIDE_TOP,    1.0)
	panel.offset_left   = 8
	panel.offset_right  = -8
	panel.offset_bottom = -8
	panel.offset_top    = -80
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 8)
	vbox.add_child(slots_row)

	for i in 6:
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(56, 56)

		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color    = Color(0, 0, 0, 0.5)
		slot_style.border_color = C_BORDER
		slot_style.set_border_width_all(2)
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		slot_panel.modulate.a = 0.35
		slots_row.add_child(slot_panel)

		var overlay := Control.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_panel.add_child(overlay)

		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.add_theme_color_override("font_color", C_GOLD)
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.set_anchor(SIDE_LEFT, 0)
		num_lbl.set_anchor(SIDE_TOP,  0)
		num_lbl.offset_left = 3
		num_lbl.offset_top  = 2
		overlay.add_child(num_lbl)

		var icon_lbl := Label.new()
		icon_lbl.text = ""
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.set_anchors_preset(Control.PRESET_CENTER)
		icon_lbl.offset_left = -12
		icon_lbl.offset_top  = -14
		overlay.add_child(icon_lbl)
		slot_icons.append(icon_lbl)

		var name_lbl := Label.new()
		name_lbl.text = ""
		name_lbl.add_theme_color_override("font_color", C_TAN)
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.set_anchor(SIDE_RIGHT,  1)
		name_lbl.set_anchor(SIDE_BOTTOM, 1)
		name_lbl.offset_right  = -2
		name_lbl.offset_bottom = -1
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		overlay.add_child(name_lbl)
		slot_labels.append(name_lbl)

		slot_panels.append(slot_panel)

	var hint := Label.new()
	hint.text = "WASD=move   E=interact   1-6=slot"
	hint.add_theme_color_override("font_color", C_TAN)
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate.a = 0.7
	slots_row.add_child(hint)


# ─────────────────────────────────────────
#  INTERNAL HELPERS
# ─────────────────────────────────────────

func _make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = C_PANEL_BG
	style.border_color = C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", style)
	return p


func _apply_panel_style_to(node: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color    = Color(0.08, 0.03, 0.01, 0.9)
	style.border_color = C_GOLD_LIGHT
	style.set_border_width_all(2)
	node.add_theme_stylebox_override("panel", style)


func _set_timer_display(seconds: int) -> void:
	var m := seconds / 60
	var s := seconds % 60
	timer_display.text = "%02d:%02d" % [m, s]


func _toggle_tasks() -> void:
	tasks_open = !tasks_open
	tasks_body.get_parent().visible = tasks_open
	tasks_toggle.text = "TASK LIST  " + ("▲" if tasks_open else "▼")


func _rebuild_tasks() -> void:
	for child in tasks_body.get_children():
		child.queue_free()

	for i in task_names.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		tasks_body.add_child(row)

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

		var txt := Label.new()
		txt.text = task_names[i]
		txt.add_theme_font_size_override("font_size", 13)
		if task_done[i]:
			txt.add_theme_color_override("font_color", C_OLIVE_LIGHT)
		else:
			txt.add_theme_color_override("font_color", C_CREAM)
		row.add_child(txt)


func _update_task_progress() -> void:
	var done_count := task_done.count(true)
	tasks_progress.text = "%d / %d done" % [done_count, task_done.size()]
