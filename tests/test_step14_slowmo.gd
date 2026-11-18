extends SceneTree
## Smoke test slow-mo mode pilih kartu + controller time_scale. Headless.

const MainS = preload("res://scenes/main.tscn")

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	Engine.time_scale = 1.0
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	for i in range(20):
		await process_frame

	# Default normal.
	check(is_equal_approx(Engine.time_scale, 1.0), "Default time_scale 1.0 (%.2f)" % Engine.time_scale)

	# Tab held -> sustained slow.
	main.select_slow_active = true
	main._apply_time_scale()
	check(is_equal_approx(Engine.time_scale, 0.45), "Tab slow 0.45 (%.2f)" % Engine.time_scale)

	# Card pick pulse layered deeper.
	main._pulse_select()
	check(is_equal_approx(Engine.time_scale, 0.20), "Pulse pilih 0.20 (%.2f)" % Engine.time_scale)

	# Hitstop during select slow must NOT override it to 1.0 when it ends.
	# Simulate an active hitstop with a factor that is shallower than select slow.
	main.hitstop_active = true
	main.hitstop_factor = 1.0
	main._apply_time_scale()
	check(is_equal_approx(Engine.time_scale, 0.20), "Hitstop tidak timpa pulse (%.2f)" % Engine.time_scale)
	main.hitstop_active = false
	main.hitstop_factor = 1.0
	main._apply_time_scale()
	check(is_equal_approx(Engine.time_scale, 0.20), "Hitstop selesai, pulse masih (%.2f)" % Engine.time_scale)

	# Clear pulse -> back to sustained select slow.
	main.select_pulse_until = 0.0
	main._apply_time_scale()
	check(is_equal_approx(Engine.time_scale, 0.45), "Pulse habis -> 0.45 (%.2f)" % Engine.time_scale)

	# Release Tab -> full normal.
	main.select_slow_active = false
	main._apply_time_scale()
	check(is_equal_approx(Engine.time_scale, 1.0), "Lepas Tab -> 1.0 (%.2f)" % Engine.time_scale)

	Engine.time_scale = 1.0
	if failures == 0:
		print("ALL STEP14 TESTS PASSED")
	else:
		printerr("%d STEP14 TEST(S) FAILED" % failures)
	quit(failures)
