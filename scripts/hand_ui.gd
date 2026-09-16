class_name HandUI
extends Control
## 6 slot kartu bawah-tengah + indikator "PAIR READY!" (GDD #7).
## Layout RECT EKSPLISIT dari viewport (tanpa anchor): anchor butuh parent
## Control ber-size nyata, yang tidak ada saat UI di bawah Node2D/CanvasLayer.

const SLOT_W := 64.0
const SLOT_H := 90.0
const SLOT_GAP := 8.0

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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_full = UiTheme.panel_style(Color(0.05, 0.05, 0.09, 0.85), Color("3a3a55"), 1)
	sb_empty = UiTheme.panel_style(Color(0.04, 0.04, 0.07, 0.6), Color("23232e"), 1)
	sb_selected = UiTheme.panel_style(Color(0.16, 0.13, 0.05, 0.92), Color("ffd94d"), 2)

	best_label = Label.new()
	UiTheme.style_title(best_label, 22)
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
		face.position = Vector2(4, 6)
		face.size = Vector2(56, 56)
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(face)
		var label := Label.new()
		label.position = Vector2(0, 62)
		label.size = Vector2(SLOT_W, 26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiTheme.style_body(label, 15, Color(1, 1, 1, 0.3))
		label.text = "·"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		var hint := Label.new()
		hint.position = Vector2(3, 1)
		hint.size = Vector2(20, 16)
		UiTheme.style_body(hint, 12, Color(1, 1, 1, 0.4))
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
		if i < cards_shown.size():
			var c: CardData = cards_shown[i]
			slot_faces[i].texture = _face_for(c)
			slot_faces[i].modulate = Color.WHITE
			slot_labels[i].text = c.short()
			if CardData.is_red(c.suit):
				slot_labels[i].add_theme_color_override("font_color", Color("ff7b7b"))
			else:
				slot_labels[i].add_theme_color_override("font_color", Color("f2f2f2"))
			if selected:
				slot_panels[i].add_theme_stylebox_override("panel", sb_selected)
			else:
				slot_panels[i].add_theme_stylebox_override("panel", sb_full)
		else:
			slot_faces[i].texture = _back()
			slot_faces[i].modulate = Color(1, 1, 1, 0.3)
			slot_labels[i].text = "·"
			slot_labels[i].add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
			slot_panels[i].add_theme_stylebox_override("panel", sb_empty)


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
