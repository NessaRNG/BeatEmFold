extends Node2D
## MVP Step 1-4: arena + kartu + cash-in + wave + shop + boss.

const ST_FIGHT := 0
const ST_SHOP := 1
const ST_OVER := 2
const ST_MENU := 4
const ST_TUTORIAL := 5
const ST_ASK := 6

## true = boot ke menu utama. T-restart set false agar langsung main.
static var start_in_menu := true

var player: Player
var deck: Deck
var hand_manager: HandManager
var hand_ui: HandUI
var combat_manager: CombatManager
var run_manager: RunManager
var jokers: JokerManager
var wave_manager: WaveManager
var shop_ui: ShopUI
var tutorial: Tutorial
var player_hp_label: Label
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect
var boss_bar_bg: ColorRect
var boss_bar_fill: ColorRect
var seal_badge: Panel
var seal_text: Label
var wave_label: Label
var combo_label: Label
var deck_label: Label
var help_label: Label
var mode_label: Label
var combat_label: Label
var boss_label: Label
var flash_rect: ColorRect
## Semua UI ber-anchor wajib di bawah CanvasLayer — Control di bawah
## Node2D tidak dapat viewport rect (size 0, anchor runtuh off-screen).
var ui_root: Control
var hud_panel: ColorRect
var cash_pips: Array[ColorRect] = []
var discard_pips: Array[ColorRect] = []

var state := ST_FIGHT
var camera: Camera2D
var trauma := 0.0
var hitstop_active := false
var last_hp := 100
var _boss_frac := 1.0
var _nav_frame := -1


## Tolak aktivasi ganda dalam 1 frame (tombol + shortcut keyboard).
func _nav_guard() -> bool:
	var f := Engine.get_process_frames()
	if f == _nav_frame:
		return false
	_nav_frame = f
	return true
# Menu & pause.
var menu_dim: ColorRect
var menu_title: Label
var menu_sub: Label
var menu_best: Label
var menu_mulai: Button
var menu_keluar: Button
var ask_box: Panel
var ask_text: Label
var ask_ya: Button
var ask_tidak: Button
var menu_div: ColorRect
var menu_ver: Label
var menu_hint: Label
var pause_dim: ColorRect
var pause_title: Label
var pause_hints: Label
var pause_lanjut: Button
var pause_menu_btn: Button
var over_dim: ColorRect
var over_title: Label
var over_score: Label
var over_retry: Button
var over_menu_btn: Button
var last_best_name := "HIGH CARD"
var last_best_type := 0
var select_was_held := false
var r_was_down := false
var num_was_down := [false, false, false, false, false, false]
var combat_tween: Tween


func _ready() -> void:
	_build_arena()
	_build_actors()
	_build_hud()
	_build_cards()
	_build_combat()
	_build_flow()
	_build_menu()
	_build_ask()
	_connect_signals()
	var keys := PauseKeys.new()
	keys.game = self
	add_child(keys)
	_refresh_hud(player.hp, player.max_hp)
	if start_in_menu:
		_show_menu()
	else:
		_start_wave(0)


func _build_arena() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1a1a26")
	bg.size = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	add_child(bg)

	var alley := AlleyBg.new()
	add_child(alley)

	var lane := ColorRect.new()
	lane.color = Color(0.12, 0.11, 0.22, 0.55)
	lane.size = Vector2(1280, Player.LANE_BOTTOM - Player.LANE_TOP + 80.0)
	lane.position = Vector2(0, Player.LANE_TOP - 40.0)
	add_child(lane)

	var ground_line := ColorRect.new()
	ground_line.color = Color("3a3a55")
	ground_line.size = Vector2(1280, 4)
	ground_line.position = Vector2(0, Player.LANE_BOTTOM + 30.0)
	add_child(ground_line)

	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	add_child(camera)
	camera.make_current()


func _build_actors() -> void:
	var player_script := load("res://scripts/player.gd") as GDScript
	player = player_script.new()
	player.position = Vector2(400, 520)
	add_child(player)


func _build_hud() -> void:
	var ui_layer := CanvasLayer.new()
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UiTheme.build()
	ui_layer.add_child(ui_root)
	get_viewport().size_changed.connect(_fit_ui)
	_fit_ui()

	hud_panel = ColorRect.new()
	hud_panel.color = Color(0, 0, 0, 0.5)
	hud_panel.position = Vector2(8, 8)
	hud_panel.size = Vector2(340, 192)
	add_child(hud_panel)

	player_hp_label = Label.new()
	player_hp_label.position = Vector2(24, 12)
	UiTheme.style_title(player_hp_label, 26)
	ui_root.add_child(player_hp_label)

	hp_bar_bg = ColorRect.new()
	hp_bar_bg.position = Vector2(24, 48)
	hp_bar_bg.size = Vector2(280, 16)
	hp_bar_bg.color = Color(0, 0, 0, 0.6)
	add_child(hp_bar_bg)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.position = Vector2(24, 48)
	hp_bar_fill.size = Vector2(280, 16)
	hp_bar_fill.color = Color("55d66b")
	add_child(hp_bar_fill)

	wave_label = Label.new()
	wave_label.position = Vector2(24, 70)
	UiTheme.style_body(wave_label, 20)
	wave_label.text = "WAVE 1/3"
	ui_root.add_child(wave_label)

	combo_label = Label.new()
	combo_label.position = Vector2(24, 96)
	UiTheme.style_body(combo_label, 20)
	combo_label.text = "JAB: -"
	ui_root.add_child(combo_label)

	deck_label = Label.new()
	deck_label.position = Vector2(24, 122)
	UiTheme.style_body(deck_label, 16, Color(1, 1, 1, 0.85))
	ui_root.add_child(deck_label)

	for i in range(4):
		var pip := ColorRect.new()
		pip.position = Vector2(24 + i * 18, 146)
		pip.size = Vector2(14, 14)
		pip.color = Color("55d66b")
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(pip)
		cash_pips.append(pip)
	for i in range(3):
		var pip2 := ColorRect.new()
		pip2.position = Vector2(24 + 4 * 18 + 14 + i * 18, 146)
		pip2.size = Vector2(14, 14)
		pip2.color = Color("5aa9ff")
		pip2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_root.add_child(pip2)
		discard_pips.append(pip2)

	help_label = Label.new()
	UiTheme.style_body(help_label, 15, Color(1, 1, 1, 0.8))
	help_label.text = "Jab: J | Dash: K/Spasi | Tahan Tab + 1-6 pilih | E cash-in | R buang"
	help_label.position = Vector2(24, 640)
	ui_root.add_child(help_label)

	mode_label = Label.new()
	mode_label.position = Vector2(24, 166)
	UiTheme.style_title(mode_label, 18, Color("ffe066"))
	mode_label.text = "MODE PILIH KARTU (gerak tetap jalan)"
	mode_label.visible = false
	ui_root.add_child(mode_label)

	combat_label = Label.new()
	UiTheme.style_title(combat_label, 34)
	combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combat_label.modulate = Color(1, 1, 1, 0)
	combat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(combat_label)

	flash_rect = ColorRect.new()
	flash_rect.color = Color(1, 0.9, 0.4, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(flash_rect)

	boss_label = Label.new()
	UiTheme.style_title(boss_label, 24, Color("ff7b7b"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_label.visible = false
	ui_root.add_child(boss_label)

	boss_bar_bg = ColorRect.new()
	boss_bar_bg.color = Color(0, 0, 0, 0.6)
	boss_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_bg.visible = false
	ui_root.add_child(boss_bar_bg)

	boss_bar_fill = ColorRect.new()
	boss_bar_fill.color = Color("e04040")
	boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar_fill.visible = false
	ui_root.add_child(boss_bar_fill)

	seal_badge = Panel.new()
	seal_badge.add_theme_stylebox_override("panel",
		UiTheme.panel_style(Color(0.12, 0.04, 0.06, 0.9), Color("e04040"), 2, 8))
	seal_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal_badge.visible = false
	ui_root.add_child(seal_badge)
	seal_text = Label.new()
	UiTheme.style_title(seal_text, 17, Color("ff7b7b"))
	seal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal_text.visible = false
	ui_root.add_child(seal_text)
	_fit_ui()


func _build_cards() -> void:
	deck = Deck.new()
	hand_manager = HandManager.new()
	hand_manager.deck = deck
	add_child(hand_manager)
	run_manager = RunManager.new()
	add_child(run_manager)
	jokers = JokerManager.new()
	add_child(jokers)
	var sfx := Sfx.new()
	add_child(sfx)
	hand_ui = HandUI.new()
	ui_root.add_child(hand_ui)
	hand_manager.hand_changed.connect(hand_ui.set_hand)
	hand_manager.best_hand_changed.connect(hand_ui.set_best_hand)
	hand_manager.hand_changed.connect(_on_hand_counts)
	run_manager.changed.connect(_refresh_counters)
	hand_manager.deal(3) # buka dengan 3 kartu, sisanya dari mukul


func _build_combat() -> void:
	combat_manager = CombatManager.new()
	combat_manager.player = player
	combat_manager.hand_manager = hand_manager
	combat_manager.run_manager = run_manager
	combat_manager.jokers = jokers
	add_child(combat_manager)
	combat_manager.cash_in_resolved.connect(_on_cash_resolved)
	combat_manager.cash_in_failed.connect(_on_cash_failed)


func _build_flow() -> void:
	wave_manager = WaveManager.new()
	add_child(wave_manager)
	shop_ui = ShopUI.new()
	ui_root.add_child(shop_ui)
	run_manager.load_best()
	shop_ui.setup(run_manager, jokers, deck, hand_manager)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	shop_ui.shop_closed.connect(_on_shop_closed)
	tutorial = Tutorial.new()
	add_child(tutorial)
	tutorial.setup(player, hand_manager, combat_manager, run_manager, ui_root)
	tutorial.finished.connect(_on_tutorial_finished)


func _build_menu() -> void:
	menu_dim = ColorRect.new()
	menu_dim.color = Color(0, 0, 0, 0.82)
	menu_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_dim.visible = false
	ui_root.add_child(menu_dim)
	menu_title = Label.new()
	menu_title.text = "BEAT'EM FOLD"
	UiTheme.style_title(menu_title, 76, Color("ff5fd2"))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_title.visible = false
	ui_root.add_child(menu_title)
	menu_sub = Label.new()
	menu_sub.text = "Pukul = draw. Rakit poker tanpa jeda."
	UiTheme.style_body(menu_sub, 18)
	menu_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_sub.visible = false
	ui_root.add_child(menu_sub)
	menu_best = Label.new()
	UiTheme.style_title(menu_best, 20, Color("ffd94d"))
	menu_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_best.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_best.visible = false
	ui_root.add_child(menu_best)
	menu_mulai = KeyButton.new()
	menu_mulai.setup("Mulai", KEY_M)
	menu_mulai.add_theme_font_size_override("font_size", 24)
	menu_mulai.add_theme_stylebox_override("normal",
		UiTheme.panel_style(Color("14261a"), Color("55d66b"), 2, 7))
	menu_mulai.add_theme_stylebox_override("hover",
		UiTheme.panel_style(Color("1d3a24"), Color("7bff9e"), 2, 7))
	menu_mulai.visible = false
	menu_mulai.pressed.connect(func() -> void: _press_mulai())
	ui_root.add_child(menu_mulai)
	menu_keluar = KeyButton.new()
	menu_keluar.setup("Keluar", KEY_K)
	menu_keluar.visible = false
	menu_keluar.pressed.connect(func() -> void: get_tree().quit())
	ui_root.add_child(menu_keluar)
	menu_div = ColorRect.new()
	menu_div.color = Color(1, 0.37, 0.82, 0.6)
	menu_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_div.visible = false
	ui_root.add_child(menu_div)
	menu_ver = Label.new()
	menu_ver.text = "ENDLESS • v1.0"
	UiTheme.style_body(menu_ver, 14, Color(1, 1, 1, 0.5))
	menu_ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_ver.visible = false
	ui_root.add_child(menu_ver)
	menu_hint = Label.new()
	menu_hint.text = "ENTER = mulai"
	UiTheme.style_title(menu_hint, 18, Color("ffd94d"))
	menu_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_hint.visible = false
	ui_root.add_child(menu_hint)
	pause_dim = ColorRect.new()
	pause_dim.color = Color(0, 0, 0, 0.65)
	pause_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_dim.visible = false
	pause_dim.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(pause_dim)
	pause_title = Label.new()
	pause_title.text = "PAUSE"
	UiTheme.style_title(pause_title, 56)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_title.visible = false
	pause_title.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(pause_title)
	pause_hints = Label.new()
	pause_hints.text = "ESC/L lanjutkan • T ulangi • M menu utama"
	UiTheme.style_body(pause_hints, 18)
	pause_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_hints.visible = false
	pause_hints.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(pause_hints)
	pause_lanjut = KeyButton.new()
	pause_lanjut.setup("Lanjutkan", KEY_L)
	pause_lanjut.visible = false
	pause_lanjut.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_lanjut.pressed.connect(func() -> void: toggle_pause())
	ui_root.add_child(pause_lanjut)
	pause_menu_btn = KeyButton.new()
	pause_menu_btn.setup("Menu Utama", KEY_M)
	pause_menu_btn.visible = false
	pause_menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu_btn.pressed.connect(func() -> void: to_menu())
	ui_root.add_child(pause_menu_btn)
	over_dim = ColorRect.new()
	over_dim.color = Color(0, 0, 0, 0.7)
	over_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_dim.visible = false
	ui_root.add_child(over_dim)
	over_title = Label.new()
	over_title.text = "K.O.!"
	UiTheme.style_title(over_title, 64, Color("ff5a5a"))
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_title.visible = false
	ui_root.add_child(over_title)
	over_score = Label.new()
	UiTheme.style_title(over_score, 24, Color("ffd94d"))
	over_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_score.visible = false
	ui_root.add_child(over_score)
	over_retry = KeyButton.new()
	over_retry.setup("Coba Lagi", KEY_C)
	over_retry.add_theme_font_size_override("font_size", 22)
	over_retry.add_theme_stylebox_override("normal",
		UiTheme.panel_style(Color("14261a"), Color("55d66b"), 2, 7))
	over_retry.add_theme_stylebox_override("hover",
		UiTheme.panel_style(Color("1d3a24"), Color("7bff9e"), 2, 7))
	over_retry.visible = false
	over_retry.pressed.connect(func() -> void: restart_run())
	ui_root.add_child(over_retry)
	over_menu_btn = KeyButton.new()
	over_menu_btn.setup("Menu Utama", KEY_M)
	over_menu_btn.visible = false
	over_menu_btn.pressed.connect(func() -> void: to_menu())
	ui_root.add_child(over_menu_btn)
	_layout_overlays()
	_layout_overlays()


func _menu_nodes() -> Array:
	return [menu_dim, menu_title, menu_sub, menu_best, menu_mulai,
		menu_keluar, menu_div, menu_ver, menu_hint]


func _pause_nodes() -> Array:
	return [pause_dim, pause_title, pause_hints, pause_lanjut, pause_menu_btn]


func _show_menu() -> void:
	state = ST_MENU
	player.controls_locked = true
	_set_hud_visible(false)
	menu_best.text = "TERBAIK: %d" % run_manager.best
	for n in _menu_nodes():
		n.visible = true
	_layout_overlays()
	UiAnim.rise_in(menu_title, 30.0, 0.3)
	UiAnim.fade_in(menu_div, 0.3, 0.1)
	UiAnim.fade_in(menu_sub, 0.25, 0.15)
	UiAnim.fade_in(menu_best, 0.25, 0.2)
	UiAnim.rise_in(menu_mulai, 26.0, 0.28, 0.25)
	UiAnim.rise_in(menu_keluar, 26.0, 0.28, 0.32)
	UiAnim.fade_in(menu_ver, 0.3, 0.35)
	UiAnim.fade_in(menu_hint, 0.3, 0.4)


func _hide_menu() -> void:
	for n in _menu_nodes():
		n.visible = false


func _start_game() -> void:
	if state != ST_ASK:
		return
	for n in _ask_nodes():
		n.visible = false
	_set_hud_visible(true)
	Sfx.play_sfx("confirm", -4.0)
	_start_wave(0)


func _press_mulai() -> void:
	if state != ST_MENU:
		return
	for n in _menu_nodes():
		n.visible = false
	state = ST_ASK
	for n in _ask_nodes():
		n.visible = true
	_layout_overlays()
	UiAnim.pop_in(ask_box, 0.22)
	UiAnim.rise_in(ask_ya, 20.0, 0.22, 0.08)
	UiAnim.rise_in(ask_tidak, 20.0, 0.22, 0.14)


func _start_tutorial() -> void:
	if state != ST_ASK:
		return
	for n in _ask_nodes():
		n.visible = false
	_set_hud_visible(true)
	state = ST_TUTORIAL
	player.controls_locked = false
	player.attack_locked = false
	tutorial.begin(self)


func _on_tutorial_finished() -> void:
	_start_wave(0)


func try_start_from_menu() -> void:
	_start_game()


## ENTER di menu = tanya tutorial, di ask = langsung main, di over = retry.
func confirm_end() -> void:
	if state == ST_MENU:
		_press_mulai()
	elif state == ST_ASK:
		_start_game()
	elif state == ST_OVER:
		restart_run()


func _set_hud_visible(v: bool) -> void:
	for n in [hud_panel, player_hp_label, hp_bar_bg, hp_bar_fill, wave_label,
			combo_label, deck_label, help_label, hand_ui]:
		if n != null:
			n.visible = v
	for p in cash_pips:
		p.visible = v
	for p in discard_pips:
		p.visible = v


func _on_hand_counts(_cards: Array) -> void:
	_refresh_counters()
	_refresh_status()


func _refresh_counters() -> void:
	var n := 0
	if hand_manager != null:
		n = hand_manager.hand.size()
	var d := 0
	if deck != null:
		d = deck.remaining()
	deck_label.text = "HAND %d/6 | DECK %d | CASH %d/4 | BUANG %d/3 | $%d | SKOR %d" % [
		n, d, run_manager.hands_left, run_manager.discards_left, run_manager.money,
		run_manager.score]
	for i in range(cash_pips.size()):
		cash_pips[i].color = Color("55d66b") if i < run_manager.hands_left else Color(0, 0, 0, 0.6)
	for i in range(discard_pips.size()):
		discard_pips[i].color = Color("5aa9ff") if i < run_manager.discards_left else Color(0, 0, 0, 0.6)


## Jaga ui_root seukuran viewport (anchor butuh parent ber-size nyata).
func _fit_ui() -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	if ui_root != null:
		ui_root.position = Vector2.ZERO
		ui_root.size = vp
	if combat_label != null:
		combat_label.position = Vector2(0, 180)
		combat_label.size = Vector2(vp.x, 50)
	if flash_rect != null:
		flash_rect.position = Vector2.ZERO
		flash_rect.size = vp
	if help_label != null:
		help_label.position = Vector2(24, vp.y - 26)
	_layout_overlays()
	if boss_label != null:
		boss_label.position = Vector2((vp.x - 500.0) * 0.5, 12)
		boss_label.size = Vector2(500, 32)
	if boss_bar_bg != null:
		boss_bar_bg.position = Vector2((vp.x - 400.0) * 0.5, 46)
		boss_bar_bg.size = Vector2(400, 14)
	if boss_bar_fill != null:
		boss_bar_fill.position = Vector2((vp.x - 400.0) * 0.5, 46)
		_fit_boss_bar()
	if seal_badge != null:
		seal_badge.position = Vector2(vp.x - 236.0, 12)
		seal_badge.size = Vector2(224, 56)
	if seal_text != null:
		seal_text.position = Vector2(vp.x - 236.0, 12)
		seal_text.size = Vector2(224, 56)


func _layout_overlays() -> void:
	if menu_dim == null or pause_dim == null:
		return
	var vp := get_viewport_rect().size
	menu_dim.position = Vector2.ZERO
	menu_dim.size = vp
	menu_title.position = Vector2(0, 120)
	menu_title.size = Vector2(vp.x, 90)
	menu_div.position = Vector2((vp.x - 320.0) * 0.5, 224)
	menu_div.size = Vector2(320, 3)
	menu_sub.position = Vector2(0, 236)
	menu_sub.size = Vector2(vp.x, 26)
	menu_best.position = Vector2(0, 268)
	menu_best.size = Vector2(vp.x, 30)
	menu_mulai.position = Vector2((vp.x - 320.0) * 0.5, 318)
	menu_mulai.size = Vector2(320, 62)
	menu_keluar.position = Vector2((vp.x - 220.0) * 0.5, 392)
	menu_keluar.size = Vector2(220, 46)
	menu_ver.position = Vector2(0, 452)
	menu_ver.size = Vector2(vp.x, 22)
	_layout_ask(vp)
	menu_hint.position = Vector2(0, vp.y - 60)
	menu_hint.size = Vector2(vp.x, 30)
	_layout_ask(vp)


func _build_ask() -> void:
	ask_box = Panel.new()
	ask_box.add_theme_stylebox_override("panel",
		UiTheme.panel_style(Color(0.07, 0.06, 0.11, 0.97), Color("7bff9e"), 2, 10))
	ask_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ask_box.visible = false
	ui_root.add_child(ask_box)
	ask_text = Label.new()
	ask_text.text = "Main tutorial dulu?"
	UiTheme.style_title(ask_text, 30)
	ask_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ask_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ask_text.visible = false
	ui_root.add_child(ask_text)
	ask_ya = KeyButton.new()
	ask_ya.setup("Ya", KEY_Y)
	ask_ya.visible = false
	ask_ya.pressed.connect(func() -> void: _start_tutorial())
	ui_root.add_child(ask_ya)
	ask_tidak = KeyButton.new()
	ask_tidak.setup("Langsung Main", KEY_L)
	ask_tidak.visible = false
	ask_tidak.pressed.connect(func() -> void: _start_game())
	ui_root.add_child(ask_tidak)


func _ask_nodes() -> Array:
	return [ask_box, ask_text, ask_ya, ask_tidak]


func _layout_ask(vp: Vector2) -> void:
	if ask_box == null:
		return
	var bw := 460.0
	var bx := (vp.x - bw) * 0.5
	var by := 260.0
	ask_box.position = Vector2(bx, by)
	ask_box.size = Vector2(bw, 160)
	ask_text.position = Vector2(bx, by + 16)
	ask_text.size = Vector2(bw, 44)
	ask_ya.position = Vector2(bx + 30, by + 80)
	ask_ya.size = Vector2(180, 52)
	ask_tidak.position = Vector2(bx + 250, by + 80)
	ask_tidak.size = Vector2(180, 52)
	pause_dim.position = Vector2.ZERO
	pause_dim.size = vp
	pause_title.position = Vector2(0, 220)
	pause_title.size = Vector2(vp.x, 70)
	pause_hints.position = Vector2(0, 300)
	pause_hints.size = Vector2(vp.x, 28)
	pause_lanjut.position = Vector2((vp.x - 300.0) * 0.5, 350)
	pause_lanjut.size = Vector2(300, 54)
	pause_menu_btn.position = Vector2((vp.x - 300.0) * 0.5, 416)
	pause_menu_btn.size = Vector2(300, 48)
	over_dim.position = Vector2.ZERO
	over_dim.size = vp
	over_title.position = Vector2(0, 190)
	over_title.size = Vector2(vp.x, 80)
	over_score.position = Vector2(0, 280)
	over_score.size = Vector2(vp.x, 36)
	over_retry.position = Vector2((vp.x - 320.0) * 0.5, 344)
	over_retry.size = Vector2(320, 56)
	over_menu_btn.position = Vector2((vp.x - 260.0) * 0.5, 412)
	over_menu_btn.size = Vector2(260, 48)


func _over_nodes() -> Array:
	return [over_dim, over_title, over_score, over_retry, over_menu_btn]


func _game_over() -> void:
	state = ST_OVER
	player.controls_locked = true
	mode_label.visible = false
	run_manager.save_best()
	over_score.text = "SKOR %d   •   TERBAIK %d" % [run_manager.score, run_manager.best]
	for n in _over_nodes():
		n.visible = true
	UiAnim.pop_in(over_title, 0.3, 0.0, false, 0.5)
	UiAnim.fade_in(over_score, 0.25, 0.15)
	UiAnim.rise_in(over_retry, 22.0, 0.25, 0.2)
	UiAnim.rise_in(over_menu_btn, 22.0, 0.25, 0.28)
	Sfx.play_sfx("error", -6.0, 0.7)


func toggle_pause() -> void:
	if (state != ST_FIGHT and state != ST_TUTORIAL) or player == null or player.dead:
		return
	if not _nav_guard():
		return
	if get_tree().paused:
		get_tree().paused = false
		for n in _pause_nodes():
			n.visible = false
	else:
		get_tree().paused = true
		for n in _pause_nodes():
			n.visible = true
		UiAnim.fade_in(pause_dim, 0.2, 0.0, true)
		UiAnim.pop_in(pause_title, 0.22, 0.0, true)
		UiAnim.fade_in(pause_hints, 0.2, 0.08, true)
		UiAnim.rise_in(pause_lanjut, 20.0, 0.22, 0.1, true)
		UiAnim.rise_in(pause_menu_btn, 20.0, 0.22, 0.16, true)


func restart_run() -> void:
	if state != ST_OVER and not get_tree().paused:
		return
	if not _nav_guard():
		return
	get_tree().paused = false
	start_in_menu = false
	get_tree().reload_current_scene()


func to_menu() -> void:
	if not get_tree().paused and state != ST_OVER:
		return
	if not _nav_guard():
		return
	get_tree().paused = false
	start_in_menu = true
	get_tree().reload_current_scene()


func _connect_signals() -> void:
	player.hp_changed.connect(_refresh_hud)
	player.combo_changed.connect(_on_combo)
	player.hit_landed.connect(_on_hit_landed)
	hand_manager.best_hand_changed.connect(_on_best_hand)
	hand_manager.selection_changed.connect(_on_selection)


## Tiap jab kena: draw (Step 2) + juice kecil.
func _on_hit_landed() -> void:
	hand_manager.draw_card()
	add_shake(0.12)
	hitstop(0.3, 0.03)
	Sfx.play_sfx("punch_m", -2.0, 1.0, 0.06)


func add_shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func hitstop(time_factor: float, dur: float) -> void:
	if hitstop_active:
		return
	hitstop_active = true
	Engine.time_scale = time_factor
	await get_tree().create_timer(dur, true, false, true).timeout
	Engine.time_scale = 1.0
	hitstop_active = false


func _start_wave(idx: int) -> void:
	state = ST_FIGHT
	run_manager.reset_for_wave(idx)
	wave_manager.start_wave(idx, self)
	for e in wave_manager.spawned:
		e.died.connect(_on_enemy_died.bind(e))
	wave_label.text = wave_manager.wave_title(idx)
	combat_manager.sealed_hand = wave_manager.wave_sealed(idx)
	_refresh_seal()
	var boss = wave_manager.boss_ref
	if boss != null:
		boss.hp_changed.connect(_on_boss_hp)
		_on_boss_hp(boss.hp, boss.max_hp)
		_set_boss_visible(true)
	else:
		_set_boss_visible(false)
	_enter_stage(idx)


## Sinematik masuk stage: player jalan dari kiri, musuh diam dulu.
func _enter_stage(idx: int) -> void:
	player.position = Vector2(-80, 520)
	player.facing = 1
	player.sprite.flip_h = false
	player.sprite.play("walk")
	player.controls_locked = true
	player.attack_locked = true
	player.invuln_timer = 1.5
	for e in wave_manager.spawned:
		e.ai_enabled = false
	var tween := create_tween()
	tween.tween_property(player, "position:x", 400.0, 1.1)
	await tween.finished
	if not is_inside_tree():
		return
	for e in wave_manager.spawned:
		if is_instance_valid(e):
			e.ai_enabled = true
	player.controls_locked = false
	player.attack_locked = false
	_show_combat_text(wave_manager.wave_banner(idx))


func _on_wave_cleared(idx: int) -> void:
	_set_boss_visible(false)
	# Endless: bonus wave + sine clear (slow-mo + jalan keluar) -> shop.
	run_manager.add_score(25 * (idx + 1))
	_wave_clear_cine(idx)


## Sinematik clear: slow-mo, banner, player jalan keluar arena, baru shop.
func _wave_clear_cine(_idx: int) -> void:
	state = ST_FIGHT
	player.controls_locked = true
	player.attack_locked = true
	hitstop_active = false
	Engine.time_scale = 1.0
	hitstop(0.25, 1.0)
	_show_combat_text("WAVE CLEAR!")
	await get_tree().create_timer(1.05, true, false, true).timeout
	if not is_inside_tree():
		return
	player.facing = 1
	player.sprite.flip_h = false
	player.sprite.play("walk")
	var tween := create_tween()
	tween.tween_property(player, "position:x", 1360.0, 1.2)
	await tween.finished
	if not is_inside_tree():
		return
	while get_tree().paused:
		await get_tree().create_timer(0.1, true, false, true).timeout
	_open_shop()
	_refresh_counters()


func _on_enemy_died(e: Dummy) -> void:
	if state != ST_FIGHT:
		return
	run_manager.add_money(e.money_value)
	run_manager.add_score(e.money_value * 3)
	add_shake(0.25)
	hitstop(0.1, 0.1)
	Sfx.play_sfx("punch_h", -2.0, 1.0, 0.08)


func _on_boss_hp(hp: int, max_hp: int) -> void:
	boss_label.text = "BOSS HP: %d/%d" % [hp, max_hp]
	_boss_frac = float(hp) / float(maxi(max_hp, 1))
	_fit_boss_bar()


func _fit_boss_bar() -> void:
	if boss_bar_fill == null:
		return
	boss_bar_fill.size = Vector2(400.0 * _boss_frac, 14)


func _set_boss_visible(v: bool) -> void:
	boss_label.visible = v
	if boss_bar_bg != null:
		boss_bar_bg.visible = v
	if boss_bar_fill != null:
		boss_bar_fill.visible = v


## Badge kanan-atas: kombo apa yang di-seal boss (kalau ada).
func _refresh_seal() -> void:
	var sealed: int = combat_manager.sealed_hand
	if sealed < 0:
		seal_badge.visible = false
		seal_text.visible = false
		return
	seal_text.text = "SEALED: %s" % wave_manager.seal_name(sealed)
	seal_badge.visible = true
	seal_text.visible = true


func _open_shop() -> void:
	state = ST_SHOP
	player.controls_locked = true
	player.attack_locked = true
	mode_label.visible = false
	Sfx.play_sfx("open", -6.0)
	Sfx.play_sfx("shuffle", -8.0)
	var best := last_best_type
	if hand_manager.hand.size() < 2:
		best = PokerEvaluator.PAIR
	shop_ui.open_shop(best)


func _on_shop_closed() -> void:
	if not _nav_guard():
		return
	Sfx.play_sfx("click", -10.0)
	_start_wave(run_manager.wave_index + 1)


func _process(_delta: float) -> void:
	if player == null:
		return
	# Screenshake decay (jalan di semua state).
	if trauma > 0.0 and camera != null:
		trauma = maxf(trauma - _delta * 1.6, 0.0)
		var s := trauma * trauma * 22.0
		camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))
	elif camera != null:
		camera.offset = Vector2.ZERO
	if state == ST_MENU:
		return
	if state == ST_SHOP:
		for i in range(6):
			if Input.is_physical_key_pressed(KEY_1 + i) and not _num_was(i):
				shop_ui.buy_index(i)
		_num_track()
		if Input.is_action_just_pressed("cashin"):
			shop_ui.close_shop()
		return
	if state != ST_FIGHT and state != ST_TUTORIAL or player.dead:
		return
	var held := Input.is_action_pressed("select_mode")
	player.attack_locked = held
	mode_label.visible = held
	if held != select_was_held:
		select_was_held = held
		_refresh_status()
	if held:
		for i in range(6):
			if Input.is_action_just_pressed("slot_%d" % (i + 1)):
				hand_manager.toggle_select(i)
	else:
		if Input.is_action_just_pressed("cashin"):
			combat_manager.try_cash_in()
		if Input.is_action_just_pressed("discard"):
			_quick_discard()
	# Di mode pilih, buang via tombol R saja.
	var r_down := Input.is_physical_key_pressed(KEY_R)
	if held and r_down and not r_was_down:
		_quick_discard()
	r_was_down = r_down


## Edge-detection tombol angka 1-6 (shop).
func _num_was(i: int) -> bool:
	return num_was_down[i]


func _num_track() -> void:
	for i in range(6):
		num_was_down[i] = Input.is_physical_key_pressed(KEY_1 + i)


## Buang kartu terpilih (jatah 3x per wave); kalau kosong, buang 1 tertua.
func _quick_discard() -> void:
	if not run_manager.can_discard():
		_on_cash_failed("BUANG HABIS!")
		return
	var sel := hand_manager.get_selected_cards()
	if sel.is_empty() and not hand_manager.hand.is_empty():
		sel = [hand_manager.hand[0]]
	if not sel.is_empty():
		hand_manager.remove_cards(sel)
		hand_manager.clear_selection()
		run_manager.use_discard()
		jokers.on_discard(player)
		Sfx.play_sfx("click", -10.0)


func _on_best_hand(hand_name: String, hand_type: int) -> void:
	last_best_name = hand_name
	last_best_type = hand_type
	if not select_was_held:
		hand_ui.set_best_hand(hand_name, hand_type)


func _on_selection(sel: Array) -> void:
	hand_ui.set_selected_cards(sel)
	_refresh_status()
	if not sel.is_empty():
		Sfx.play_sfx("place", -8.0)


## Status di atas kartu: preview seleksi saat mode pilih, best-hand biasa.
func _refresh_status() -> void:
	var sel := hand_manager.get_selected_cards()
	if select_was_held:
		if sel.size() >= 2:
			var res := PokerEvaluator.evaluate(sel)
			hand_ui.set_status("%s (%d) — LEPAS TAB + E = CASH!" % [res["name"], sel.size()], true)
		elif sel.size() == 1:
			hand_ui.set_status("PILIH 1 LAGI… (min 2)", false)
		else:
			hand_ui.set_status("TAHAN TAB + 1-6 = toggle", false)
	else:
		hand_ui.set_best_hand(last_best_name, 0)


func _on_cash_resolved(hand_name: String, damage: int, targets_hit: int) -> void:
	add_shake(0.5)
	hitstop(0.15, 0.09)
	Sfx.play_sfx("confirm", -4.0)
	Sfx.play_sfx("punch_h", -2.0, 1.0, 0.05)
	if targets_hit > 0:
		combat_label.add_theme_color_override("font_color", Color("ffd94d"))
		_show_combat_text("%s! %d DMG → %d TARGET" % [hand_name, damage, targets_hit])
	else:
		combat_label.add_theme_color_override("font_color", Color("ff7b7b"))
		_show_combat_text("%s! MISS…" % hand_name)
	flash_rect.color = Color(1, 0.9, 0.4, 0.14)
	var ftween := create_tween()
	ftween.tween_property(flash_rect, "color", Color(1, 0.9, 0.4, 0), 0.18)
	_refresh_status()


func _on_cash_failed(reason: String) -> void:
	_show_combat_text(reason)
	Sfx.play_sfx("error", -6.0)


func _show_combat_text(text: String) -> void:
	combat_label.text = text
	combat_label.modulate = Color(1, 1, 1, 1)
	combat_label.pivot_offset = combat_label.size * 0.5
	combat_label.scale = Vector2(1.25, 1.25)
	var pop := create_tween()
	pop.tween_property(combat_label, "scale", Vector2.ONE, 0.18)
	if combat_tween and combat_tween.is_valid():
		combat_tween.kill()
	combat_tween = create_tween()
	combat_tween.tween_interval(1.2)
	combat_tween.tween_property(combat_label, "modulate", Color(1, 1, 1, 0), 0.5)


func _refresh_hud(hp: int, max_hp: int) -> void:
	player_hp_label.text = "PLAYER HP: %d/%d" % [hp, max_hp]
	var frac := float(hp) / float(maxi(max_hp, 1))
	hp_bar_fill.size = Vector2(280.0 * frac, 16)
	if frac < 0.3:
		hp_bar_fill.color = Color("e04040")
	elif frac < 0.6:
		hp_bar_fill.color = Color("e0a040")
	else:
		hp_bar_fill.color = Color("55d66b")
	if hp < last_hp:
		add_shake(0.6)
		hitstop(0.3, 0.06)
		Sfx.play_sfx("punch_m", -4.0, 0.75, 0.05)
	last_hp = hp
	if hp <= 0 and state == ST_FIGHT:
		_game_over()


func _on_combo(stage: int) -> void:
	var names := ["-", "JAB 1", "JAB 2", "FINISHER"]
	combo_label.text = "JAB: %s" % names[clampi(stage, 0, 3)]
