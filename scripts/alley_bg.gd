class_name AlleyBg
extends Node2D
## Gang malam prosedural (seed tetap): langit, gedung, tembok bata, neon
## "K.O. BAR" flicker, poster, pipa, dumpster, lampu + cone, aspal basah.

var rng := RandomNumberGenerator.new()
var neon: Node2D
var lamp_glow: Node2D
var neon_reflect: ColorRect
var lamp_reflect: ColorRect
var flicker_t := 0.0


func _ready() -> void:
	rng.seed = 7
	_build_sky()
	_build_wall()
	_build_props()
	_build_floor()


func _px(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _build_sky() -> void:
	var sky := Image.create(1280, 360, false, Image.FORMAT_RGBA8)
	for y in range(360):
		var t := float(y) / 360.0
		var c := Color("0b0e1f").lerp(Color("241a3a"), t * t)
		_px(sky, 0, y, 1280, 1, c)
	var bg := Sprite2D.new()
	bg.texture = _tex(sky)
	bg.centered = false
	bg.position = Vector2.ZERO
	add_child(bg)
	# Gedung jauh + jendela.
	var city := Image.create(1280, 170, false, Image.FORMAT_RGBA8)
	city.fill(Color(0, 0, 0, 0))
	var x := 0
	while x < 1280:
		var bw := rng.randi_range(90, 200)
		var bh := rng.randi_range(60, 165)
		_px(city, x, 170 - bh, bw, bh, Color("121627"))
		for wy in range(170 - bh + 8, 162, 16):
			for wx in range(x + 8, x + bw - 8, 16):
				if rng.randf() < 0.28:
					_px(city, wx, wy, 7, 9, Color(1, 0.85, 0.45, 0.8))
				elif rng.randf() < 0.2:
					_px(city, wx, wy, 7, 9, Color(0.25, 0.3, 0.45, 0.6))
		x += bw + rng.randi_range(4, 30)
	var city_sp := Sprite2D.new()
	city_sp.texture = _tex(city)
	city_sp.centered = false
	add_child(city_sp)
	# Bulan + glow.
	var moon := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	moon.fill(Color(0, 0, 0, 0))
	for py in range(96):
		for px2 in range(96):
			var d := Vector2(px2 - 48, py - 48).length()
			if d < 20.0:
				moon.set_pixel(px2, py, Color("e8ecff"))
			elif d < 44.0:
				moon.set_pixel(px2, py, Color(0.85, 0.9, 1.0, (44.0 - d) / 24.0 * 0.25))
	var moon_sp := Sprite2D.new()
	moon_sp.texture = _tex(moon)
	moon_sp.position = Vector2(600, 64)
	add_child(moon_sp)


func _build_wall() -> void:
	# Tembok bata 1280x260.
	var wall := Image.create(1280, 260, false, Image.FORMAT_RGBA8)
	wall.fill(Color("241d28"))
	var bh := 13
	var bw := 42
	var row := 0
	for y in range(0, 260, bh):
		var off := int(bw / 2.0) if row % 2 == 1 else 0
		var x := -bw
		while x < 1280:
			var v := rng.randf_range(-0.03, 0.05)
			_px(wall, x + off + 1, y + 1, bw - 2, bh - 2,
				Color(0.29 + v, 0.17 + v, 0.2 + v))
			x += bw
		row += 1
	var wall_sp := Sprite2D.new()
	wall_sp.texture = _tex(wall)
	wall_sp.centered = false
	wall_sp.position = Vector2(0, 170)
	add_child(wall_sp)
	# Dinding samping (lorong) lebih gelap.
	for sx in [0.0, 1160.0]:
		var side := ColorRect.new()
		side.color = Color(0, 0, 0, 0.5)
		side.position = Vector2(sx, 170)
		side.size = Vector2(120, 260)
		add_child(side)
		var edge := ColorRect.new()
		edge.color = Color(0, 0, 0, 0.65)
		edge.position = Vector2(sx + (116.0 if sx < 600.0 else 0.0), 170)
		edge.size = Vector2(4, 260)
		add_child(edge)
	_build_neon(Vector2(830, 215))
	_build_poster(Vector2(300, 250), Vector2(70, 92))
	_build_poster(Vector2(384, 268), Vector2(54, 72))
	_build_pipe(150.0)
	_build_pipe(1120.0)


func _build_neon(pos: Vector2) -> void:
	neon = Node2D.new()
	neon.name = "Neon"
	neon.position = pos
	var glow := ColorRect.new()
	glow.color = Color(1, 0.25, 0.75, 0.16)
	glow.position = Vector2(-15, -12)
	glow.size = Vector2(220, 92)
	neon.add_child(glow)
	var box := ColorRect.new()
	box.color = Color("1a0f1e")
	box.position = Vector2.ZERO
	box.size = Vector2(190, 68)
	neon.add_child(box)
	var pink := Color("ff5fd2")
	for b in [
		Rect2(Vector2.ZERO, Vector2(190, 3)), Rect2(Vector2(0, 65), Vector2(190, 3)),
		Rect2(Vector2.ZERO, Vector2(3, 68)), Rect2(Vector2(187, 0), Vector2(3, 68))]:
		var tube := ColorRect.new()
		tube.color = pink
		tube.position = b.position
		tube.size = b.size
		neon.add_child(tube)
	var lb := Label.new()
	lb.text = "K.O. BAR"
	lb.add_theme_font_size_override("font_size", 30)
	lb.add_theme_color_override("font_color", Color("ffe3f7"))
	lb.position = Vector2(0, 8)
	lb.size = Vector2(190, 52)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	neon.add_child(lb)
	add_child(neon)


func _build_poster(pos: Vector2, sz: Vector2) -> void:
	var border := ColorRect.new()
	border.color = Color("0d0d12")
	border.position = pos - Vector2(2, 2)
	border.size = sz + Vector2(4, 4)
	add_child(border)
	var paper := ColorRect.new()
	paper.color = Color("cfc8b0")
	paper.position = pos
	paper.size = sz
	add_child(paper)
	var ink := ColorRect.new()
	ink.color = Color("8a2f3c")
	ink.position = pos + Vector2(8, 10)
	ink.size = Vector2(sz.x - 16, 14)
	add_child(ink)
	var ink2 := ColorRect.new()
	ink2.color = Color("2b2b33")
	ink2.position = pos + Vector2(8, 30)
	ink2.size = Vector2(sz.x - 16, 4)
	add_child(ink2)
	var ink3 := ColorRect.new()
	ink3.color = Color("2b2b33")
	ink3.position = pos + Vector2(8, 38)
	ink3.size = Vector2(sz.x - 24, 4)
	add_child(ink3)


func _build_pipe(x: float) -> void:
	var pipe := ColorRect.new()
	pipe.color = Color("16161e")
	pipe.position = Vector2(x, 170)
	pipe.size = Vector2(26, 260)
	add_child(pipe)
	var hi := ColorRect.new()
	hi.color = Color(1, 1, 1, 0.08)
	hi.position = Vector2(x + 3, 170)
	hi.size = Vector2(4, 260)
	add_child(hi)


func _build_props() -> void:
	# Dumpster kiri.
	var dump := Node2D.new()
	dump.name = "Dumpster"
	var body := ColorRect.new()
	body.color = Color("23402e")
	body.position = Vector2(60, 470)
	body.size = Vector2(170, 100)
	dump.add_child(body)
	var lid := ColorRect.new()
	lid.color = Color("2c5340")
	lid.position = Vector2(54, 458)
	lid.size = Vector2(182, 16)
	dump.add_child(lid)
	for i in range(4):
		var ridge := ColorRect.new()
		ridge.color = Color(0, 0, 0, 0.3)
		ridge.position = Vector2(80 + i * 40, 478)
		ridge.size = Vector2(5, 84)
		dump.add_child(ridge)
	add_child(dump)
	# Kantong sampah.
	for b in [[250.0, 548.0, 22.0], [288.0, 556.0, 15.0]]:
		var bag := Polygon2D.new()
		bag.color = Color("101018")
		var pts := PackedVector2Array()
		for k in range(8):
			var a := TAU * k / 8.0
			pts.append(Vector2(b[0], b[1]) + Vector2(cos(a), sin(a)) * b[2])
		bag.polygon = pts
		add_child(bag)
	# Lampu kanan + cone cahaya.
	lamp_glow = Node2D.new()
	lamp_glow.name = "Lamp"
	var pole := ColorRect.new()
	pole.color = Color("0d0d14")
	pole.position = Vector2(1190, 170)
	pole.size = Vector2(14, 390)
	lamp_glow.add_child(pole)
	var arm := ColorRect.new()
	arm.color = Color("0d0d14")
	arm.position = Vector2(1150, 170)
	arm.size = Vector2(54, 12)
	lamp_glow.add_child(arm)
	var bulb := ColorRect.new()
	bulb.color = Color("ffe9a8")
	bulb.position = Vector2(1146, 182)
	bulb.size = Vector2(12, 10)
	bulb.name = "Bulb"
	lamp_glow.add_child(bulb)
	var cone := Polygon2D.new()
	cone.color = Color(1, 0.9, 0.6, 0.07)
	cone.polygon = PackedVector2Array([
		Vector2(1152, 192), Vector2(1090, 600), Vector2(1214, 600)])
	cone.name = "Cone"
	lamp_glow.add_child(cone)
	add_child(lamp_glow)


func _build_floor() -> void:
	# Aspal basah + noise.
	var fl := Image.create(1280, 290, false, Image.FORMAT_RGBA8)
	fl.fill(Color("151624"))
	for i in range(2200):
		var x := rng.randi_range(0, 1279)
		var y := rng.randi_range(0, 289)
		fl.set_pixel(x, y, Color(1, 1, 1, 0.03) if i % 2 == 0 else Color(0, 0, 0, 0.25))
	var fl_sp := Sprite2D.new()
	fl_sp.texture = _tex(fl)
	fl_sp.centered = false
	fl_sp.position = Vector2(0, 430)
	add_child(fl_sp)
	# Pantulan neon + lampu.
	neon_reflect = ColorRect.new()
	neon_reflect.color = Color(1, 0.25, 0.75, 0.09)
	neon_reflect.position = Vector2(830, 600)
	neon_reflect.size = Vector2(190, 60)
	add_child(neon_reflect)
	lamp_reflect = ColorRect.new()
	lamp_reflect.color = Color(1, 0.9, 0.6, 0.07)
	lamp_reflect.position = Vector2(1100, 600)
	lamp_reflect.size = Vector2(110, 60)
	add_child(lamp_reflect)


func _process(delta: float) -> void:
	flicker_t += delta
	var drop := 0.35 if sin(flicker_t * 1.7) > 0.985 else 1.0
	var j := 0.86 + 0.1 * sin(flicker_t * 13.0) + 0.04 * sin(flicker_t * 31.0)
	if neon != null:
		neon.modulate.a = j * drop
	if neon_reflect != null:
		neon_reflect.modulate.a = j * drop
	if lamp_glow != null:
		lamp_glow.modulate.a = 0.92 + 0.08 * sin(flicker_t * 7.0)
