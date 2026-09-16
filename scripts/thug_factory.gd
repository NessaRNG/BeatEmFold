class_name ThugFactory
extends RefCounted
## Preman pixel prosedural (dibuat runtime, kohesif penuh).
## Canvas 52x60, hadap kanan, kaki ~y56. Pose: idle/walk1/walk2/jab/hook/upper.
## Look: player, striker, dasher, fury, slammer, brute, boss.

const W := 52
const H := 60

static var _cache := {}
static var _ring: Texture2D


## Ring penanda di bawah player (cyan) — bedakan dari shadow musuh.
static func ring() -> Texture2D:
	if _ring == null:
		var img := Image.create(48, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for x in range(48):
			for y in range(16):
				var dx := (x - 23.5) / 23.5
				var dy := (y - 7.5) / 7.5
				var d := dx * dx + dy * dy
				if d >= 0.7 and d <= 1.0:
					img.set_pixel(x, y, Color.WHITE)
		_ring = ImageTexture.create_from_image(img)
	return _ring


static func frames(look: String) -> SpriteFrames:
	if _cache.has(look):
		return _cache[look]
	var pal := _palette(look)
	var sf := SpriteFrames.new()
	_mkanim(sf, "idle", [_draw(pal, "idle")])
	_mkanim(sf, "walk", [_draw(pal, "walk1"), _draw(pal, "walk2")], 8.0)
	_mkanim(sf, "jab", [_draw(pal, "jab")])
	if look == "player":
		_mkanim(sf, "hook", [_draw(pal, "hook")])
		_mkanim(sf, "upper", [_draw(pal, "upper")])
	else:
		_mkanim(sf, "hook", [_draw(pal, "jab")])
		_mkanim(sf, "upper", [_draw(pal, "jab")])
	_cache[look] = sf
	return sf


static func _mkanim(sf: SpriteFrames, anim: String, imgs: Array, fps: float = 10.0) -> void:
	if not sf.has_animation(anim):
		sf.add_animation(anim)
	for img in imgs:
		sf.add_frame(anim, ImageTexture.create_from_image(img), 1.0)
	sf.set_animation_loop(anim, anim == "idle" or anim == "walk")
	sf.set_animation_speed(anim, fps)


static func _palette(look: String) -> Dictionary:
	var p := {
		"skin": Color("d9a06f"), "hair": Color("2a2a2a"), "hairstyle": "flat",
		"top": Color("6b7280"), "top_dark": Color("4b5563"), "pants": Color("2f3542"),
		"shoe": Color("14141f"), "shirt": Color("e8e8e8"), "accent": Color("c0392b"),
		"chain": false, "style": "jacket",
	}
	match look:
		"player":
			p["skin"] = Color("e8b08a")
			p["hairstyle"] = "bandana"
			p["top"] = Color("2b4d9c")
			p["top_dark"] = Color("1e356e")
			p["pants"] = Color("2c3e60")
			p["chain"] = true
		"dasher":
			p["skin"] = Color("c98d5f")
			p["hairstyle"] = "cap"
			p["top"] = Color("2a9d8f")
			p["top_dark"] = Color("1e6e64")
			p["pants"] = Color("1f2430")
			p["accent"] = Color("d23c3c")
		"fury":
			p["skin"] = Color("e8b08a")
			p["hair"] = Color("e03131")
			p["hairstyle"] = "mohawk"
			p["top"] = Color("e8e8e8")
			p["top_dark"] = Color("b8b8b8")
			p["pants"] = Color("6b7c3a")
			p["style"] = "tank"
		"slammer":
			p["skin"] = Color("b57e52")
			p["hairstyle"] = "shades"
			p["top"] = Color("3f7c4e")
			p["top_dark"] = Color("2c5a37")
			p["shirt"] = Color("dddddd")
			p["pants"] = Color("333340")
			p["style"] = "vest"
		"brute":
			p["skin"] = Color("9c6b43")
			p["hair"] = Color("141414")
			p["top"] = Color("6b4a2f")
			p["top_dark"] = Color("4a3220")
			p["pants"] = Color("1f1f24")
		"boss":
			p["skin"] = Color("d9a06f")
			p["hairstyle"] = "shades"
			p["top"] = Color("23232e")
			p["top_dark"] = Color("14141c")
			p["shirt"] = Color("f2f2f2")
			p["accent"] = Color("c0392b")
			p["pants"] = Color("1a1a20")
			p["chain"] = true
			p["style"] = "suit"
	return p


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


static func _draw(p: Dictionary, pose: String) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin: Color = p["skin"]
	var pants: Color = p["pants"]
	var shoe: Color = p["shoe"]
	# Kaki.
	if pose == "walk1":
		_r(img, 16, 40, 4, 12, pants)
		_r(img, 15, 52, 6, 4, shoe)
		_r(img, 25, 41, 4, 11, pants)
		_r(img, 24, 52, 6, 4, shoe)
	elif pose == "walk2":
		_r(img, 12, 41, 4, 11, pants)
		_r(img, 11, 52, 6, 4, shoe)
		_r(img, 28, 40, 4, 12, pants)
		_r(img, 27, 52, 6, 4, shoe)
	else:
		_r(img, 14, 40, 4, 13, pants)
		_r(img, 27, 40, 4, 13, pants)
		_r(img, 13, 53, 6, 4, shoe)
		_r(img, 26, 53, 6, 4, shoe)
	# Badan sesuai style.
	_draw_torso(img, p)
	# Lengan belakang (jauh).
	var sleeve: Color = p["top_dark"]
	if p["style"] == "tank":
		sleeve = skin
	_r(img, 8, 24, 4, 12, sleeve)
	_r(img, 8, 36, 4, 4, skin)
	# Kepala + rambut.
	_r(img, 17, 10, 12, 12, skin)
	_r(img, 25, 14, 2, 2, Color("14141f")) # mata
	_draw_hair(img, p)
	# Lengan depan per pose.
	var arm: Color = p["top"]
	if p["style"] == "tank":
		arm = skin
	if pose == "jab":
		_r(img, 32, 27, 12, 4, arm)
		_r(img, 44, 26, 5, 6, skin)
	elif pose == "hook":
		_r(img, 32, 15, 4, 9, arm)
		_r(img, 31, 10, 7, 6, skin)
	elif pose == "upper":
		_r(img, 35, 13, 4, 9, arm)
		_r(img, 37, 8, 6, 6, skin)
	else:
		_r(img, 32, 24, 4, 12, arm)
		_r(img, 31, 36, 6, 5, skin)
	# Rantai emas preman.
	if bool(p["chain"]):
		var gold := Color("ffd94d")
		img.set_pixel(19, 27, gold)
		img.set_pixel(21, 29, gold)
		img.set_pixel(23, 30, gold)
		img.set_pixel(25, 29, gold)
		img.set_pixel(27, 27, gold)
	return img


static func _draw_torso(img: Image, p: Dictionary) -> void:
	var top: Color = p["top"]
	var dark: Color = p["top_dark"]
	var shirt: Color = p["shirt"]
	var style: String = p["style"]
	_r(img, 12, 22, 20, 17, top)
	if style == "jacket" or style == "hoodie":
		_r(img, 18, 22, 8, 3, dark) # kerah
		_r(img, 21, 25, 1, 13, Color(1, 1, 1, 0.35)) # resleting
		if style == "hoodie":
			_r(img, 10, 15, 6, 8, dark) # tudung
	elif style == "tank":
		pass # kaos oblong polos
	elif style == "vest":
		_r(img, 12, 22, 7, 17, top)
		_r(img, 25, 22, 7, 17, top)
		_r(img, 19, 24, 6, 14, shirt)
	elif style == "suit":
		_r(img, 20, 23, 4, 15, shirt)
		_r(img, 21, 24, 2, 11, p["accent"]) # dasi
		_r(img, 18, 22, 8, 2, dark)
	_r(img, 12, 38, 20, 2, Color("1a1a1a")) # sabuk


static func _draw_hair(img: Image, p: Dictionary) -> void:
	var hair: Color = p["hair"]
	var style: String = p["hairstyle"]
	if style == "flat":
		_r(img, 16, 6, 14, 5, hair)
		_r(img, 16, 10, 2, 5, hair)
	elif style == "mohawk":
		_r(img, 21, 1, 4, 10, hair)
	elif style == "cap":
		var c: Color = p["accent"]
		_r(img, 16, 6, 14, 6, c)
		_r(img, 28, 9, 8, 3, c.darkened(0.2))
	elif style == "bandana":
		_r(img, 16, 5, 14, 4, hair)
		_r(img, 16, 9, 14, 4, p["accent"])
		_r(img, 12, 10, 4, 3, p["accent"])
	elif style == "shades":
		_r(img, 22, 13, 7, 3, Color("0a0a0a"))
		img.set_pixel(23, 13, Color.WHITE)
