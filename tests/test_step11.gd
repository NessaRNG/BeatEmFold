extends SceneTree
## Smoke test Post-MVP 12 (tutorial): dijalankan via
## godot --headless --path . -s tests/test_step11.gd

const Cards = preload("res://scripts/card_data.gd")

var failures = 0
var finished_fired := false


func _c(rank: int, suit: int):
	var c = Cards.new()
	c.rank = rank
	c.suit = suit
	return c


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _on_finished() -> void:
	finished_fired = true


func _init() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var tut = main.tutorial
	tut.finished.connect(_on_finished)

	# Mulai tutorial dari menu (via pertanyaan).
	main._press_mulai()
	main._start_tutorial()
	await process_frame
	check(main.state == 5, "State tutorial")
	check(tut.step == 0 and tut.tutor != null, "Samsack spawn, langkah 0")
	check(tut.box.visible, "Kotak tutorial tampil")

	# 0: gerak.
	main.player.position = Vector2(600, 520)
	await process_frame
	check(tut.step == 1, "Gerak -> langkah 1")

	# 1: 3x kena. Hit asli juga draw (deal 3 + 3 = 6) -> langkah 2
	# auto-lulus karena 5+ kartu. Integrasi jalan.
	main.player.hit_landed.emit()
	main.player.hit_landed.emit()
	main.player.hit_landed.emit()
	check(tut.step == 3, "3 jab + draw -> langkah 3")

	# 3: pilih 2.
	main.hand_manager.toggle_select(0)
	main.hand_manager.toggle_select(1)
	check(tut.step == 4, "Pilih 2 -> langkah 4")

	# 4: cash-in (langsung tembak sinyal resolve).
	main.combat_manager.cash_in_resolved.emit("PAIR", 40, 1)
	check(tut.step == 5, "Cash -> langkah 5")

	# 5: dash.
	main.player.dashed.emit()
	check(tut.step == 6, "Dash -> langkah 6")

	# 6: bunuh samsack -> selesai -> wave 0 jalan.
	tut.tutor.take_damage(999, Vector2.RIGHT, true)
	await process_frame
	await process_frame
	check(finished_fired, "Finished fired")
	check(main.state == 0, "Lanjut wave 0")
	check(main.wave_manager.spawned.size() == 3, "Wave 0 spawn")

	if failures == 0:
		print("ALL STEP11 TESTS PASSED")
	else:
		printerr("%d STEP11 TEST(S) FAILED" % failures)
	quit(failures)
