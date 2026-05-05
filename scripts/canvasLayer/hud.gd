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

const SIDE_MARGIN := 8
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

var inv_slot_panel : PanelContainer
var inv_slot_icon  : Label
var inv_slot_name  : Label

# PauseMenu.tscn must be instanced as a child of this HUD node in the scene tree.
# Scene tree should look like:
#   HUD  (CanvasLayer, this script)
#   └── PauseMenu  (CanvasLayer, PauseMenu.gd)
@onready var pause_menu : CanvasLayer = $PauseMenu

# ── State ──
var task_names : Array[String] = []
var task_done  : Array[bool]   = []
var active_slot: int = 0


# ─────────────────────────────────────────
#  LIFECYCLE
# ─────────────────────────────────────────

func _ready() -> void:
	_build_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_P):
		_toggle_pause()


# ─────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────

func update_stats(hp: float, energy: float, happiness: float) -> void:
	hp_bar.value  = hp
	en_bar.value  = energy
	hap_bar.value = happiness
	hp_val.text   = str(int(hp))        + "%"
	en_val.text   = str(int(energy))    + "%"
	hap_val.text  = str(int(happiness)) + "%"
	hp_bar.modulate  = Color.RED if hp        < 25.0 else Color.WHITE
	en_bar.modulate  = Color.RED if energy    < 20.0 else Color.WHITE
	hap_bar.modulate = Color.RED if happiness < 20.0 else Color.WHITE


func setup_tasks(names: Array[String]) -> void:
	task_names = names
	task_done.resize(names.size())
	task_done.fill(false)
	_rebuild_tasks()
	_update_task_progress()


func complete_task(index: int) -> void:
	if index < 0 or index >= task_done.size():
		return
	task_done[index] = true
	_rebuild_tasks()
	_update_task_progress()


func setup_timer(seconds: int, level_name: String) -> void:
	_set_timer_display(seconds)
	level_label.text = level_name


func tick_timer(seconds_left: int) -> void:
	_set_timer_display(seconds_left)
	if seconds_left <= 30:
		timer_display.add_theme_color_override("font_color", C_WARN)
	else:
		timer_display.add_theme_color_override("font_color", C_GOLD_LIGHT)


func show_interact_prompt(visible_state: bool, text: String = "[E] Interact") -> void:
	interact_prompt.visible = visible_state
	interact_prompt.text    = text


func update_inventory(inventory_array: Array, p_active_slot: int) -> void:
	active_slot = p_active_slot
	var item: Dictionary = inventory_array[0] if not inventory_array.is_empty() else {}
	var has_item := not item.is_empty()

	var style := StyleBoxFlat.new()
	style.bg_color     = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12) if has_item else Color(0, 0, 0, 0.5)
	style.border_color = C_GOLD_LIGHT if has_item else C_BORDER
	style.set_border_width_all(2)
	inv_slot_panel.add_theme_stylebox_override("panel", style)
	inv_slot_panel.modulate.a = 1.0 if has_item else 0.4

	inv_slot_icon.text = item.get("icon", "") if has_item else ""
	inv_slot_name.text = item.get("name", "") if has_item else ""


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
	_build_pause_button(root)

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


# ── Stats — upper LEFT ────────────────────────────────────
func _build_stats_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(280, 0)
	panel.set_anchor(SIDE_LEFT,   0.0)
	panel.set_anchor(SIDE_RIGHT,  0.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = SIDE_MARGIN
	panel.offset_right  = SIDE_MARGIN + 280
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


# ── Timer — upper CENTER ──────────────────────────────────
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


# ── Tasks — upper RIGHT ───────────────────────────────────
func _build_tasks_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(260, 0)
	panel.set_anchor(SIDE_LEFT,   1.0)
	panel.set_anchor(SIDE_RIGHT,  1.0)
	panel.set_anchor(SIDE_TOP,    0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left   = -(300 + SIDE_MARGIN)
	panel.offset_right  = -SIDE_MARGIN
	panel.offset_top    = TOP_Y_START
	panel.offset_bottom = TOP_Y_END
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

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


# ── Inventory — BOTTOM, single slot ──────────────────────
func _build_inventory_panel(root: Control) -> void:
	var panel := _make_panel()
	panel.custom_minimum_size = Vector2(68, 68)
	panel.set_anchor(SIDE_LEFT,   0.5)
	panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    1.0)
	panel.set_anchor(SIDE_BOTTOM, 1.0)
	panel.offset_left   = -34
	panel.offset_right  =  34
	panel.offset_top    = -80
	panel.offset_bottom = -8
	root.add_child(panel)

	var sp := PanelContainer.new()
	sp.custom_minimum_size = Vector2(48, 48)
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0, 0, 0, 0.5)
	s.border_color = C_BORDER
	s.set_border_width_all(2)
	sp.add_theme_stylebox_override("panel", s)
	sp.modulate.a = 0.4
	panel.add_child(sp)
	inv_slot_panel = sp

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	sp.add_child(overlay)

	var num := Label.new()
	num.text = "1"
	num.add_theme_color_override("font_color", C_GOLD)
	num.add_theme_font_size_override("font_size", 8)
	num.position = Vector2(2, 1)
	overlay.add_child(num)

	inv_slot_icon = Label.new()
	inv_slot_icon.text = ""
	inv_slot_icon.add_theme_font_size_override("font_size", 20)
	inv_slot_icon.set_anchors_preset(Control.PRESET_CENTER)
	inv_slot_icon.offset_left = -12
	inv_slot_icon.offset_top  = -14
	overlay.add_child(inv_slot_icon)

	inv_slot_name = Label.new()
	inv_slot_name.text = ""
	inv_slot_name.add_theme_color_override("font_color", C_TAN)
	inv_slot_name.add_theme_font_size_override("font_size", 6)
	inv_slot_name.set_anchor(SIDE_RIGHT,  1.0)
	inv_slot_name.set_anchor(SIDE_BOTTOM, 1.0)
	inv_slot_name.set_anchor(SIDE_LEFT,   0.0)
	inv_slot_name.set_anchor(SIDE_TOP,    0.0)
	inv_slot_name.offset_right  = -2
	inv_slot_name.offset_bottom = -2
	inv_slot_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inv_slot_name.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	overlay.add_child(inv_slot_name)


# ── Pause Button — lower LEFT ─────────────────────────────
func _build_pause_button(root: Control) -> void:
	var btn := Button.new()
	btn.text = "❚❚"
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", C_GOLD_LIGHT)
	btn.custom_minimum_size = Vector2(44, 44)

	var style := StyleBoxFlat.new()
	style.bg_color    = C_PANEL_BG
	style.border_color = C_BORDER
	style.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2)
	btn.add_theme_stylebox_override("hover",   hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	btn.set_anchor(SIDE_LEFT,   0.0)
	btn.set_anchor(SIDE_RIGHT,  0.0)
	btn.set_anchor(SIDE_TOP,    1.0)
	btn.set_anchor(SIDE_BOTTOM, 1.0)
	btn.offset_left   = SIDE_MARGIN
	btn.offset_right  = SIDE_MARGIN + 44
	btn.offset_top    = -52
	btn.offset_bottom = -8

	btn.pressed.connect(_toggle_pause)
	root.add_child(btn)


# ─────────────────────────────────────────
#  PAUSE
# ─────────────────────────────────────────

func _toggle_pause() -> void:
	pause_menu.toggle()


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
			txt.modulate = Color(C_OLIVE_LIGHT, 0.85)
		else:
			txt.add_theme_color_override("font_color", C_CREAM)
		row.add_child(txt)


func _update_task_progress() -> void:
	var done_count := task_done.count(true)
	tasks_progress.text = "%d / %d done" % [done_count, task_done.size()]
