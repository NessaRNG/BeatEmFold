class_name Tutorial
extends Node
## Tutorial terpandu 7 langkah di arena aman (1 samsack pasif respawn).
## Maju via event; selesai -> finished (main lanjut wave 0).

signal finished

const TOTAL := 7

var player: Player
var hand_manager: HandManager
var combat: CombatManager
var run: RunManager
var ui_root: Control
var tutor: Dummy

var step := -1
var hits := 0
var start_pos := Vector2.ZERO
var done := false
var l_was := false

var box: Panel
var title_lb: Label
var text_lb: Label


func setup(p: Player, hm: HandManager, cm: CombatManager, r: RunManager, ui: Control) -> void:
	player = p
	hand_manager = hm
	combat = cm
	run = r
	ui_root = ui
	player.hit_landed.connect(_on_hit)
	player.dashed.connect(_on_dash)
	hand_manager.hand_changed.connect(_on_hand)
	hand_manager.selection_changed.connect(_on_sel)
	combat.cash_in_resolved.connect(_on_cash)


func begin(parent: Node) -> void:
	_end_old_tutor()
	step = 0
	hits = 0
	done = false
	start_pos = player.position
	run.hands_left = 99
	run.discards_left = 99
	var dummy_script := load("res://scripts/dummy.gd") as GDScript
	tutor = dummy_script.new()
	tutor.respawns = true
	tutor.display_name = "SAMSACK"
	tutor.max_hp = 30
	tutor.hp = 30
	tutor.position = Vector2(800, 520)
	parent.add_child(tutor)
	tutor.died.connect(_on_tutor_died)
	_build_box()
	_refresh()
	UiAnim.rise_in(box, 24.0, 0.28)


func _end_old_tutor() -> void:
	if tutor != null and is_instance_valid(tutor):
		tutor.queue_free()
	tutor = null


func _build_box() -> void:
	if box != null:
		return
	box = Panel.new()
	box.add_theme_stylebox_override("panel",
		UiTheme.panel_style(Color(0.07, 0.06, 0.11, 0.95), Color("7bff9e"), 2, 10))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(box)
	title_lb = Label.new()
	UiTheme.style_title(title_lb, 20, Color("7bff9e"))
	title_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title_lb)
	text_lb = Label.new()
	UiTheme.style_body(text_lb, 17)
	text_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(text_lb)
	_layout_box()


func _layout_box() -> void:
	if box == null:
		return
	var vp := ui_root.get_viewport_rect().size
	box.position = Vector2((vp.x - 560.0) * 0.5, 216)
	box.size = Vector2(560, 110)
	title_lb.position = Vector2(0, 8)
	title_lb.size = Vector2(560, 28)
	text_lb.position = Vector2(16, 38)
	text_lb.size = Vector2(528, 64)


func _process(_delta: float) -> void:
	if step < 0 or done:
		return
	var l := Input.is_physical_key_pressed(KEY_L)
	if l and not l_was:
		skip()
	l_was = l
	if step == 0 and player.position.distance_to(start_pos) > 120.0:
		_advance()


func skip() -> void:
	if done:
		return
	_finish()


func _on_hit() -> void:
	if step != 1:
		return
	hits += 1
	if hits >= 3:
		_advance()
	else:
		_refresh()


func _on_sel(sel: Array) -> void:
	if step == 3 and sel.size() >= 2:
		_advance()


func _on_hand(_cards: Array) -> void:
	if step == 2:
		_refresh()


func _on_cash(_n: String, _d: int, _k: int) -> void:
	if step == 4:
		_advance()


func _on_dash() -> void:
	if step == 5:
		_advance()


func _on_tutor_died() -> void:
	if step == 6:
		_finish()


func _step_text() -> String:
	match step:
		0:
			return "Gerak: WASD / Panah"
		1:
			return "Pukul SAMSACK: J, kena %d/3" % mini(hits, 3)
		2:
			return "Tiap pukulan = 1 kartu. Kumpulkan %d/5" % mini(hand_manager.hand.size(), 5)
		3:
			return "Tahan TAB + tekan 1 dan 2 (%d/2)" % mini(hand_manager.get_selected_cards().size(), 2)
		4:
			return "Lepas TAB + tekan E = CASH-IN!"
		5:
			return "Dash: K / Spasi"
		_:
			return "Habisi SAMSACK itu!"


func _refresh() -> void:
	if box == null or step < 0:
		return
	if step == 2 and hand_manager.hand.size() >= 5:
		_advance()
		return
	title_lb.text = "TUTORIAL %d/%d   (L = lewati)" % [mini(step + 1, TOTAL), TOTAL]
	text_lb.text = _step_text()
	_layout_box()


func _advance() -> void:
	Sfx.play_sfx("confirm", -6.0)
	step += 1
	if step >= TOTAL:
		_finish()
	else:
		_refresh()
		UiAnim.punch(title_lb, 1.12, 0.14)


func _finish() -> void:
	if done:
		return
	done = true
	step = -1
	if box != null:
		box.visible = false
	if tutor != null and is_instance_valid(tutor):
		tutor.queue_free()
	tutor = null
	finished.emit()
