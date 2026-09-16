extends SceneTree
## Screenshot diagnostik: buka main scene dgn rendering.
## Argumen: "menu" (default) atau "game" (mulai main dulu).
## Jalankan TANPA --headless (butuh display).

func _init() -> void:
	var mode := "menu"
	for a in OS.get_cmdline_user_args():
		if a == "game" or a == "over" or a == "tutor" or a == "ask" or a == "boss":
			mode = a
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	for i in range(20):
		await process_frame
	var path := "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_shot.png"
	if mode != "menu":
		if mode == "tutor":
			main._press_mulai()
			main._start_tutorial()
		elif mode == "ask":
			main._press_mulai()
		elif mode == "boss":
			main._press_mulai()
			main._start_game()
			await _clear_to(main, 2)
		else:
			main._press_mulai()
			main._start_game()
		for i in range(60):
			await process_frame
		path = "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_game.png"
	if mode == "over":
		main.player.hp = 5
		main.player.invuln_timer = 0.0
		main.player.take_damage(10)
		for i in range(30):
			await process_frame
		path = "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_over.png"
	if mode == "boss":
		path = "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_boss.png"
	if mode == "tutor":
		path = "C:/Users/Nessa/AppData/Local/Temp/opencode/beatemfold_tutor.png"
	await process_frame
	var img := root.get_texture().get_image()
	var err := img.save_png(path)
	print("SCREENSHOT saved=%s err=%d" % [path, err])
	quit(0)


## Dorong progres: habisi wave 0..target-1 (termasuk shop) secara instan.
func _clear_to(main, target: int) -> void:
	var t0 := Time.get_ticks_msec()
	while main.wave_manager.active_index < target and Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		if main.state == 1 and main.shop_ui.open: # ST_SHOP
			main.shop_ui.close_shop()
			continue
		for e in main.wave_manager.spawned:
			if is_instance_valid(e) and not e.dead:
				e.take_damage(9999, Vector2.RIGHT, true)
