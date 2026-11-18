extends SceneTree
## Screenshot 3 stage backgrounds in-engine. Tanpa --headless.

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	for i in range(24):
		await process_frame
	main._hide_menu()
	main.state = 0
	for i in range(6):
		await process_frame
	var names := ["alley", "rooftop", "bar"]
	for t in range(3):
		main.stage_bg.set_theme(t, 0)
		for i in range(6):
			await process_frame
		var img := root.get_texture().get_image()
		var path := "/tmp/opencode/stage_%s.png" % names[t]
		var err := img.save_png(path)
		print("STAGE saved=%s err=%d" % [path, err])
	quit(0)
