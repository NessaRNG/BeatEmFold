class_name StageBg
extends Node2D
## 3 stage prosedural: 0=ALLEY (gang malam), 1=ROOFTOP (senja), 2=BAR (interior).
## Ganti per wave kind via set_theme(). Lane gameplay tidak berubah.

var rng := RandomNumberGenerator.new()
var theme := -1
var flicker_t := 0.0
var flicker_nodes: Array = []
var flicker_base: Array = []


func _ready() -> void:
	set_theme(0, 0)


func set_theme(t: int, loop: int = 0) -> void:
	if t == theme and get_child_count() > 0:
		return
	theme = t
	for c in get_children():
		c.queue_free()
	flicker_nodes.clear()
	flicker_base.clear()
	rng.seed = 7 + t * 101 + loop * 13
	match t:
		1:
			_build_rooftop()
		2:
			_build_bar()
		_:
			_build_alley()


func _px(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _sprite(img: Image, pos: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = _tex(img)
	sp.centered = false
	sp.position = pos
	add_child(sp)
	return sp


func _rect(pos: Vector2, sz: Vector2, c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.position = pos
	r.size = sz
	add_child(r)
	return r


func _glow_poly(pts: PackedVector2Array, c: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.color = c
	p.polygon = pts
	add_child(p)
	return p


func _octagon(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(8):
		var a := TAU * k / 8.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _neon_box(pos: Vector2, text: String, pink: Color, glow_c: Color) -> void:
	var n := Node2D.new()
	n.name = "Neon"
	n.position = pos
	var glow := ColorRect.new()
	glow.color = glow_c
	glow.position = Vector2(-15, -12)
	glow.size = Vector2(220, 92)
	n.add_child(glow)
	var box := ColorRect.new()
	box.color = Color("1a0f1e")
	box.position = Vector2.ZERO
	box.size = Vector2(190, 68)
	n.add_child(box)
	for b in [
		Rect2(Vector2.ZERO, Vector2(190, 3)), Rect2(Vector2(0, 65), Vector2(190, 3)),
		Rect2(Vector2.ZERO, Vector2(3, 68)), Rect2(Vector2(187, 0), Vector2(3, 68))]:
		var tube := ColorRect.new()
		tube.color = pink
		tube.position = b.position
		tube.size = b.size
		n.add_child(tube)
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 30)
	lb.add_theme_color_override("font_color", Color("ffe3f7"))
	lb.position = Vector2(0, 8)
	lb.size = Vector2(190, 52)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_child(lb)
	add_child(n)
	flicker_nodes.append(n)
	flicker_base.append(1.0)


## Stack 3 layer original (far -> mid -> near). Filter NEAREST, tanpa mipmap.
func _layer(stage: String, name: String) -> void:
	var tex := load("res://assets/backgrounds/original/%s_%s.png" % [stage, name]) as Texture2D
	if tex == null:
		return
	var r := TextureRect.new()
	r.texture = tex
	r.position = Vector2.ZERO
	r.size = Vector2(1280, 720)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


func _add_lamp() -> void:
	var lamp := Node2D.new()
	lamp.name = "Lamp"
	add_child(lamp)
	var pole := ColorRect.new()
	pole.color = Color("0d0d14")
	pole.position = Vector2(1190, 170)
	pole.size = Vector2(14, 390)
	lamp.add_child(pole)
	var arm := ColorRect.new()
	arm.color = Color("0d0d14")
	arm.position = Vector2(1150, 170)
	arm.size = Vector2(54, 12)
	lamp.add_child(arm)
	var bulb := ColorRect.new()
	bulb.color = Color("ffe9a8")
	bulb.position = Vector2(1146, 182)
	bulb.size = Vector2(12, 10)
	lamp.add_child(bulb)
	_glow_poly(PackedVector2Array([Vector2(1152, 192), Vector2(1090, 600), Vector2(1214, 600)]),
		Color(1, 0.9, 0.6, 0.07))


# --- 0: ALLEY (layer original + neon flicker) ---
func _build_alley() -> void:
	_layer("alley", "far")
	_layer("alley", "mid")
	_layer("alley", "near")
	_neon_box(Vector2(830, 200), "K.O. BAR", Color("ff5fd2"), Color(1, 0.25, 0.75, 0.16))
	_neon_box(Vector2(180, 260), "24H", Color("5affd2"), Color(0.2, 1, 0.8, 0.12))
	_add_lamp()



# --- 1: ROOFTOP (layer original + neon flicker) ---
func _build_rooftop() -> void:
	_layer("rooftop", "far")
	_layer("rooftop", "mid")
	_layer("rooftop", "near")
	_neon_box(Vector2(830, 215), "ROOFTOP", Color("ffb14d"), Color(1, 0.6, 0.2, 0.16))


# --- 2: BAR (layer original + neon flicker) ---
func _build_bar() -> void:
	_layer("bar", "far")
	_layer("bar", "mid")
	_layer("bar", "near")
	_neon_box(Vector2(545, 300), "K.O. CLUB", Color("5affd2"), Color(0.2, 1, 0.8, 0.14))


func _process(delta: float) -> void:
	if flicker_nodes.is_empty():
		return
	flicker_t += delta
	var drop := 0.35 if sin(flicker_t * 1.7) > 0.985 else 1.0
	var j := 0.86 + 0.1 * sin(flicker_t * 13.0) + 0.04 * sin(flicker_t * 31.0)
	for n in flicker_nodes:
		if is_instance_valid(n):
			n.modulate.a = j * drop
