extends SceneTree
## Smoke test visual (thug factory): dijalankan via
## godot --headless --path . -s tests/test_step8.gd

const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")
const Thugs = preload("res://scripts/thug_factory.gd")

var failures = 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)


func _init() -> void:
	# --- Factory frame ---
	var p = Thugs.frames("player")
	check(p.has_animation("walk") and p.get_frame_count("walk") == 2, "Player walk 2 frame")
	check(p.has_animation("jab") and p.has_animation("hook") and p.has_animation("upper"), "Player jab/hook/upper")
	var looks_ok := true
	for look in ["striker", "dasher", "fury", "slammer", "brute", "boss"]:
		var f = Thugs.frames(look)
		if not (f.has_animation("idle") and f.has_animation("walk") and f.has_animation("jab")):
			looks_ok = false
	check(looks_ok, "6 look musuh lengkap")
	check(Thugs.frames("fury") == Thugs.frames("fury"), "Cache dipakai ulang")

	# --- Player sprite + anim state ---
	var player = PlayerS.new()
	root.add_child(player)
	await process_frame
	check(player.sprite.animation == "idle", "Player idle awal")
	player.velocity = Vector2(200, 0)
	player._update_visual()
	check(player.sprite.animation == "walk", "Gerak -> walk")
	player.velocity = Vector2.ZERO
	player._start_jab(0)
	check(player.sprite.animation == "jab", "Jab1 -> jab")
	player._start_jab(1)
	check(player.sprite.animation == "hook", "Jab2 -> hook")
	player._start_jab(2)
	check(player.sprite.animation == "upper", "Finisher -> upper")
	player.facing = -1
	player._update_visual()
	check(player.sprite.flip_h, "Flip saat hadap kiri")
	check(player.sprite.scale.x > 1.2, "Player lebih besar (%.2f)" % player.sprite.scale.x)
	var ring_found := false
	for ch in player.get_children():
		if ch is Sprite2D and ch != player.shadow and ch != player.sprite:
			ring_found = true
	check(ring_found, "Ring penanda player ada")
	player.hp = 5
	player.invuln_timer = 0.0
	player.take_damage(10)
	check(player.dead and player.sprite.rotation < -1.0, "Mati -> roboh")

	# --- Enemy look + tint + spark ---
	var d = DummyS.new()
	d.look = "brute"
	d.body_color = Color("ff9fb0")
	root.add_child(d)
	await process_frame
	check(d.sprite.animation == "idle", "Brute idle (look mapping)")
	check(d.sprite.modulate == Color("ff9fb0"), "Tint varian menempel")
	check(d.sprite.scale.x > 1.1, "Musuh lebih besar (%.2f)" % d.sprite.scale.x)
	check(d.shadow != null, "Shadow ada")
	d.take_damage(5, Vector2.RIGHT, false)
	var found_spark := false
	for ch in d.get_children():
		if ch is AnimatedSprite2D and ch != d.sprite:
			found_spark = true
	check(found_spark, "Hitspark sprite muncul saat kena")

	# --- Main: bg + bar ---
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var alley_found := false
	for ch in main.get_children():
		if ch is Node2D and ch.has_node("Neon") and ch.has_node("Lamp"):
			alley_found = true
	check(alley_found, "Alley BG ada (neon+lampu)")
	check(main.hp_bar_fill.size.x > 200.0, "HP bar penuh di awal (%.0f)" % main.hp_bar_fill.size.x)
	main._refresh_hud(50, 100)
	check(absf(main.hp_bar_fill.size.x - 140.0) < 1.0, "HP 50 -> bar setengah (%.0f)" % main.hp_bar_fill.size.x)

	if failures == 0:
		print("ALL STEP8 TESTS PASSED")
	else:
		printerr("%d STEP8 TEST(S) FAILED" % failures)
	quit(failures)
