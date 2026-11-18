extends SceneTree
## Smoke test power-up affinity + efek fisik. Dijalankan via
## godot --headless -s tests/test_step13_powerups.gd

const RunS = preload("res://scripts/run_manager.gd")
const CombatS = preload("res://scripts/combat_manager.gd")
const HandS = preload("res://scripts/hand_manager.gd")
const DeckS = preload("res://scripts/deck.gd")
const CardS = preload("res://scripts/card_data.gd")
const DummyS = preload("res://scripts/dummy.gd")
const PlayerS = preload("res://scripts/player.gd")
const PUS = preload("res://scripts/powerup_data.gd")

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _mkcard(rank: int, suit: int) -> CardS:
	var c := CardS.new()
	c.rank = rank
	c.suit = suit
	return c


func _init() -> void:
	# --- state & stack ---
	var run := RunS.new()
	root.add_child(run)
	check(run.powerup_count("fist_heavy") == 0, "Powerup awal kosong")
	run.add_powerup("fist_heavy")
	run.add_powerup("fist_heavy")
	check(run.powerup_count("fist_heavy") == 2, "Stack powerup bertambah")
	check(run.hands_per_wave() == 4, "Tanpa breath jatah tetap 4")
	run.add_powerup("move_breath")
	check(run.hands_per_wave() == 5, "Breath +1 jatah cash-in")
	run.reset_for_wave(0)
	check(run.hands_left == 5, "Reset wave pakai jatah breath")

	# --- roll 3 unik, utamakan yang belum dipakai ---
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var picks := PUS.roll(run.powerups, rng)
	check(picks.size() == 3, "Roll kasih 3 pilihan")
	var unik := {}
	for id in picks:
		unik[id] = true
	check(unik.size() == 3, "Roll pilihan unik")

	# --- Afinitas Spade: +2 dmg/kartu ♠ ---
	var player := PlayerS.new()
	root.add_child(player)
	player.run_manager = run
	var hm := HandS.new()
	hm.deck = DeckS.new()
	root.add_child(hm)
	var cm := CombatS.new()
	cm.player = player
	cm.hand_manager = hm
	cm.run_manager = run
	root.add_child(cm)

	var target := DummyS.new()
	root.add_child(target)
	target.hp = 200
	target.max_hp = 200
	target.position = Vector2(120, 500)
	player.position = Vector2(40, 500)
	player.facing = 1
	target.add_to_group("enemies")
	await process_frame

	# Pilih manual 3 kartu spade supaya used = 3 (tanpa auto-pick).
	# Pair 7♠7♠ + 9♠, suit dominan Spade -> 25*1.5=37, afinitas +2*3=6 => 43.
	run.powerups.clear()
	run.add_powerup("aff_spade")
	hm.hand = [_mkcard(7, CardS.SPADES), _mkcard(7, CardS.SPADES), _mkcard(9, CardS.SPADES)]
	hm.toggle_select(0)
	hm.toggle_select(1)
	hm.toggle_select(2)
	var before := target.hp
	cm.try_cash_in()
	var dealt := before - target.hp
	check(dealt == 43, "Afinitas Spade +6 damage (dapat %d)" % dealt)

	# --- Finishers: J/Q/K/A guard-break ---
	target.hp = 200
	target.telegraph = 0.4
	run.powerups.clear()
	run.add_powerup("finisher")
	hm.hand = [_mkcard(13, CardS.HEARTS), _mkcard(14, CardS.HEARTS)]
	run.hands_left = 4
	cm.try_cash_in()
	check(target.telegraph == 0.0 and target.stagger_timer >= 0.45, "Finisher guard-break (telegraph batal)")

	# --- break_guard method langsung ---
	target.telegraph = 0.5
	target.break_guard(0.5)
	check(target.telegraph == 0.0, "break_guard() membatalkan telegraph")

	if failures == 0:
		print("ALL STEP13 TESTS PASSED")
	else:
		printerr("%d STEP13 TEST(S) FAILED" % failures)
	quit(failures)
