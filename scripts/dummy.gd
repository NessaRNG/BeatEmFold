class_name Dummy
extends CharacterBody2D
## MVP Step 1: samsak musuh. Punya HP, flash kena hit, knockback, stagger, respawn.

signal hp_changed(hp: int, max_hp: int)
signal died

const RESPAWN_TIME := 2.0

var max_hp := 30
var hp := 30
var dead := false
var stagger_timer := 0.0
var respawn_timer := 0.0
var knockback := Vector2.ZERO
## Konfigurasi wave/boss (4a/4c).
var display_name := "DUMMY"
var body_w := 36.0
var body_h := 56.0
var body_color := Color.WHITE
var respawns := true
var is_boss := false
var money_value := 4
var slam_damage := 0
var slam_range := 130.0
var slam_interval := 3.0
var slam_cd := 0.0
var telegraph := 0.0
var _player: Node2D
## Striker AI (post-MVP 1): dekati -> windup kuning -> pukul.
## Max 1 penyerang via token; sisanya tahan jarak + strafe.
var ai_enabled := false
var ai_speed := 120.0
var ai_damage := 8
var ai_range := 62.0
var ai_hold_dist := 220.0
var ai_windup := 0.6
var ai_recover := 0.4
var ai_state := 0 # 0=chase, 1=windup, 2=recover, 3=strike-gap (fury)
var ai_timer := 0.0
var ai_time := 0.0
var ai_has_token := false
## Varian pola serang: fury = double-hit, dasher = lunge saat strike.
var strike_hits := 1
var strike_gap := 0.25
var strike_lunge := 0.0
var strike_pending := 0
static var active_attackers := 0
## Naik per loop endless (1 -> maks 3). Diatur WaveManager tiap wave.
static var max_attackers := 1
static var spark_tex: Texture2D


static func reset_tokens() -> void:
	active_attackers = 0

var sprite: AnimatedSprite2D
var shadow: Sprite2D
var hp_label: Label
## Skala sprite (boss 1.5, brute 1.25).
var sprite_scale := 1.0
## Tampilan preman: striker/dasher/fury/slammer/brute/boss.
var look := "striker"


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(body_w, body_h)
	col.shape = shape
	col.position = Vector2(0, -body_h * 0.5)
	add_child(col)

	shadow = Sprite2D.new()
	shadow.texture = load("res://assets/chars/fistbot_shadow.png")
	shadow.position = Vector2(0, -2)
	add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = ThugFactory.frames(look)
	sprite.position = Vector2(-4, -30 * sprite_scale * 1.15)
	sprite.scale = Vector2(sprite_scale * 1.15, sprite_scale * 1.15)
	sprite.modulate = body_color
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("idle")
	add_child(sprite)

	hp_label = Label.new()
	hp_label.text = _hp_text()
	hp_label.position = Vector2(-body_w * 0.5 - 20.0, -body_h - 26.0)
	add_child(hp_label)


func _physics_process(delta: float) -> void:
	if dead:
		if respawns:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				_respawn()
		return
	if stagger_timer > 0.0:
		stagger_timer -= delta
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 1200.0 * delta)
	else:
		velocity = Vector2.ZERO
		if ai_enabled:
			_update_ai(delta)
		_update_slam(delta)
		_update_visual()
	move_and_slide()
	position.y = clampf(position.y, Player.LANE_TOP, Player.LANE_BOTTOM)
	position.x = clampf(position.x, 40.0, 1240.0)


func _ensure_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player != null


func _update_ai(delta: float) -> void:
	if not _ensure_player() or _player.get("dead"):
		velocity = Vector2.ZERO
		return
	ai_time += delta
	var to: Vector2 = _player.position - position
	var dist := to.length()
	match ai_state:
		0: # chase / hold (slammer nempel sampai slam_range)
			var want := ai_hold_dist
			if slam_damage > 0:
				want = minf(want, slam_range * 0.9)
			if dist <= ai_range and ai_damage > 0 and _try_take_token():
				ai_state = 1
				ai_timer = ai_windup
				strike_pending = strike_hits - 1
				_flash(Color("ffe066"))
				sprite.play("jab")
				velocity = Vector2.ZERO
			elif dist > want:
				velocity = to.normalized() * ai_speed
			elif dist < want - 60.0:
				velocity = Vector2(-signf(to.x) * ai_speed * 0.5, 0)
			else:
				var phase := float(get_instance_id() % 10)
				velocity = Vector2(0, sin(ai_time * 2.0 + phase) * 40.0)
		1: # windup (telegraph) — kaki diam, masih bisa di-dodge
			velocity = Vector2.ZERO
			ai_timer -= delta
			if ai_timer <= 0.0:
				_strike()
		3: # jeda antar-hit fury (token tetap dipegang)
			velocity = Vector2.ZERO
			ai_timer -= delta
			if ai_timer <= 0.0:
				_strike()
		_: # recover
			velocity = Vector2.ZERO
			ai_timer -= delta
			if ai_timer <= 0.0:
				ai_state = 0


func _try_take_token() -> bool:
	if ai_has_token:
		return true
	if is_boss or active_attackers < max_attackers:
		active_attackers += 1
		ai_has_token = true
		return true
	return false


func _release_token() -> void:
	if ai_has_token:
		ai_has_token = false
		active_attackers = maxi(active_attackers - 1, 0)


func _strike() -> void:
	# Dasher: lunge pendek dulu (masih bisa di-dash, tidak bisa jalan kaki).
	if strike_lunge > 0.0 and _player != null:
		var to: Vector2 = _player.position - position
		var dist: float = to.length()
		if dist > 20.0:
			position += to.normalized() * minf(strike_lunge, dist - 20.0)
	_unflash()
	var d := position.distance_to(_player.position)
	if d <= ai_range + 15.0:
		_player.take_damage(ai_damage)
	if strike_pending > 0:
		strike_pending -= 1
		ai_state = 3
		ai_timer = strike_gap
		_flash(Color("ffe066"))
	else:
		_release_token()
		ai_state = 2
		ai_timer = ai_recover


## Serangan boss: telegraph 0.5s (kuning) lalu slam AoE bila masih dekat.
func _update_slam(delta: float) -> void:
	if slam_damage <= 0:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if telegraph > 0.0:
		telegraph -= delta
		if telegraph <= 0.0:
			_unflash()
			if position.distance_to(_player.position) <= slam_range + 20.0:
				_player.take_damage(slam_damage)
			slam_cd = slam_interval
		return
	if slam_cd > 0.0:
		slam_cd -= delta
		return
	if position.distance_to(_player.position) <= slam_range:
		telegraph = 0.5
		_flash(Color("ffe066"))


func take_damage(amount: int, from_dir: Vector2, heavy: bool = false) -> void:
	if dead:
		return
	hp = maxi(hp - amount, 0)
	hp_label.text = _hp_text()
	hp_changed.emit(hp, max_hp)
	# Feedback: flash putih + stagger + knockback + spark
	_flash(Color.WHITE)
	stagger_timer = 0.35 if heavy else 0.18
	knockback = from_dir * (420.0 if heavy else 220.0)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", body_color, 0.12)
	_spawn_float("-%d" % amount, heavy)
	_spawn_spark(heavy)
	_burst(Color("ffd94d") if heavy else Color(1, 1, 1, 0.9), 10 if heavy else 5)
	if hp <= 0:
		_die()


## Stun tambahan (bonus Cash-In Clubs). Tidak menimpa stagger yg lebih lama.
func add_stagger(t: float) -> void:
	if dead:
		return
	stagger_timer = maxf(stagger_timer, t)


func _die() -> void:
	dead = true
	telegraph = 0.0
	_release_token()
	sprite.modulate = Color("444444")
	_burst(Color("ff5a5a"), 14)
	if respawns:
		respawn_timer = RESPAWN_TIME
		hp_label.text = "KO! respawn..."
	else:
		hp_label.text = "KO!"
	died.emit()


func _respawn() -> void:
	dead = false
	hp = max_hp
	sprite.modulate = body_color
	sprite.play("idle")
	hp_label.text = _hp_text()
	hp_changed.emit(hp, max_hp)


## Flash warna (telegraph kuning / hit putih), pulih ke tint dasar.
func _flash(c: Color) -> void:
	sprite.modulate = c


func _unflash() -> void:
	if not dead:
		sprite.modulate = body_color


## Hitspark sprite di titik kena.
func _spawn_spark(big: bool) -> void:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = CharSprites.spark_anims()
	a.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	a.position = Vector2(0, -body_h * 0.5)
	if big:
		a.scale = Vector2(1.6, 1.6)
	add_child(a)
	a.play("spark")
	_free_spark(a)


func _free_spark(a: AnimatedSprite2D) -> void:
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(a):
		a.queue_free()


## Anim + hadap mengikuti state. Dipanggil tiap physics frame hidup.
func _update_visual() -> void:
	if _player != null and is_instance_valid(_player):
		var dx: float = _player.position.x - position.x
		if absf(dx) > 4.0:
			sprite.flip_h = dx < 0.0
	if ai_state == 1 or ai_state == 3:
		if sprite.animation != "jab":
			sprite.play("jab")
	elif velocity.length() > 20.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	elif sprite.animation != "idle":
		sprite.play("idle")


func _hp_text() -> String:
	return "%s %d/%d" % [display_name, hp, max_hp]


## Angka damage melayang (game feel, menempel di musuh).
func _spawn_float(text: String, big: bool) -> void:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 22 if big else 16)
	lb.add_theme_color_override("font_color", Color("ffd94d") if big else Color.WHITE)
	lb.position = Vector2(-24.0, -body_h - 52.0)
	add_child(lb)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lb, "position:y", lb.position.y - 36.0, 0.6)
	tween.tween_property(lb, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(lb.queue_free)


## Semburan partikel CPU (aman di compatibility renderer).
func _burst(color: Color, count: int) -> void:
	if spark_tex == null:
		var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		spark_tex = ImageTexture.create_from_image(img)
	var p := CPUParticles2D.new()
	p.texture = spark_tex
	p.amount = count
	p.lifetime = 0.4
	p.one_shot = true
	p.explosiveness = 0.9
	p.spread = 180.0
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.color = color
	p.position = position + Vector2(0, -body_h * 0.5)
	var parent := get_parent()
	if parent == null:
		return
	parent.add_child(p)
	p.emitting = true
	_free_later(p)


func _free_later(node: Node) -> void:
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(node):
		node.queue_free()
