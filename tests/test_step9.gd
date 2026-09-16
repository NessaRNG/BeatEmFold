extends SceneTree
## Smoke test Post-MVP 9 (endless): dijalankan via
## godot --headless --path . -s tests/test_step9.gd

const DummyS = preload("res://scripts/dummy.gd")
const WaveS = preload("res://scripts/wave_manager.gd")
const RunS = preload("res://scripts/run_manager.gd")

var failures = 0
var cleared_idx = -99


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _on_cleared(idx: int) -> void:
	cleared_idx = idx


func _init() -> void:
	var wm = WaveS.new()
	root.add_child(wm)
	wm.wave_cleared.connect(_on_cleared)
	await process_frame

	check(WaveS.kind_of(5) == 2 and WaveS.loop_of(5) == 1, "Wave 5 = boss loop 1")
	check(wm.wave_sealed(5) == 5, "Seal rotasi: loop1 = FLUSH")
	check(wm.wave_sealed(8) == 1, "Seal rotasi: loop2 = PAIR")
	check("WAVE 4" in wm.wave_banner(3), "Banner wave 4")

	# Loop 1 fight: +1 musuh, HP +40%, token 2
	wm.start_wave(3, root)
	await process_frame
	check(wm.spawned.size() == 4, "Fight loop1: 4 musuh (dapat %d)" % wm.spawned.size())
	check(wm.spawned[0].max_hp == 42, "HP striker 30->42 (dapat %d)" % wm.spawned[0].max_hp)
	check(wm.spawned[0].ai_damage == 9, "Dmg +1/loop")
	check(DummyS.max_attackers == 2, "Token 2 di loop 1")

	# Loop 1 elite: +1 fury, brute 84
	wm.start_wave(4, root)
	await process_frame
	check(wm.spawned.size() == 4, "Elite loop1: 4 musuh")
	var brutes := 0
	for e in wm.spawned:
		if e.display_name == "BRUTE" and e.max_hp == 84:
			brutes += 1
	check(brutes == 1, "Brute 60->84")

	# Loop 1 boss: 225 HP, slam 17, bounty 25
	wm.start_wave(5, root)
	await process_frame
	var boss = wm.boss_ref
	check(boss != null and boss.max_hp == 225, "Boss 150->225 (dapat %d)" % boss.max_hp)
	check(boss.slam_damage == 17, "Slam 15->17")
	check(boss.money_value == 25, "Bounty 20->25")
	for e in wm.spawned:
		e.take_damage(999, Vector2.RIGHT, true)
	await process_frame
	await process_frame
	check(cleared_idx == 5, "Boss loop1 clear -> lanjut (bukan menang)")

	# Skor + best
	var run = RunS.new()
	root.add_child(run)
	await process_frame
	run.add_score(100)
	check(run.score == 100 and run.best == 100, "Skor + best ikut")
	run.save_best()
	var run2 = RunS.new()
	root.add_child(run2)
	run2.load_best()
	check(run2.best >= 100, "Best tersimpan (dapat %d)" % run2.best)

	DummyS.reset_tokens()
	if failures == 0:
		print("ALL STEP9 TESTS PASSED")
	else:
		printerr("%d STEP9 TEST(S) FAILED" % failures)
	quit(failures)
