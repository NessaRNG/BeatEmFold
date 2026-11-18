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

	var sheet_path := "res://assets/sprites/original_player_sheet.png"
	match character_type:
		"boss":
			sheet_path = "res://assets/sprites/original_boss_sheet.png"
		"enemy", "punk", "striker", "dasher", "fury", "slammer", "brute":
			sheet_path = "res://assets/sprites/original_enemy_sheet.png"
		_:
			sheet_path = "res://assets/sprites/original_player_sheet.png"

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

	# Layout 29 frame: idle 0..5, walk 6..13, jab 14..18, hook 19..23, upper 24..28.
	# Durasi per-frame bikin windup pelan -> snap cepat -> recover lentur (lebih halus).

	# 1. idle: 6 frame pernapasan sinusoidal
	sf.add_animation("idle")
	for i in range(6):
		sf.add_frame("idle", make_frame.call(i), 1.0)
	sf.set_animation_speed("idle", 6.0)
	sf.set_animation_loop("idle", true)

	# 2. walk: 8 frame stride lengkap
	sf.add_animation("walk")
	for i in range(6, 14):
		sf.add_frame("walk", make_frame.call(i), 1.0)
	sf.set_animation_speed("walk", 12.0)
	sf.set_animation_loop("walk", true)

	# 3. jab: 5 frame guard -> coil -> mid -> snap -> recover
	sf.add_animation("jab")
	var jab_dur := [0.45, 0.7, 0.7, 1.0, 1.15]
	for k in range(5):
		sf.add_frame("jab", make_frame.call(14 + k), jab_dur[k])
	sf.set_animation_speed("jab", 15.0)
	sf.set_animation_loop("jab", false)

	# 4. hook: 5 frame coil -> swing -> follow-through -> recover
	sf.add_animation("hook")
	var hook_dur := [0.45, 0.7, 0.7, 1.0, 1.15]
	for k in range(5):
		sf.add_frame("hook", make_frame.call(19 + k), hook_dur[k])
	sf.set_animation_speed("hook", 15.0)
	sf.set_animation_loop("hook", false)

	# 5. upper: 5 frame crouch -> rise -> launch -> recover
	sf.add_animation("upper")
	var upper_dur := [0.5, 0.7, 0.75, 1.0, 1.05]
	for k in range(5):
		sf.add_frame("upper", make_frame.call(24 + k), upper_dur[k])
	sf.set_animation_speed("upper", 13.0)
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

