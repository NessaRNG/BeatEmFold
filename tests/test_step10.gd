extends SceneTree
## Smoke test Post-MVP 10 (menu + pause): dijalankan via
## godot --headless --path . -s tests/test_step10.gd

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# --- Menu awal ---
	check(main.state == 4, "Boot ke menu (state %d)" % main.state)
	check(main.wave_manager.spawned.is_empty(), "Belum spawn musuh di menu")
	check(not main.hud_panel.visible, "HUD sembunyi di menu")
	check(main.menu_title.visible, "Judul tampil")
	check("TERBAIK" in main.menu_best.text, "Best tampil (%s)" % main.menu_best.text)
	var keys_found := false
	for ch in main.get_children():
		if ch.get_class() == "Node" and ch.get("game") == main:
			keys_found = ch.process_mode == Node.PROCESS_MODE_ALWAYS
	check(keys_found, "PauseKeys ALWAYS ada")

	# --- Mulai game via tombol shortcut: menu -> tanya -> langsung main ---
	check(main.menu_mulai.hotkey == KEY_M, "MULAI shortcut M")
	check(main.menu_mulai.text.begins_with("(M)"), "Hint tampil (%s)" % main.menu_mulai.text)
	main.menu_mulai.pressed.emit()
	check(main.state == 6, "Mulai -> tanya tutorial (state %d)" % main.state)
	check(main.ask_text.visible, "Pertanyaan tampil")
	main.ask_tidak.pressed.emit()
	await process_frame
	check(main.state == 0, "TIDAK -> fight")
	check(main.wave_manager.spawned.size() == 3, "Wave 0 spawn")
	check(main.hud_panel.visible and not main.menu_title.visible, "HUD tampil, menu hilang")
	check(not main.seal_badge.visible, "Tanpa seal: badge sembunyi")
	main.combat_manager.sealed_hand = 4
	main._refresh_seal()
	check(main.seal_badge.visible and "STRAIGHT" in main.seal_text.text, "Seal tampil (%s)" % main.seal_text.text)
	main.combat_manager.sealed_hand = -1
	main._refresh_seal()

	# --- Pause via fungsi + resume via tombol ---
	main.toggle_pause()
	check(paused, "Pause: tree berhenti")
	check(main.pause_title.visible, "Overlay pause tampil")
	await process_frame # guard nav: frame berbeda
	main.pause_lanjut.pressed.emit()
	check(not paused, "Tombol LANJUTKAN resume")
	check(not main.pause_title.visible, "Overlay hilang")

	# --- Guard ---
	main.to_menu()
	check(main.state == 0, "M di luar pause diabaikan")
	main.restart_run()
	check(main.state == 0, "T di luar over/pause diabaikan")

	# --- Game over: overlay + tombol ---
	main.player.hp = 5
	main.player.invuln_timer = 0.0
	main.player.take_damage(10)
	await process_frame
	check(main.state == 2, "Mati -> game over")
	check(main.over_title.visible, "Judul K.O. tampil")
	check("SKOR" in main.over_score.text, "Skor tampil (%s)" % main.over_score.text)
	check(main.over_retry.visible and main.over_menu_btn.visible, "Tombol retry + menu ada")
	check(main.over_retry.hotkey == KEY_C, "Retry shortcut C")
	main.toggle_pause()
	check(not paused, "Pause ditolak saat mati")

	if failures == 0:
		print("ALL STEP10 TESTS PASSED")
	else:
		printerr("%d STEP10 TEST(S) FAILED" % failures)
	quit(failures)
