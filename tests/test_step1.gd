extends SceneTree
## Smoke test MVP Step 1: dijalankan via
## godot --headless --path . -s tests/test_step1.gd


func _init() -> void:
	var player_script := load("res://scripts/player.gd") as GDScript
	var dummy_script := load("res://scripts/dummy.gd") as GDScript
	var failures := 0

	var player = player_script.new()
	var dummy = dummy_script.new()
	root.add_child(player)
	root.add_child(dummy)
	# _ready jalan saat masuk tree; tunggu 2 frame agar node anak kebentuk
	await process_frame
	await process_frame

	# 1. HP awal
	if player.hp != 100:
		failures += 1
		printerr("FAIL: player hp awal = %d, harap 100" % player.hp)
	else:
		print("PASS: player hp awal 100")

	if dummy.hp != 30:
		failures += 1
		printerr("FAIL: dummy hp awal = %d, harap 30" % dummy.hp)
	else:
		print("PASS: dummy hp awal 30")

	# 2. Damage ke dummy
	dummy.take_damage(5, Vector2.RIGHT, false)
	if dummy.hp != 25:
		failures += 1
		printerr("FAIL: dummy hp setelah 5 dmg = %d, harap 25" % dummy.hp)
	else:
		print("PASS: dummy take_damage 5 -> 25")

	# 3. Player kena hit + mercy i-frame (hit kedua langsung harus diabaikan)
	player.take_damage(10)
	var after_first: int = player.hp
	player.take_damage(10)
	if after_first != 90:
		failures += 1
		printerr("FAIL: player hp setelah 10 dmg = %d, harap 90" % after_first)
	elif player.hp != 90:
		failures += 1
		printerr("FAIL: mercy i-frame gagal, hp = %d, harap tetap 90" % player.hp)
	else:
		print("PASS: player take_damage + mercy i-frame (100 -> 90, hit kedua diabaikan)")

	# 4. Konstanta jab sesuai GDD (fixed jab-jab-finisher)
	if player.JAB_DAMAGE[2] <= player.JAB_DAMAGE[0]:
		failures += 1
		printerr("FAIL: finisher harus lebih besar dari jab1")
	else:
		print("PASS: jab damage %s, finisher paling besar" % str(player.JAB_DAMAGE))

	# 5. Dummy mati -> KO -> respawn manual
	dummy.take_damage(999, Vector2.RIGHT, true)
	if not dummy.dead:
		failures += 1
		printerr("FAIL: dummy harus dead setelah lethal dmg")
	else:
		print("PASS: dummy KO setelah lethal dmg")
	dummy._respawn()
	if dummy.dead or dummy.hp != dummy.max_hp:
		failures += 1
		printerr("FAIL: dummy respawn gagal")
	else:
		print("PASS: dummy respawn full HP")

	if failures == 0:
		print("ALL TESTS PASSED")
	else:
		printerr("%d TEST(S) FAILED" % failures)
	quit(failures)
