class_name CharSprites
extends RefCounted
## Loader sprite sheet Chibi Brawler modular (48x48 per frame).
## Sheet layout 288x48:
## 0: idle1, 1: idle2, 2: walk1, 3: walk2, 4: jab, 5: hook/upper

static var _cache := {}
static var _spark_tex: Texture2D
static var _spark_sf: SpriteFrames

static func spark_frames() -> Array:
	if _spark_tex == null:
		_spark_tex = load("res://assets/chars/hitspark.png")
	var out: Array = []
	for i in range(2):
		var at := AtlasTexture.new()
		at.atlas = _spark_tex
		at.region = Rect2(i * 40, 0, 40, 39)
		out.append(at)
	return out


## SpriteFrames hitspark siap play ("spark", sekali, 14fps).
static func spark_anims() -> SpriteFrames:
	if _spark_sf == null:
		_spark_sf = SpriteFrames.new()
		_spark_sf.add_animation("spark")
		for t in spark_frames():
			_spark_sf.add_frame("spark", t, 1.0)
		_spark_sf.set_animation_loop("spark", false)
		_spark_sf.set_animation_speed("spark", 14.0)
	return _spark_sf


static func get_frames(character_type: String = "player") -> SpriteFrames:
	if _cache.has(character_type):
		return _cache[character_type]

	var sheet_path := "res://assets/sprites/handcrafted_player_sheet.png"
	match character_type:
		"boss":
			sheet_path = "res://assets/sprites/handcrafted_boss_sheet.png"
		"enemy", "punk", "striker", "dasher", "fury", "slammer", "brute":
			sheet_path = "res://assets/sprites/handcrafted_enemy_sheet.png"
		_:
			sheet_path = "res://assets/sprites/handcrafted_player_sheet.png"

	var tex := load(sheet_path) as Texture2D
	if tex == null:
		# Fallback ke ThugFactory jika file belum terimport di Godot runtime
		return ThugFactory.frames(character_type)

	var sf := SpriteFrames.new()
	var frame_w := 128
	var frame_h := 96

	# Helper untuk potong AtlasTexture per frame
	var make_frame := func(idx: int) -> AtlasTexture:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(idx * frame_w, 0, frame_w, frame_h)
		return at

	# 1. idle: 4 frames (0..3) fluid breathing & arm sway
	sf.add_animation("idle")
	for i in range(4):
		sf.add_frame("idle", make_frame.call(i), 1.0)
	sf.set_animation_speed("idle", 6.0)
	sf.set_animation_loop("idle", true)

	# 2. walk: 6 frames (4..9) dynamic run stride
	sf.add_animation("walk")
	for i in range(4, 10):
		sf.add_frame("walk", make_frame.call(i), 1.0)
	sf.set_animation_speed("walk", 12.0)
	sf.set_animation_loop("walk", true)

	# 3. jab: 2 frames (10..11) windup -> snap punch
	sf.add_animation("jab")
	sf.add_frame("jab", make_frame.call(10), 0.7)
	sf.add_frame("jab", make_frame.call(11), 1.3)
	sf.set_animation_speed("jab", 14.0)
	sf.set_animation_loop("jab", false)

	# 4. hook: 2 frames (12..13) windup -> wide swing
	sf.add_animation("hook")
	sf.add_frame("hook", make_frame.call(12), 0.7)
	sf.add_frame("hook", make_frame.call(13), 1.3)
	sf.set_animation_speed("hook", 14.0)
	sf.set_animation_loop("hook", false)

	# 5. upper: 2 frames (14..15) crouch -> air launch
	sf.add_animation("upper")
	sf.add_frame("upper", make_frame.call(14), 0.7)
	sf.add_frame("upper", make_frame.call(15), 1.3)
	sf.set_animation_speed("upper", 14.0)
	sf.set_animation_loop("upper", false)

	# 6. hit: frame 1 (flinch)
	sf.add_animation("hit")
	sf.add_frame("hit", make_frame.call(1), 1.0)
	sf.set_animation_speed("hit", 10.0)
	sf.set_animation_loop("hit", false)

	_cache[character_type] = sf
	return sf


static func slash_tex() -> Texture2D:
	return load("res://assets/sprites/slash_arc_fx.png") as Texture2D


static func dust_tex() -> Texture2D:
	return load("res://assets/sprites/dust_puff_fx.png") as Texture2D

