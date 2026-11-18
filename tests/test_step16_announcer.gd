extends SceneTree
## Smoke test scope announcer: area ganti vs spam cash-in. Headless.

const WM = preload("res://scripts/wave_manager.gd")

var failures = 0
func check(c: bool, l: String) -> void:
	if c: print("PASS: %s" % l)
	else: failures += 1; printerr("FAIL: %s" % l)

func _init() -> void:
	# Area tier boundaries: 0-14 ALLEY, 15-29 ROOFTOP, 30-44 CLUB.
	check(WM.tier_of(0) == 0 and WM.tier_of(14) == 0, "Wave 0-14 = ALLEY")
	check(WM.tier_of(15) == 1 and WM.tier_of(29) == 1, "Wave 15-29 = ROOFTOP")
	check(WM.tier_of(30) == 2 and WM.tier_of(44) == 2, "Wave 30-44 = CLUB")
	check(WM.tier_of(14) != WM.tier_of(15), "Area ganti di wave 15")
	check(WM.tier_of(29) != WM.tier_of(30), "Area ganti di wave 30")

	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	for i in range(24): await process_frame
	main._press_mulai(); main._start_game()
	for i in range(20): await process_frame

	# Announcer tidak berubah saat cash-in resolve (spam dihapus).
	main.combat_label.text = "SENTINEL"
	main._on_cash_resolved("PAIR", 25, 1)
	check(main.combat_label.text == "SENTINEL", "Cash-in tidak timpa announcer")

	# Announce area pakai nama tier + nomor wave.
	main._announce_area(15)
	check("ROOFTOP" in main.combat_label.text and "WAVE 16" in main.combat_label.text,
		"Area announce: %s" % main.combat_label.text)

	Engine.time_scale = 1.0
	if failures == 0: print("ALL STEP16 TESTS PASSED")
	else: printerr("%d STEP16 TEST(S) FAILED" % failures)
	quit(failures)
