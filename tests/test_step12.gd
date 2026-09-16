extends SceneTree
## Smoke test Post-MVP 15 (sine wave): dijalankan via
## godot --headless --path . -s tests/test_step12.gd

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _wait_until(call: Callable, timeout_ms: int) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < timeout_ms:
		await process_frame
		if call.call():
			return true
	return false


func _init() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._press_mulai()
	main._start_game()
	await process_frame
	check(main.state == 0, "Fight jalan")
	check(main.wave_manager.spawned.size() == 3, "Wave 0 spawn")
	# Tunggu walk-in selesai (player kembali + kontrol buka).
	var arrived := await _wait_until(func() -> bool: return not main.player.controls_locked, 8000)
	check(arrived, "Walk-in selesai, kontrol kembali")
	check(main.player.position.x > 300.0, "Player di arena (x=%.0f)" % main.player.position.x)
	var ai_on := true
	for e in main.wave_manager.spawned:
		ai_on = ai_on and e.ai_enabled
	check(ai_on, "AI musuh aktif setelah arrival")

	# Habisi semua -> sine clear -> shop buka, player keluar arena.
	for e in main.wave_manager.spawned:
		e.take_damage(999, Vector2.RIGHT, true)
	var shopped := await _wait_until(func() -> bool: return main.shop_ui.open, 15000)
	check(shopped, "Shop buka setelah sine clear")
	check(main.player.position.x > 1240.0, "Player jalan keluar (x=%.0f)" % main.player.position.x)

	# Tutup shop -> wave 1 + walk-in dari kiri.
	main.shop_ui.close_shop()
	await process_frame
	check(main.wave_manager.active_index == 1, "Wave 1 mulai")
	check(main.player.position.x < 400.0, "Masuk dari kiri (x=%.0f)" % main.player.position.x)
	arrived = await _wait_until(func() -> bool: return not main.player.controls_locked, 8000)
	check(arrived and main.player.position.x > 300.0, "Walk-in wave 1 selesai")

	if failures == 0:
		print("ALL STEP12 TESTS PASSED")
	else:
		printerr("%d STEP12 TEST(S) FAILED" % failures)
	quit(failures)
