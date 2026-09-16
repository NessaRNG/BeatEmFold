extends SceneTree
## Smoke test Post-MVP 2 (elite wave): dijalankan via
## godot --headless --path . -s tests/test_step6.gd

const DummyS = preload("res://scripts/dummy.gd")
const WaveS = preload("res://scripts/wave_manager.gd")

var failures = 0
var cleared_idx = -1


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _on_cleared(idx: int) -> void:
	cleared_idx = idx


func _kill_all(wm) -> void:
	for e in wm.spawned:
		e.take_damage(999, Vector2.RIGHT, true)
	await process_frame
	await process_frame


func _init() -> void:
	var wm = WaveS.new()
	root.add_child(wm)
	wm.wave_cleared.connect(_on_cleared)
	await process_frame

	check(wm.kind_of(4) == 1 and wm.loop_of(4) == 1, "kind/loop mapping (4=elite loop1)")
	check(wm.wave_title(1) == "WAVE 2", "Judul wave 2")
	check(wm.wave_sealed(2) == 4 and wm.wave_sealed(0) == -1, "Seal hanya boss")

	# Wave 0: 2 striker + 1 dasher
	wm.start_wave(0, root)
	await process_frame
	check(wm.spawned.size() == 3, "Wave 0: 3 musuh")
	var strikers := 0
	var dashers := 0
	for e in wm.spawned:
		if e.display_name == "DASHER":
			dashers += 1
			if e.ai_speed < 150.0 or e.money_value != 5:
				check(false, "Dasher cepat + bounty $5")
		else:
			strikers += 1
	check(strikers == 2 and dashers == 1, "Komposisi 2 striker + 1 dasher")
	await _kill_all(wm)
	check(cleared_idx == 0, "Wave 0 clear")

	# Wave 1: elite trio
	wm.start_wave(1, root)
	await process_frame
	check(wm.spawned.size() == 3, "Elite: 3 musuh")
	var names := {}
	for e in wm.spawned:
		names[e.display_name] = true
	check(names.has("BRUTE") and names.has("FURY") and names.has("SLAMMER"), "Trio BRUTE+FURY+SLAMMER")
	var b = null
	var fury = null
	var slam = null
	for e in wm.spawned:
		if e.display_name == "BRUTE":
			b = e
		elif e.display_name == "FURY":
			fury = e
		elif e.display_name == "SLAMMER":
			slam = e
	check(b != null and b.max_hp == 60 and b.ai_damage == 12, "Brute tebal + pukul 12")
	check(absf(b.ai_windup - 0.7) < 0.001, "Brute windup 0.7 (adil)")
	check(b.money_value == 8, "Brute bounty $8")
	check(b.body_w > 40.0, "Brute lebih besar")
	check(fury != null and fury.strike_hits == 2 and fury.money_value == 6, "Fury double-hit bounty $6")
	check(slam != null and slam.slam_damage == 10 and slam.ai_damage == 0, "Slammer mini-slam tanpa melee")
	await _kill_all(wm)
	check(cleared_idx == 1, "Elite clear")

	# Wave 2: boss tidak berubah
	wm.start_wave(2, root)
	await process_frame
	check(wm.boss_ref != null and wm.boss_ref.money_value == 20, "Boss bounty $20")
	check(wm.boss_ref.ai_enabled, "Boss tetap ngejar")
	await _kill_all(wm)
	check(cleared_idx == 2, "Boss clear -> run selesai")

	if failures == 0:
		print("ALL STEP6 TESTS PASSED")
	else:
		printerr("%d STEP6 TEST(S) FAILED" % failures)
	quit(failures)
