class_name Player
extends CharacterBody2D
## MVP Step 1: gerak + jab 3-hit fixed + dash i-frame. Tanpa kartu.
## Kontrol keyboard: WASD/Panah gerak, J/klik-kiri jab, K/Spasi dash.

signal hp_changed(hp: int, max_hp: int)
signal combo_changed(stage: int)
## Dipancar tiap ada jab yang KENA musuh (dipakai HandManager auto-draw).
signal hit_landed
## Dipancar tiap dash dimulai (dipakai tutorial).
signal dashed

const SPEED := 280.0
const DASH_SPEED := 700.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.5
const IFRAME_TIME := 0.25
const LANE_TOP := 430.0
const LANE_BOTTOM := 600.0

const JAB_DAMAGE := [5, 5, 9]
const JAB_DURATION := [0.22, 0.22, 0.34]
const JAB_RANGE := 78.0
const JAB_HEIGHT := 64.0
const COMBO_WINDOW := 0.7

var max_hp := 100
var hp := 100
var facing := 1
var attack_stage := 0 # 0 = idle, 1..3 = jab index+1
var attack_timer := 0.0
var combo_timer := 0.0
var attack_did_hit := false
var attack_queued := false
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_dir := Vector2.RIGHT
var invuln_timer := 0.0
var dead := false
## true saat tahan select_mode: jab dikunci (gerak + dash tetap jalan).
var attack_locked := false
## true saat shop / game over: semua input gerak mati.
var controls_locked := false

var sprite: AnimatedSprite2D
var shadow: Sprite2D
var hitbox: Area2D
var hitbox_shape: CollisionShape2D

const PUNCH_ANIMS := ["jab", "hook", "upper"]


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 # tabrak dunia saja, musuh dideteksi via Area2D

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34, 52)
	col.shape = shape
	col.position = Vector2(0, -26)
	add_child(col)

	shadow = Sprite2D.new()
	shadow.texture = load("res://assets/chars/fistbot_shadow.png")
	shadow.position = Vector2(0, -2)
	shadow.scale = Vector2(1.4, 1.4)
	add_child(shadow)

	var ring := Sprite2D.new()
	ring.texture = ThugFactory.ring()
	ring.position = Vector2(0, -3)
	ring.modulate = Color(0.35, 0.9, 1.0, 0.85)
	add_child(ring)

	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = ThugFactory.frames("player")
	sprite.position = Vector2(-5, -40)
	sprite.scale = Vector2(1.35, 1.35)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("idle")
	add_child(sprite)

	hitbox = Area2D.new()
	hitbox.collision_layer = 4
	hitbox.collision_mask = 4 # layer 3 = enemy
	hitbox.monitoring = true
	var hb_shape := RectangleShape2D.new()
	hb_shape.size = Vector2(JAB_RANGE, JAB_HEIGHT)
	hitbox_shape = CollisionShape2D.new()
	hitbox_shape.shape = hb_shape
	hitbox_shape.position = Vector2(JAB_RANGE * 0.5, -28)
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)


func _physics_process(delta: float) -> void:
	if dead or controls_locked:
		return
	_update_timers(delta)
	_handle_attack_input()
	_handle_dash_input()
	_move(delta)
	_update_attack(delta)
	_update_visual()


func _update_timers(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer -= delta
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and attack_stage == 0:
			attack_stage = 0
			combo_changed.emit(0)


func _handle_attack_input() -> void:
	if attack_locked:
		return
	if Input.is_action_just_pressed("attack"):
		if attack_stage == 0:
			_start_jab(0)
		else:
			attack_queued = true


func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and dash_timer <= 0.0:
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.length() < 0.1:
			dir = Vector2(facing, 0)
		dash_dir = dir.normalized()
		dash_timer = DASH_TIME
		dash_cooldown = DASH_COOLDOWN
		invuln_timer = maxf(invuln_timer, IFRAME_TIME)
		dashed.emit()
		# Dash membatalkan jab (game feel responsif)
		attack_stage = 0
		attack_timer = 0.0
		attack_queued = false


func _move(delta: float) -> void:
	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = dash_dir * DASH_SPEED
	else:
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var speed_mult := 0.25 if attack_stage > 0 else 1.0
		velocity = dir * SPEED * speed_mult
		if absf(dir.x) > 0.1 and attack_stage == 0:
			facing = 1 if dir.x > 0.0 else -1
	move_and_slide()
	# Klem 1 lane ala beat 'em up (Streets of Rage style)
	position.y = clampf(position.y, LANE_TOP, LANE_BOTTOM)
	position.x = clampf(position.x, 40.0, 1240.0)


func _start_jab(index: int) -> void:
	attack_stage = index + 1
	attack_timer = JAB_DURATION[index]
	attack_did_hit = false
	attack_queued = false
	combo_timer = COMBO_WINDOW
	sprite.play(PUNCH_ANIMS[index])
	position.x = clampf(position.x + facing * 10.0, 40.0, 1240.0)
	combo_changed.emit(attack_stage)


func _update_attack(delta: float) -> void:
	if attack_stage == 0:
		return
	attack_timer -= delta
	# Hit aktif di awal swing (0.05s setelah mulai) biar berasa snappy
	var index := attack_stage - 1
	if not attack_did_hit and attack_timer < JAB_DURATION[index] - 0.05:
		attack_did_hit = true
		_do_hit(index)
	if attack_timer <= 0.0:
		if attack_queued and attack_stage < 3:
			_start_jab(attack_stage) # lanjut ke jab berikut
		else:
			attack_stage = 0
			attack_queued = false
			combo_changed.emit(0)


func _do_hit(index: int) -> void:
	hitbox_shape.position = Vector2(facing * JAB_RANGE * 0.5, -28)
	# Tunggu 1 physics frame agar posisi hitbox update sebelum query
	await get_tree().physics_frame
	if dead:
		return
	var hit_any := false
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			var dir := Vector2(facing, 0)
			body.take_damage(JAB_DAMAGE[index], dir, index == 2)
			hit_any = true
	if hit_any:
		hit_landed.emit()


func take_damage(amount: int) -> void:
	if dead or invuln_timer > 0.0 or dash_timer > 0.0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	invuln_timer = 0.4 # brief mercy i-frame kena hit
	if hp <= 0:
		dead = true
		sprite.rotation = -1.4 # roboh
		sprite.modulate = Color.WHITE
		set_physics_process(false)


## Heal dari Cash-In Hearts. Tidak melewati max.
func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


## Shield sementara dari Cash-In Diamonds (i-frame panjang).
func grant_shield(duration: float) -> void:
	if dead:
		return
	invuln_timer = maxf(invuln_timer, duration)


func _update_visual() -> void:
	sprite.flip_h = facing < 0
	if attack_stage == 0:
		if velocity.length() > 20.0:
			if sprite.animation != "walk":
				sprite.play("walk")
		elif sprite.animation != "idle":
			sprite.play("idle")
	# Kedip saat i-frame
	sprite.modulate.a = 0.4 if invuln_timer > 0.0 else 1.0
