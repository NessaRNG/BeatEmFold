class_name CharSprites
extends RefCounted
## Hitspark dari Beat em Up Pack (Chewbatrij, CC0). Karakter kini prosedural
## (ThugFactory) agar pas tema preman.

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
