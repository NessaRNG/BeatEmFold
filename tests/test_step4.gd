extends SceneTree
## Smoke test Step 4 (wave/shop/boss): dijalankan via
## godot --headless --path . -s tests/test_step4.gd

const Cards = preload("res://scripts/card_data.gd")
const Hands = preload("res://scripts/hand_manager.gd")
const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")
const CombatS = preload("res://scripts/combat_manager.gd")
const RunS = preload("res://scripts/run_manager.gd")
const JokerS = preload("res://scripts/joker_manager.gd")
const WaveS = preload("res://scripts/wave_manager.gd")
const JokerD = preload("res://scripts/joker_data.gd")
const ShopS = preload("res://scripts/shop_ui.gd")

var failures = 0
var cleared_idx = -1
var shop_closed_fired = false
var got_name = ""
var got_dmg = 0
var got_n = 0
var fail_msg = ""


func _on_cash_resolved(hand_name: String, damage: int, n: int) -> void:
	got_name = hand_name
	got_dmg = damage
	got_n = n


func _on_cash_failed(reason: String) -> void:
	fail_msg = reason


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


func _on_cleared(idx: int) -> void:
	cleared_idx = idx


func _on_shop_closed() -> void:
	shop_closed_fired = true


func _init() -> void:
	# --- RunManager: jatah wave ---
	var run = RunS.new()
	root.add_child(run)
	await process_frame
	run.reset_for_wave(0)
	check(run.can_cash_in() and run.hands_left == 4, "Jatah cash 4/wave")
	for i in range(4):
		run.use_cash_in()
	check(not run.can_cash_in(), "Cash habis setelah 4x")
	check(run.can_discard(), "Jatah buang 3/wave")
	run.reset_for_wave(1)
	check(run.can_cash_in() and run.can_discard(), "Jatah reset wave baru")

	# --- Combat + jatah: cash ke-5 ditolak ---
	var player = PlayerS.new()
	player.position = Vector2(400, 520)
	root.add_child(player)
	var dummy = DummyS.new()
	dummy.max_hp = 500
	dummy.hp = 500
	dummy.respawns = false
	dummy.position = Vector2(470, 520)
	root.add_child(dummy)
	var hm = Hands.new()
	root.add_child(hm)
	var jok = JokerS.new()
	root.add_child(jok)
	var cm = CombatS.new()
	cm.player = player
	cm.hand_manager = hm
	cm.run_manager = run
	cm.jokers = jok
	root.add_child(cm)
	await process_frame
	await process_frame
	run.reset_for_wave(0)
	cm.cash_in_failed.connect(_on_cash_failed)
	cm.cash_in_resolved.connect(_on_cash_resolved)
	for i in range(4):
		hm.hand.assign([_c(7, 1), _c(7, 2), _c(13, 1)])
		hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
		cm.try_cash_in()
	check(run.hands_left == 0, "4 cash makan jatah habis")
	hm.hand.assign([_c(7, 1), _c(7, 2), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	fail_msg = ""
	cm.try_cash_in()
	check(fail_msg != "" and hm.hand.size() == 3, "Cash ke-5 ditolak, kartu aman")

	# --- Planet + Bloodlust ---
	run.reset_for_wave(0)
	run.upgrade_planet(1) # Pair Lv1: +8 chips +1 mult
	hm.hand.assign([_c(5, 2), _c(5, 3), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	# (10+8 +5+5)x(2+1) = 84
	check(got_dmg == 84, "Planet Pair Lv1: 84 dmg (dapat %d)" % got_dmg)
	player.hp = 40 # <50%: bloodlust belum dibeli
	run.reset_for_wave(0)
	hm.hand.assign([_c(5, 2), _c(5, 3), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(got_dmg == 84, "Tanpa joker tetap 84 (dapat %d)" % got_dmg)

	# --- Straight sealed (Boss Blind) ---
	cm.sealed_hand = 4 # STRAIGHT
	run.reset_for_wave(0)
	hm.hand.assign([_c(5, 2), _c(6, 3), _c(7, 1), _c(8, 2), _c(9, 0)])
	hm.selected_cards.assign(hm.hand.duplicate())
	cm.try_cash_in()
	check(got_name == "STRAIGHT SEALED!", "Sealed downgrade (%s)" % got_name)
	check(got_dmg == 5 + 5 + 6 + 7 + 8 + 9, "Sealed dmg flat 5+chips=%d (dapat %d)" % [40, got_dmg])
	cm.sealed_hand = -1

	# --- Joker: bloodlust / spade_drill / parry ---
	for j in JokerD.starter_pool():
		if j.id == "bloodlust":
			jok.add(j)
	check(jok.has("bloodlust"), "Joker bloodlust dibeli")
	player.hp = 40
	run.reset_for_wave(0)
	hm.hand.assign([_c(5, 2), _c(5, 3), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	# (10+8 +5+5)x(2+1 planet+2 bloodlust) = 140
	check(got_dmg == 140, "Bloodlust HP<50%%: 140 dmg (dapat %d)" % got_dmg)
	player.hp = 100
	player.invuln_timer = 0.0
	for j in JokerD.starter_pool():
		if j.id == "parry":
			jok.add(j)
	jok.on_discard(player)
	check(player.invuln_timer >= 1.0, "Parry: discard = shield 1s")

	# --- WaveManager: spawn 3, clear saat habis ---
	var wm = WaveS.new()
	root.add_child(wm)
	wm.wave_cleared.connect(_on_cleared)
	await process_frame
	wm.start_wave(0, root)
	check(wm.spawned.size() == 3, "Wave 0 spawn 3 dummy")
	cleared_idx = -1
	for e in wm.spawned:
		e.take_damage(999, Vector2.RIGHT, true)
	await process_frame
	await process_frame
	check(cleared_idx == 0, "Wave clear terdeteksi")
	wm.start_wave(2, root)
	check(wm.boss_ref != null and wm.boss_ref.is_boss, "Wave 2 = boss")
	check(wm.boss_ref.max_hp == 150 and wm.boss_ref.slam_damage == 15, "Boss stat")

	# --- Boss slam: telegraph lalu damage (deterministik, drive manual) ---
	player.position = Vector2(800, 520)
	player.hp = 100
	player.invuln_timer = 0.0
	var boss = wm.boss_ref
	boss.position = Vector2(850, 520)
	boss.slam_cd = 0.0
	boss.telegraph = 0.0
	boss._update_slam(0.1)
	check(boss.telegraph > 0.0, "Slam mulai telegraph saat player dekat")
	boss._update_slam(0.6)
	check(player.hp == 85, "Slam 15 dmg (hp %d)" % player.hp)
	check(boss.slam_cd >= 2.9, "Slam cooldown reset")

	# --- Shop: beli joker + planet + tutup ---
	var shop = ShopS.new()
	root.add_child(shop)
	await process_frame
	var run2 = RunS.new()
	root.add_child(run2)
	var jok2 = JokerS.new()
	root.add_child(jok2)
	var hm2 = Hands.new()
	root.add_child(hm2)
	await process_frame
	hm2.deal(1) # pastikan deck kebentuk
	run2.add_money(20)
	shop.setup(run2, jok2, hm2.deck, hm2)
	shop.shop_closed.connect(_on_shop_closed)
	shop.open_shop(1)
	check(shop.open and shop.rows.size() == 6, "Shop buka 6 opsi")
	shop.buy_index(0) # bloodlust $6
	check(jok2.has("bloodlust") and run2.money == 14, "Beli joker $6 (sisa $%d)" % run2.money)
	shop.buy_index(3) # planet pair $5
	check(run2.planet_level(1) == 1 and run2.money == 9, "Beli planet $5 (sisa $%d)" % run2.money)
	shop_closed_fired = false
	shop.close_shop()
	check(shop_closed_fired and not shop.open, "Shop tutup -> lanjut")
	check(shop.continue_button.hotkey == KEY_L, "Lanjut shortcut L")
	# Harga loop 1 naik 25%: planet $5 -> $6.
	run2.wave_index = 3
	shop.open_shop(1)
	var found6 := false
	var btn3: Button = shop.rows[3]["btn"]
	for ch in btn3.get_children():
		if ch is Label and ch.text == "$6":
			found6 = true
	check(found6, "Harga loop1 +25%")
	shop.close_shop()

	if failures == 0:
		print("ALL STEP4 TESTS PASSED")
	else:
		printerr("%d STEP4 TEST(S) FAILED" % failures)
	quit(failures)
