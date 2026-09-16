extends SceneTree
## Smoke test Post-MVP 1 (striker AI): dijalankan via
## godot --headless --path . -s tests/test_step5.gd

const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _mk_striker(x: float):
	var d = DummyS.new()
	d.respawns = false
	d.max_hp = 100
	d.hp = 100
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

	# --- 1. Chase: jauh -> dekati ---
	var s1 = _mk_striker(700.0)
	await process_frame
	s1._update_ai(0.1)
	check(s1.velocity.x < 0.0, "Jauh: dekati player (vx %.0f)" % s1.velocity.x)

	# --- 2. Hold: jarak sedang -> strafe, x diam ---
	s1.position = Vector2(580, 520) # dist 180: hold ring
	s1.ai_state = 0
	s1._update_ai(0.1)
	check(s1.velocity.x == 0.0, "Hold ring: x diam, strafe saja")

	# --- 3. Dekat: windup + token ---
	s1.position = Vector2(450, 520) # dist 50
	s1.ai_state = 0
	s1._update_ai(0.1)
	check(s1.ai_state == 1, "Dekat: windup mulai")
	check(DummyS.active_attackers == 1, "Token diambil (1 penyerang)")

	# --- 4. Strike kena dalam jarak ---
	player.hp = 100
	player.invuln_timer = 0.0
	s1._update_ai(0.6)
	check(player.hp == 92, "Strike 8 dmg dalam jarak (hp %d)" % player.hp)
	check(s1.ai_state == 2 and DummyS.active_attackers == 0, "Recover + token lepas")

	# --- 5. Dodge: kabur saat windup -> luput ---
	s1.ai_state = 1
	s1.ai_timer = 0.5
	s1.ai_has_token = true
	DummyS.active_attackers = 1
	player.hp = 100
	player.invuln_timer = 0.0
	player.position = Vector2(900, 520) # kabur jauh
	s1._update_ai(0.6)
	check(player.hp == 100, "Dodge saat windup: luput")
	check(DummyS.active_attackers == 0, "Token lepas setelah strike")

	# --- 6. Token: penyerang kedua menunggu ---
	DummyS.reset_tokens()
	player.position = Vector2(400, 520)
	var s2 = _mk_striker(460.0)
	await process_frame
	# Physics alami bisa curi token saat await -> reset total dulu.
	s1.ai_has_token = false
	s2.ai_has_token = false
	DummyS.reset_tokens()
	s1.position = Vector2(450, 520)
	s1.ai_state = 0
	s2.ai_state = 0
	s1._update_ai(0.1) # s1 ambil token
	s2._update_ai(0.1) # s2 dekat tapi token habis
	check(s1.ai_state == 1 and s2.ai_state == 0, "Max 1 penyerang (s1 windup, s2 tunggu)")
	s1._strike() # s1 selesai
	s2._update_ai(0.1)
	check(s2.ai_state == 1, "Token bebas -> s2 maju")

	# --- 7. Mati saat windup -> token tidak bocor ---
	DummyS.reset_tokens()
	s2.ai_state = 1
	s2.ai_timer = 0.5
	s2.ai_has_token = true
	DummyS.active_attackers = 1
	s2.take_damage(999, Vector2.RIGHT, true)
	check(DummyS.active_attackers == 0, "Mati windup: token kembali")

	# --- 8. Recover -> chase lagi ---
	s1.ai_state = 2
	s1.ai_timer = 0.4
	s1._update_ai(0.5)
	check(s1.ai_state == 0, "Recover selesai -> chase")

	# --- 9. Boss: chase tapi tidak strike (ai_damage 0) ---
	var boss = _mk_striker(500.0)
	boss.is_boss = true
	boss.ai_damage = 0
	boss.ai_speed = 60.0
	await process_frame
	boss.position = Vector2(450, 520)
	boss.ai_state = 0
	DummyS.reset_tokens()
	boss._update_ai(0.1)
	check(boss.ai_state == 0, "Boss dekat: tetap chase (slam urusan sendiri)")

	# --- 10. Tidak bisa keluar arena (klem X seperti player) ---
	var esc = _mk_striker(100.0)
	await process_frame
	esc.knockback = Vector2(-2000, 0)
	esc.stagger_timer = 1.0
	for i in range(30):
		await physics_frame
	check(esc.position.x >= 40.0, "Klem kiri (x=%.0f)" % esc.position.x)
	esc.position = Vector2(1200, 520)
	esc.knockback = Vector2(2000, 0)
	esc.stagger_timer = 1.0
	for i in range(30):
		await physics_frame
	check(esc.position.x <= 1240.0, "Klem kanan (x=%.0f)" % esc.position.x)

	if failures == 0:
		print("ALL STEP5 TESTS PASSED")
	else:
		printerr("%d STEP5 TEST(S) FAILED" % failures)
	quit(failures)
