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


# --- 0: ALLEY (aset tekstur pixel art + retro neon stage) ---
func _build_alley() -> void:
	# 1. Polished Brick Environment utama (Dinding bata merah-oranye, semen plester mengelupas, paving trotoar, dan aspal arena)
	var brick_env_path := "res://assets/backgrounds/brick_alley_polished.png"
	var env_tex := load(brick_env_path) as Texture2D
	if env_tex != null:
		var env := TextureRect.new()
		env.texture = env_tex
		env.position = Vector2.ZERO
		env.size = Vector2(1280, 720)
		env.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		env.stretch_mode = TextureRect.STRETCH_SCALE
		env.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(env)
	else:
		# Fallback layer modular jika belum ada
		var sky_path := "res://assets/backgrounds/alley_skyline.png"
		var sky_tex := load(sky_path) as Texture2D
		if sky_tex != null:
			var sky := TextureRect.new()
			sky.texture = sky_tex
			sky.position = Vector2.ZERO
			sky.size = Vector2(1280, 360)
			sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sky.stretch_mode = TextureRect.STRETCH_SCALE
			sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sky)

		var wall_tex := load("res://assets/backgrounds/alley_wall_midground.png") as Texture2D
		if wall_tex != null:
			var wall := TextureRect.new()
			wall.texture = wall_tex
			wall.position = Vector2(0, 140)
			wall.size = Vector2(1280, 300)
			wall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wall.stretch_mode = TextureRect.STRETCH_SCALE
			wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(wall)

		var ground_tex := load("res://assets/backgrounds/alley_ground_lane.png") as Texture2D
		if ground_tex != null:
			var ground := TextureRect.new()
			ground.texture = ground_tex
			ground.position = Vector2(0, 400)
			ground.size = Vector2(1280, 320)
			ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ground.stretch_mode = TextureRect.STRETCH_SCALE
			ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(ground)

	# Neon signs & interactive stage lights (kompatibel test & visual)
	_neon_box(Vector2(830, 200), "K.O. BAR", Color("ff5fd2"), Color(1, 0.25, 0.75, 0.16))
	_neon_box(Vector2(180, 260), "24H", Color("5affd2"), Color(0.2, 1, 0.8, 0.12))

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

	# Kantong sampah & dumpster detail
	_rect(Vector2(60, 470), Vector2(170, 90), Color("23402e"))
	_rect(Vector2(54, 458), Vector2(182, 16), Color("2c5340"))
	for b in [[250.0, 548.0, 22.0], [288.0, 556.0, 15.0], [1010.0, 560.0, 18.0]]:
		_glow_poly(_octagon(Vector2(b[0], b[1]), b[2]), Color("101018"))



# --- 1: ROOFTOP (senja oranye, toren air, AC, pagar) ---
func _build_rooftop() -> void:
	var sky := Image.create(1280, 360, false, Image.FORMAT_RGBA8)
	for y in range(360):
		var t := float(y) / 360.0
		_px(sky, 0, y, 1280, 1, Color("1a1030").lerp(Color("e06020"), t * t))
	_sprite(sky, Vector2.ZERO)
	# Matahari terbenam.
	_rect(Vector2(580, 220), Vector2(120, 120), Color("ffd94d"))
	_rect(Vector2(560, 240), Vector2(160, 8), Color(1, 0.85, 0.3, 0.25))
	# Gedung depan siluet.
	var x := 0
	while x < 1280:
		var bw := rng.randi_range(120, 240)
		var bh := rng.randi_range(80, 190)
		_rect(Vector2(x, 360 - bh), Vector2(bw, bh), Color("0e0d18"))
		for wy in range(int(360 - bh + 10), 350, 18):
			for wx in range(x + 10, x + bw - 10, 18):
				if rng.randf() < 0.22:
					_rect(Vector2(wx, wy), Vector2(8, 10), Color(1, 0.7, 0.35, 0.7))
		x += bw + rng.randi_range(10, 40)
	# Dak + pagar.
	_rect(Vector2(0, 360), Vector2(1280, 70), Color("2a2438"))
	for px in range(0, 1280, 64):
		_rect(Vector2(px, 330), Vector2(6, 100), Color("161420"))
	_rect(Vector2(0, 330), Vector2(1280, 8), Color("3a3450"))
	# Toren air kiri.
	_rect(Vector2(90, 230), Vector2(110, 130), Color("4a3a30"))
	_rect(Vector2(100, 220), Vector2(90, 16), Color("5a4a3c"))
	for i in range(3):
		_rect(Vector2(100 + i * 32, 360), Vector2(10, 70), Color("2a2018"))
	# Box AC kanan + tengah.
	for b in [Vector2(950, 380), Vector2(1030, 390), Vector2(420, 392)]:
		_rect(b, Vector2(56, 40), Color("3c4250"))
		_rect(b + Vector2(6, 6), Vector2(44, 6), Color(0, 0, 0, 0.4))
	# Antena.
	_rect(Vector2(700, 200), Vector2(6, 160), Color("101018"))
	_rect(Vector2(680, 210), Vector2(46, 6), Color("101018"))
	_rect(Vector2(700, 196), Vector2(10, 10), Color("ff5a5a"))
	_neon_box(Vector2(830, 215), "ROOFTOP", Color("ffb14d"), Color(1, 0.6, 0.2, 0.16))
	# Lantai dak kerikil.
	var fl := Image.create(1280, 290, false, Image.FORMAT_RGBA8)
	fl.fill(Color("232030"))
	for i in range(2600):
		fl.set_pixel(rng.randi_range(0, 1279), rng.randi_range(0, 289),
			Color(1, 1, 1, 0.04) if i % 2 == 0 else Color(0, 0, 0, 0.3))
	_sprite(fl, Vector2(0, 430))
	_rect(Vector2(830, 600), Vector2(190, 60), Color(1, 0.6, 0.2, 0.08))


# --- 2: BAR (interior kayu, lampu panggung, meja) ---
func _build_bar() -> void:
	_rect(Vector2(0, 0), Vector2(1280, 430), Color("171019"))
	# Panel kayu.
	for px in range(0, 1280, 96):
		var v := rng.randf_range(-0.02, 0.03)
		_rect(Vector2(px + 2, 40), Vector2(92, 390), Color(0.24 + v, 0.13 + v, 0.12 + v))
		_rect(Vector2(px + 2, 40), Vector2(4, 390), Color(0, 0, 0, 0.4))
	# Rak botol.
	_rect(Vector2(0, 150), Vector2(1280, 12), Color("0d0a10"))
	_rect(Vector2(0, 250), Vector2(1280, 12), Color("0d0a10"))
	for i in range(26):
		var bx := 30 + i * 47 + rng.randi_range(-6, 6)
		var bc: Color = [Color("3fae5a"), Color("e04040"), Color("4da6ff"), Color("ffd94d")][i % 4]
		_rect(Vector2(bx, 118), Vector2(14, 32), bc)
		_rect(Vector2(bx + 4, 110), Vector2(6, 8), Color(0.8, 0.8, 0.8, 0.7))
	# Lampu panggung 3 warna.
	for i in range(3):
		var lx := 320.0 + i * 320.0
		var lc: Color = [Color("ff5fd2"), Color("5aa9ff"), Color("ffd94d")][i]
		_rect(Vector2(lx, 0), Vector2(10, 60), Color("0d0d14"))
		_rect(Vector2(lx - 8, 60), Vector2(26, 16), lc)
		_glow_poly(PackedVector2Array(
			[Vector2(lx + 5, 76), Vector2(lx - 110, 600), Vector2(lx + 120, 600)]),
			Color(lc.r, lc.g, lc.b, 0.08))
	_neon_box(Vector2(545, 300), "K.O. CLUB", Color("5affd2"), Color(0.2, 1, 0.8, 0.14))
	# Meja + kursi siluet.
	for t in [Vector2(140, 470), Vector2(1050, 480)]:
		_rect(t + Vector2(-50, 0), Vector2(120, 14), Color("2e1a12"))
		_rect(t + Vector2(-6, 14), Vector2(12, 70), Color("1c100c"))
		_rect(t + Vector2(-80, 30), Vector2(26, 54), Color("141018"))
		_rect(t + Vector2(64, 30), Vector2(26, 54), Color("141018"))
	# Lantai kayu.
	var fl := Image.create(1280, 290, false, Image.FORMAT_RGBA8)
	fl.fill(Color("1d130e"))
	for y in range(0, 290, 24):
		for x2 in range(1280):
			if x2 % 2 == 0:
				fl.set_pixel(x2, y, Color(0, 0, 0, 0.35))
		for i in range(30):
			fl.set_pixel(rng.randi_range(0, 1279), rng.randi_range(y, mini(y + 23, 289)),
				Color(1, 0.8, 0.5, 0.03))
	_sprite(fl, Vector2(0, 430))
	_rect(Vector2(545, 600), Vector2(190, 60), Color(0.2, 1, 0.8, 0.07))


func _process(delta: float) -> void:
	if flicker_nodes.is_empty():
		return
	flicker_t += delta
	var drop := 0.35 if sin(flicker_t * 1.7) > 0.985 else 1.0
	var j := 0.86 + 0.1 * sin(flicker_t * 13.0) + 0.04 * sin(flicker_t * 31.0)
	for n in flicker_nodes:
		if is_instance_valid(n):
			n.modulate.a = j * drop
