class_name ShopUI
extends Control
## Kios simpel: 2 kartu (tambah/hapus kartu deck), tombol LANJUT.
## Klik / 1-2, E lanjut.

signal shop_closed

const ADD_CARD_PRICE := 3
const REMOVE_CARD_PRICE := 3

const CARD_W := 210.0
const CARD_H := 250.0
const CARD_GAP := 20.0

var run: RunManager
var deck: Deck
var hand_manager: HandManager

var dim: ColorRect
var title_label: Label
var sub_label: Label
var coin: Panel
var money_label: Label
var rows: Array = [] # [{btn: Button}]; btn berisi icon/nama/desc/harga
var continue_button: Button
var open := false

## Power-up: panel PILIHAN terpisah (tidak masuk rows, jaga rows.size()==2).
var powerup_frame: Panel
var powerup_buttons: Array = []
var powerup_picks: Array = []
var powerup_picked := false
var powerup_title: Label
var powerup_note: Label

const PU_FRAME_W := 760.0
const PU_FRAME_H := 252.0
const PU_CARD_W := 224.0
const PU_CARD_H := 152.0
const PU_CARD_GAP := 20.0

## Warna per kategori power-up.
static func _cat_color(cat: String) -> Color:
	match cat:
		"TINJU":
			return Color("ff6b5a")
		"GERAK":
			return Color("5ad9ff")
		"AFINITAS":
			return Color("7bff9e")
		"FINISHER":
			return Color("ffd94d")
		_:
			return Color("b06bff")


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	title_label = _mk_label(34, Color("ff5fd2"))
	add_child(title_label)
	sub_label = _mk_label(15, Color(1, 1, 1, 0.7))
	add_child(sub_label)
	coin = Panel.new()
	coin.add_theme_stylebox_override("panel",
		UiTheme.panel_style(Color("ffd94d"), Color("a87f1f"), 2, 15))
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coin)
	var coinsym := Label.new()
	coinsym.text = "$"
	UiTheme.style_title(coinsym, 18, Color("5a430c"))
	coinsym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coinsym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coinsym.set_anchors_preset(Control.PRESET_FULL_RECT)
	coinsym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.add_child(coinsym)
	money_label = _mk_label(24, Color("7bff9e"))
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(money_label)
	# Frame power-up: wadah solid untuk pilihan upgrade.
	powerup_frame = Panel.new()
	powerup_frame.add_theme_stylebox_override("panel",
		UiTheme.panel_framed(Color("120c1ceb"), Color("b06bff"), 3, 16))
	powerup_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(powerup_frame)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _mk_label(fs: int, color: Color) -> Label:
	var lb := Label.new()
	UiTheme.style_title(lb, fs, color)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb


func setup(r: RunManager, d: Deck, hm: HandManager) -> void:
	run = r
	deck = d
	hand_manager = hm


func open_shop() -> void:
	open = true
	visible = true
	refresh(true)
	roll_powerups()


func close_shop() -> void:
	open = false
	visible = false
	shop_closed.emit()


## Tampilkan 3 pilihan power-up gratis (satu dipilih). Dipanggil main.gd saat shop buka.
func roll_powerups() -> void:
	powerup_picked = false
	powerup_picks = run.roll_powerup_choices() if run != null else []
	_build_powerup_panel()


func pick_powerup(i: int) -> void:
	if powerup_picked or i < 0 or i >= powerup_picks.size() or run == null:
		return
	run.add_powerup(powerup_picks[i])
	powerup_picked = true
	var b: Button = powerup_buttons[i]
	var def := PowerUpData.get_def(powerup_picks[i])
	var nm: Label = b.get_node("Name")
	nm.text = def["name"]
	nm.add_theme_color_override("font_color", Color("7bff9e"))
	var badge: Label = b.get_node("Status")
	badge.text = "✓ DIPILIH"
	badge.add_theme_color_override("font_color", Color("7bff9e"))
	b.disabled = true
	for j in range(powerup_buttons.size()):
		if j != i:
			powerup_buttons[j].disabled = true
			powerup_buttons[j].modulate = Color(0.45, 0.45, 0.45, 0.8)
	if powerup_note != null:
		powerup_note.text = "✓ %s didapat — lanjut ke ronde berikutnya" % def["name"]


func _mk_powerup_button(idx: int, id: String) -> Button:
	var def := PowerUpData.get_def(id)
	var cat: String = def["cat"]
	var col := _cat_color(cat)
	var stack := run.powerup_count(id) if run != null else 0
	var b := Button.new()
	b.custom_minimum_size = Vector2(PU_CARD_W, PU_CARD_H)
	b.add_theme_stylebox_override("normal", UiTheme.panel_framed(Color("1b1630"), col, 2, 10))
	b.add_theme_stylebox_override("hover", UiTheme.panel_framed(Color("2a2050"), Color.WHITE, 3, 10))
	b.add_theme_stylebox_override("pressed", UiTheme.panel_framed(Color("332860"), col, 3, 10))
	# Key hint kiri-atas.
	var key := Label.new()
	UiTheme.style_body(key, 13, Color(1, 1, 1, 0.6))
	key.text = "[%d]" % (idx + 7)
	key.position = Vector2(10, 6)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(key)
	# Category badge kanan-atas.
	var cbadge := Label.new()
	UiTheme.style_title(cbadge, 14, col)
	cbadge.text = cat
	cbadge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cbadge.position = Vector2(40, 4)
	cbadge.size = Vector2(PU_CARD_W - 50, 20)
	cbadge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(cbadge)
	# Nama (besar).
	var nm := Label.new()
	nm.name = "Name"
	UiTheme.style_title(nm, 19, Color("ffe066"))
	nm.text = def["name"]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(8, 38)
	nm.size = Vector2(PU_CARD_W - 16, 30)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(nm)
	# Deskripsi efek.
	var desc := Label.new()
	UiTheme.style_body(desc, 16, Color(1, 1, 1, 0.92))
	desc.text = def["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.position = Vector2(8, 62)
	desc.size = Vector2(PU_CARD_W - 16, 40)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(desc)
	# Stack badge bawah.
	var sbadge := Label.new()
	UiTheme.style_body(sbadge, 14, col)
	sbadge.text = "STACK x%d" % stack if stack > 0 else "BARU"
	sbadge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sbadge.position = Vector2(8, PU_CARD_H - 26)
	sbadge.size = Vector2(PU_CARD_W - 16, 22)
	sbadge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(sbadge)
	# Status (DIPILIH) — disembunyikan sampai dipilih.
	var status := Label.new()
	status.name = "Status"
	UiTheme.style_title(status, 16, Color("7bff9e"))
	status.text = ""
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.position = Vector2(8, PU_CARD_H - 50)
	status.size = Vector2(PU_CARD_W - 16, 22)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(status)
	b.pressed.connect(func() -> void: pick_powerup(idx))
	return b


func _build_powerup_panel() -> void:
	for b in powerup_buttons:
		b.queue_free()
	powerup_buttons.clear()
	for c in powerup_frame.get_children():
		c.queue_free()
	powerup_title = _mk_label(22, Color("d9a6ff"))
	powerup_title.text = "PILIH 1 POWER-UP  ·  GRATIS"
	powerup_frame.add_child(powerup_title)
	powerup_note = _mk_label(15, Color(1, 1, 1, 0.85))
	powerup_note.text = "Klik kartu atau tekan 7 / 8 / 9 — efek aktif mulai ronde ini"
	powerup_frame.add_child(powerup_note)
	for i in range(powerup_picks.size()):
		var b := _mk_powerup_button(i, powerup_picks[i])
		powerup_frame.add_child(b)
		powerup_buttons.append(b)
	_layout_powerups()


func _layout_powerups() -> void:
	var pad := 14.0
	if powerup_title != null:
		powerup_title.position = Vector2(pad, 12)
		powerup_title.size = Vector2(PU_FRAME_W - pad * 2, 34)
	var n := float(maxi(powerup_buttons.size(), 1))
	var total := n * PU_CARD_W + (n - 1.0) * PU_CARD_GAP
	var x := (PU_FRAME_W - total) * 0.5
	for b in powerup_buttons:
		b.position = Vector2(x, 54)
		b.size = Vector2(PU_CARD_W, PU_CARD_H)
		x += PU_CARD_W + PU_CARD_GAP
	if powerup_note != null:
		powerup_note.position = Vector2(pad, PU_FRAME_H - 32)
		powerup_note.size = Vector2(PU_FRAME_W - pad * 2, 24)


func _layout() -> void:
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	dim.position = Vector2.ZERO
	dim.size = vp
	title_label.text = "K.O. SHOP"
	title_label.position = Vector2(0, 26)
	title_label.size = Vector2(vp.x, 44)
	sub_label.text = "WAVE CLEAR! Borong sebelum ronde berikut."
	sub_label.position = Vector2(0, 70)
	sub_label.size = Vector2(vp.x, 22)
	coin.position = Vector2(vp.x - 220, 30)
	coin.size = Vector2(30, 30)
	money_label.text = "Uang: $%d" % (run.money if run != null else 0)
	money_label.position = Vector2(vp.x - 184, 28)
	money_label.size = Vector2(170, 34)
	var n := float(maxi(rows.size(), 1))
	var total_w := n * CARD_W + (n - 1.0) * CARD_GAP
	var x := (vp.x - total_w) * 0.5
	var y := 108.0
	for r in rows:
		var btn: Button = r["btn"]
		btn.position = Vector2(x, y)
		btn.size = Vector2(CARD_W, CARD_H)
		x += CARD_W + CARD_GAP
	# Frame power-up tepat di bawah kartu beli.
	var frame_y := y + CARD_H + 18.0
	if powerup_frame != null:
		powerup_frame.position = Vector2((vp.x - PU_FRAME_W) * 0.5, frame_y)
		powerup_frame.size = Vector2(PU_FRAME_W, PU_FRAME_H)
	# Tombol Lanjut tepat di bawah frame (CONTEN shopboards di area y<720,
	# walaupun viewport expand lebih tinggi — jangan anchor ke bawah viewport).
	if continue_button != null:
		var cont_y := frame_y + PU_FRAME_H + 18.0
		continue_button.position = Vector2((vp.x - 460.0) * 0.5, cont_y)
		continue_button.size = Vector2(460, 58)
		continue_button.add_theme_stylebox_override("normal",
			UiTheme.panel_framed(Color("14261a"), Color("55d66b"), 3, 12))
		continue_button.add_theme_stylebox_override("hover",
			UiTheme.panel_framed(Color("1d3a24"), Color("7bff9e"), 3, 12))
	_layout_powerups()


func refresh(animate: bool = false) -> void:
	for r in rows:
		(r["btn"] as Button).queue_free()
	rows.clear()
	if continue_button != null:
		continue_button.queue_free()
	title_label.text = "K.O. SHOP"
	money_label.text = "Uang: $%d" % run.money
	var idx := 0
	var ap := _price(ADD_CARD_PRICE)
	_add_card(idx, "res://assets/icons/ico_add.png", Color("55d66b"), "Tambah kartu",
		"1 kartu acak\nmasuk deck",
		"$%d" % ap, run.money < ap, "_buy_add_card", [ap])
	idx += 1
	var rp := _price(REMOVE_CARD_PRICE)
	_add_card(idx, "res://assets/icons/ico_remove.png", Color("ff7b7b"), "Buang kartu",
		"Hapus kartu\nterlemah",
		"$%d" % rp, run.money < rp, "_buy_remove_card", [rp])
	continue_button = KeyButton.new()
	continue_button.setup("Lanjut", KEY_L)
	continue_button.add_theme_font_size_override("font_size", 20)
	continue_button.add_theme_stylebox_override("normal",
		UiTheme.panel_style(Color("14261a"), Color("55d66b"), 2, 7))
	continue_button.add_theme_stylebox_override("hover",
		UiTheme.panel_style(Color("1d3a24"), Color("7bff9e"), 2, 7))
	continue_button.add_theme_stylebox_override("pressed",
		UiTheme.panel_style(Color("275233"), Color("ffd94d"), 2, 7))
	continue_button.pressed.connect(func() -> void: close_shop())
	add_child(continue_button)
	_layout()
	if animate:
		var i := 0
		for r in rows:
			UiAnim.rise_in(r["btn"], 30.0, 0.25, 0.06 * i)
			i += 1
		UiAnim.rise_in(continue_button, 24.0, 0.25, 0.4)


func _price(base: int) -> int:
	# Harga naik 25%/loop endless.
	var loop := 0
	if run != null:
		loop = int(run.wave_index / 3.0)
	return roundi(base * (1.0 + 0.25 * loop))


func _split_desc(s: String) -> String:
	# Bungkus manual 2 baris agar muat di kartu 190px.
	var words := s.split(" ")
	if words.size() <= 2:
		return s
	var mid := int(words.size() / 2.0)
	return " ".join(words.slice(0, mid)) + "\n" + " ".join(words.slice(mid))


func _add_card(idx: int, icon_path: String, icolor: Color, title: String, desc: String, price: String, disabled: bool, method: String, args: Array) -> void:
	var btn := Button.new()
	btn.text = ""
	btn.disabled = disabled
	btn.add_theme_stylebox_override("normal",
		UiTheme.panel_framed(Color("141126f2"), icolor, 2, 12))
	btn.add_theme_stylebox_override("hover",
		UiTheme.panel_framed(Color("201a30f5"), Color.WHITE, 3, 12))
	btn.add_theme_stylebox_override("pressed",
		UiTheme.panel_framed(Color("2a2240"), Color("ffd94d"), 3, 12))
	add_child(btn)
	var icon := Panel.new()
	icon.add_theme_stylebox_override("panel",
		UiTheme.panel_style(Color(0.1, 0.09, 0.15, 1), icolor, 2, 8))
	icon.position = Vector2((CARD_W - 56.0) * 0.5, 16)
	icon.size = Vector2(56, 56)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glyph := TextureRect.new()
	glyph.texture = load(icon_path)
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(glyph)
	btn.add_child(icon)
	var key := Label.new()
	key.text = "[%d]" % (idx + 1)
	UiTheme.style_body(key, 14, Color(1, 1, 1, 0.55))
	key.position = Vector2(10, 8)
	key.size = Vector2(40, 20)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(key)
	var name_lb := Label.new()
	name_lb.text = title
	UiTheme.style_title(name_lb, 20, Color.WHITE)
	name_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lb.position = Vector2(8, 80)
	name_lb.size = Vector2(CARD_W - 16, 28)
	name_lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lb)
	var desc_lb := Label.new()
	desc_lb.text = _split_desc(desc)
	UiTheme.style_body(desc_lb, 17, Color(1, 1, 1, 0.9))
	desc_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lb.position = Vector2(8, 112)
	desc_lb.size = Vector2(CARD_W - 16, 120)
	desc_lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(desc_lb)
	var price_lb := Label.new()
	price_lb.text = price
	UiTheme.style_title(price_lb, 24, Color("7bff9e") if not disabled else Color("555560"))
	price_lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lb.position = Vector2(8, CARD_H - 56)
	price_lb.size = Vector2(CARD_W - 16, 36)
	price_lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(price_lb)
	if disabled:
		btn.modulate = Color(0.6, 0.6, 0.6, 0.85)
	match method:
		"_buy_add_card":
			btn.pressed.connect(func() -> void: _buy_add_card(args[0]))
		"_buy_remove_card":
			btn.pressed.connect(func() -> void: _buy_remove_card(args[0]))
	rows.append({"btn": btn})


func _buy_add_card(price: int) -> void:
	if not run.spend(price):
		return
	var c := CardData.new()
	c.rank = randi_range(5, 14)
	c.suit = randi_range(0, 3)
	deck.cards.append(c)
	deck.shuffle()
	Sfx.play_sfx("chips", -4.0)
	refresh()


func _buy_remove_card(price: int) -> void:
	if not run.spend(price):
		return
	var weakest = null
	for c in hand_manager.hand:
		if weakest == null or c.rank < weakest.rank:
			weakest = c
	if weakest == null:
		for c in deck.cards:
			if weakest == null or c.rank < weakest.rank:
				weakest = c
		if weakest != null:
			deck.cards.erase(weakest)
			Sfx.play_sfx("chips", -4.0)
	else:
		hand_manager.remove_cards([weakest])
		Sfx.play_sfx("chips", -4.0)
	refresh()


## Keyboard: 1-6 beli, dipanggil main saat shop buka.
func buy_index(i: int) -> void:
	if not open or i < 0 or i >= rows.size():
		return
	var btn: Button = rows[i]["btn"]
	if not btn.disabled:
		btn.pressed.emit()
