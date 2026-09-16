extends SceneTree
## Smoke test Step 4 (wave/shop/boss): dijalankan via
## godot --headless --path . -s tests/test_step4.gd

const Cards = preload("res://scripts/card_data.gd")
const Hands = preload("res://scripts/hand_manager.gd")
const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")
const CombatS = preload("res://scripts/combat_manager.gd")
const RunS = preload("res://scripts/run_manager.gd")
const WaveS = preload("res://scripts/wave_manager.gd")
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
	var cm = CombatS.new()
	cm.player = player
	cm.hand_manager = hm
	cm.run_manager = run
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

	# --- Flat damage + suit simpel ---
	run.reset_for_wave(0)
	hm.hand.assign([_c(5, 2), _c(5, 3), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(got_dmg == 25, "Pair flat 25 (dapat %d)" % got_dmg)
	player.hp = 80
	run.reset_for_wave(0)
	hm.hand.assign([_c(7, 0), _c(7, 2), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(got_dmg == 25 and player.hp == 88, "Hearts heal +8 (dmg %d hp %d)" % [got_dmg, player.hp])

	# --- Straight sealed ---
	cm.sealed_hand = 4 # STRAIGHT
	run.reset_for_wave(0)
	hm.hand.assign([_c(5, 2), _c(6, 3), _c(7, 1), _c(8, 2), _c(9, 0)])
	hm.selected_cards.assign(hm.hand.duplicate())
	cm.try_cash_in()
	check(got_name == "STRAIGHT SEALED!", "Sealed downgrade (%s)" % got_name)
	check(got_dmg == 15, "Sealed dmg flat 15 (dapat %d)" % got_dmg)
	cm.sealed_hand = -1
	player.hp = 100

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

	# --- Shop simpel: tambah/hapus kartu + tutup ---
	var shop = ShopS.new()
	root.add_child(shop)
	await process_frame
	var run2 = RunS.new()
	root.add_child(run2)
	var hm2 = Hands.new()
	root.add_child(hm2)
	await process_frame
	hm2.deal(1) # pastikan deck kebentuk
	run2.add_money(20)
	shop.setup(run2, hm2.deck, hm2)
	shop.shop_closed.connect(_on_shop_closed)
	shop.open_shop()
	check(shop.open and shop.rows.size() == 2, "Shop buka 2 opsi")
	var deck_n: int = hm2.deck.cards.size() + hm2.hand.size()
	shop.buy_index(0) # tambah kartu $3
	check(run2.money == 17, "Beli tambah kartu $3 (sisa $%d)" % run2.money)
	check(hm2.deck.cards.size() + hm2.hand.size() == deck_n + 1, "Deck +1 kartu")
	shop_closed_fired = false
	shop.close_shop()
	check(shop_closed_fired and not shop.open, "Shop tutup -> lanjut")
	check(shop.continue_button.hotkey == KEY_L, "Lanjut shortcut L")
	# Harga loop 1 naik 25%: $3 -> $4.
	run2.wave_index = 3
	shop.open_shop()
	var found4 := false
	var btn0: Button = shop.rows[0]["btn"]
	for ch in btn0.get_children():
		if ch is Label and ch.text == "$4":
			found4 = true
	check(found4, "Harga loop1 +25%")
	shop.close_shop()

	if failures == 0:
		print("ALL STEP4 TESTS PASSED")
	else:
		printerr("%d STEP4 TEST(S) FAILED" % failures)
	quit(failures)
