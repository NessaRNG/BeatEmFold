extends SceneTree
## Smoke test Post-MVP 3 (varian + feel): dijalankan via
## godot --headless --path . -s tests/test_step7.gd

const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _mk(x: float, hp: int):
	var d = DummyS.new()
	d.respawns = false
	d.max_hp = hp
	d.hp = hp
	d.ai_enabled = true
	d.position = Vector2(x, 520)
	root.add_child(d)
	return d


func _init() -> void:
	var player = PlayerS.new()
	player.position = Vector2(400, 520)
	root.add_child(player)
	await process_frame
	await process_frame
	DummyS.reset_tokens()

	# --- 1. Fury: 2 hit, token dipegang sampai selesai ---
	var fury = _mk(450.0, 100)
	fury.ai_damage = 6
	fury.strike_hits = 2
	fury.strike_gap = 0.25
	await process_frame
	player.hp = 100
	player.invuln_timer = 0.0
	fury.ai_state = 0
	fury._update_ai(0.1) # windup
	check(fury.ai_state == 1, "Fury windup")
	fury._update_ai(0.6) # hit 1 -> gap (token dipegang)
	check(player.hp == 94, "Fury hit 1 (hp %d)" % player.hp)
	check(fury.ai_state == 3 and DummyS.active_attackers == 1, "Gap antar-hit, token dipegang")
	player.invuln_timer = 0.0
	fury._update_ai(0.3) # hit 2 -> recover + lepas
	check(player.hp == 88, "Fury hit 2 (hp %d)" % player.hp)
	check(fury.ai_state == 2 and DummyS.active_attackers == 0, "Selesai -> recover + lepas")

	# --- 2. Dasher: lunge menutup jarak ---
	DummyS.reset_tokens()
	var dasher = _mk(500.0, 100) # dist 100 > jangkau 77
	dasher.ai_damage = 6
	dasher.strike_lunge = 50.0
	await process_frame
	player.hp = 100
	player.invuln_timer = 0.0
	dasher.ai_state = 1
	dasher.ai_timer = 0.01
	dasher.ai_has_token = true
	DummyS.active_attackers = 1
	dasher._update_ai(0.05)
	check(player.hp == 94, "Lunge 50 menutup 100 -> kena (hp %d)" % player.hp)
	check(dasher.position.x < 500.0, "Dasher maju saat strike")

	# --- 3. Slammer: nempel sampai slam_range ---
	DummyS.reset_tokens()
	var slam = _mk(600.0, 100) # dist 200
	slam.ai_damage = 0
	slam.slam_damage = 10
	slam.slam_range = 110.0
	slam.ai_speed = 55.0
	await process_frame
	slam.ai_state = 0
	slam._update_ai(0.1)
	check(slam.velocity.x < 0.0, "Slammer dekati (slam_range 110, dist 200)")
	slam.position = Vector2(450, 520) # dist 50, melee off
	slam.ai_state = 0
	slam._update_ai(0.1)
	check(slam.ai_state == 0, "Tanpa melee: tidak windup")

	# --- 4. Float text + partikel saat kena ---
	var before_labels := 0
	for ch in dasher.get_children():
		if ch is Label and ch.text.begins_with("-"):
			before_labels += 1
	dasher.take_damage(5, Vector2.RIGHT, false)
	var found_float := false
	for ch in dasher.get_children():
		if ch is Label and ch.text == "-5":
			found_float = true
	check(found_float, "Float '-5' muncul (sblm %d)" % before_labels)
	var found_spark := false
	for ch in dasher.get_parent().get_children():
		if ch is CPUParticles2D:
			found_spark = true
	check(found_spark, "Burst partikel muncul")

	# --- 5. Jab-step maju ---
	var px: float = player.position.x
	player.facing = 1
	player.attack_stage = 0
	player._start_jab(0)
	check(player.position.x == px + 10.0, "Jab melangkah +10")

	# --- 6. Juice main: shake + hitstop pulih ---
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.add_shake(0.5)
	check(main.trauma > 0.0, "Shake trauma naik")
	main.hitstop(0.1, 0.05)
	await process_frame
	check(Engine.time_scale <= 1.0, "Hitstop tidak macet")
	var frames := 0
	while Engine.time_scale != 1.0 and frames < 300:
		await process_frame
		frames += 1
	check(Engine.time_scale == 1.0, "Time scale pulih (%d frame)" % frames)
	check(main.camera != null and main.camera.is_current(), "Kamera aktif")

	if failures == 0:
		print("ALL STEP7 TESTS PASSED")
	else:
		printerr("%d STEP7 TEST(S) FAILED" % failures)
	quit(failures)
