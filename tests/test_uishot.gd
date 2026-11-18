extends SceneTree
## Screenshot UI diagnostik ke /tmp/opencode. Jalankan TANPA --headless.

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var mode := "game"
	for a in OS.get_cmdline_user_args():
		if a in ["menu", "game", "shop", "boss"]:
			mode = a
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	for i in range(20):
		await process_frame
	var path := "/tmp/opencode/ui_%s.png" % mode
	if mode == "game" or mode == "shop" or mode == "boss":
		main._press_mulai()
		main._start_game()
		for i in range(40):
			await process_frame
	if mode == "shop":
		for e in main.wave_manager.spawned:
			if is_instance_valid(e) and not e.dead:
				e.take_damage(9999, Vector2.RIGHT, true)
		var t0 := Time.get_ticks_msec()
		while not main.shop_ui.open and Time.get_ticks_msec() - t0 < 15000:
			await process_frame
	if mode == "boss":
		await _clear_to(main, 2)
	await process_frame
	var img := root.get_texture().get_image()
	var err := img.save_png(path)
	print("SCREENSHOT saved=%s err=%d" % [path, err])
	quit(0)


func _clear_to(main, target: int) -> void:
	var t0 := Time.get_ticks_msec()
	while main.wave_manager.active_index < target and Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		if main.state == 1 and main.shop_ui.open:
			main.shop_ui.close_shop()
			continue
		for e in main.wave_manager.spawned:
			if is_instance_valid(e) and not e.dead:
				e.take_damage(9999, Vector2.RIGHT, true)
