class_name HandUI
extends Control
## 6 slot kartu bawah-tengah + indikator "PAIR READY!" (GDD #7).
## Layout RECT EKSPLISIT dari viewport (tanpa anchor): anchor butuh parent
## Control ber-size nyata, yang tidak ada saat UI di bawah Node2D/CanvasLayer.

const SLOT_W := 78.0
const SLOT_H := 108.0
const SLOT_GAP := 10.0

var slot_panels: Array[Panel] = []
var slot_faces: Array[TextureRect] = []
var slot_labels: Array[Label] = []
var best_label: Label
var row: HBoxContainer

var sb_full: StyleBoxFlat
var sb_empty: StyleBoxFlat
var sb_selected: StyleBoxFlat

var cards_shown: Array = []
var selected_shown: Array = []
var face_cache := {}
var back_tex: Texture2D
var slot_tweens: Array[Tween] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_full = UiTheme.panel_framed(Color("0f0e18"), Color("6b5a8e"), 2, 9)
	sb_empty = UiTheme.panel_style(Color("0a0a12cc"), Color("26263a"), 2, 9)
	sb_selected = UiTheme.panel_framed(Color("241c08"), Color("ffd94d"), 3, 10)
	sb_selected.shadow_color = Color("ffd94d88")
	sb_selected.shadow_size = 8

	best_label = Label.new()
	UiTheme.style_title(best_label, 26, Color("7bff9e"))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(best_label)

	row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(SLOT_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(6):
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
		panel.add_theme_stylebox_override("panel", sb_empty)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.position = Vector2(11, 16)
		face.size = Vector2(56, 56)
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(face)
		# Pojok kiri-atas: rank + suit besar, biar kebaca tanpa buka kartu penuh.
		var corner := Label.new()
		corner.name = "Corner"
		corner.position = Vector2(2, 1)
		corner.size = Vector2(30, 30)
		corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiTheme.style_title(corner, 20, Color.WHITE)
		corner.text = ""
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(corner)
		var label := Label.new()
		label.name = "Caption"
		label.position = Vector2(0, 76)
		label.size = Vector2(SLOT_W, 26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiTheme.style_body(label, 17, Color(1, 1, 1, 0.35))
		label.text = "·"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		var hint := Label.new()
		hint.name = "Hint"
		hint.position = Vector2(SLOT_W - 22, 1)
		hint.size = Vector2(20, 16)
		UiTheme.style_body(hint, 13, Color(1, 1, 1, 0.5))
		hint.text = str(i + 1)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(hint)
		row.add_child(panel)
		slot_panels.append(panel)
		slot_faces.append(face)
		slot_labels.append(label)
	add_child(row)

	set_status("HIGH CARD", false)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vp := get_viewport_rect().size
	position = Vector2.ZERO
	size = vp
	best_label.position = Vector2((vp.x - 500.0) * 0.5, vp.y - 196.0)
	best_label.size = Vector2(500, 40)
	var row_w := 6.0 * SLOT_W + 5.0 * SLOT_GAP
	row.position = Vector2((vp.x - row_w) * 0.5, vp.y - 148.0)
	row.size = Vector2(row_w, SLOT_H + 8.0)


func set_hand(cards: Array) -> void:
	var prev: Array = cards_shown
	cards_shown = cards.duplicate()
	_refresh_slots()
	for i in range(cards_shown.size()):
		if not prev.has(cards_shown[i]):
			slot_panels[i].pivot_offset = Vector2(SLOT_W * 0.5, SLOT_H * 0.5)
			UiAnim.punch(slot_panels[i], 1.22, 0.14)


func set_selected_cards(sel: Array) -> void:
	selected_shown = sel.duplicate()
	_refresh_slots()


func _face_for(c: CardData) -> Texture2D:
	var path := c.face_path()
	if not face_cache.has(path):
		face_cache[path] = load(path)
	return face_cache[path]


func _back() -> Texture2D:
	if back_tex == null:
		back_tex = load("res://assets/cards/card_back.png")
	return back_tex


func _refresh_slots() -> void:
	for i in range(slot_labels.size()):
		var selected: bool = i < cards_shown.size() and cards_shown[i] in selected_shown
		var corner: Label = slot_panels[i].get_node("Corner")
		if i < cards_shown.size():
			var c: CardData = cards_shown[i]
			slot_faces[i].texture = _face_for(c)
			slot_faces[i].modulate = Color.WHITE
			slot_labels[i].text = c.short()
			corner.text = "%s%s" % [CardData.rank_label(c.rank), CardData.suit_symbol(c.suit)]
			if CardData.is_red(c.suit):
				var red := Color("ff7b7b")
				slot_labels[i].add_theme_color_override("font_color", red)
				corner.add_theme_color_override("font_color", red)
			else:
				slot_labels[i].add_theme_color_override("font_color", Color("f2f2f2"))
				corner.add_theme_color_override("font_color", Color("dfe8ff"))
			if selected:
				slot_panels[i].add_theme_stylebox_override("panel", sb_selected)
			else:
				slot_panels[i].add_theme_stylebox_override("panel", sb_full)
			var target_y := -18.0 if selected else 0.0
			var target_scale := 1.07 if selected else 1.0
			slot_panels[i].pivot_offset = Vector2(SLOT_W * 0.5, SLOT_H)
			var tween := slot_panels[i].create_tween()
			tween.tween_property(slot_panels[i], "position:y", target_y, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(slot_panels[i], "scale", Vector2(target_scale, target_scale), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			corner.text = ""
			slot_faces[i].texture = _back()
			slot_faces[i].modulate = Color(1, 1, 1, 0.3)
			slot_labels[i].text = "·"
			var tween := slot_panels[i].create_tween()
			tween.tween_property(slot_panels[i], "scale", Vector2.ONE, 0.16)
			slot_labels[i].add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			slot_panels[i].add_theme_stylebox_override("panel", sb_empty)
			slot_panels[i].position.y = 0.0


func set_best_hand(hand_name: String, _hand_type: int) -> void:
	if hand_name == "" or hand_name == "HIGH CARD":
		set_status("HIGH CARD", false)
	else:
		set_status("%s READY!" % hand_name, true)


## Teks status di atas kartu: best-hand biasa atau preview seleksi.
func set_status(text: String, is_ready: bool) -> void:
	best_label.text = text
	if is_ready:
		best_label.add_theme_color_override("font_color", Color("7bff9e"))
	else:
		best_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
