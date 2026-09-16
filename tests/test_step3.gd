extends SceneTree
## Smoke test Step 3 (Cash-In): dijalankan via
## godot --headless --path . -s tests/test_step3.gd

const Cards = preload("res://scripts/card_data.gd")
const Hands = preload("res://scripts/hand_manager.gd")
const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")
const CombatS = preload("res://scripts/combat_manager.gd")

var failures = 0
var last_name = ""
var last_dmg = 0
var last_n = 0
var fail_reason = ""


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


func _on_resolved(hand_name: String, damage: int, n: int) -> void:
	last_name = hand_name
	last_dmg = damage
	last_n = n


func _on_failed(reason: String) -> void:
	fail_reason = reason


func _mk_dummy(x: float, hp: int):
	var d = DummyS.new()
	d.max_hp = hp
	d.hp = hp
	d.position = Vector2(x, 520)
	root.add_child(d)
	return d


func _init() -> void:
	var player = PlayerS.new()
	player.position = Vector2(400, 520)
	root.add_child(player)
	var dummy_a = _mk_dummy(470.0, 200)
	var dummy_b = _mk_dummy(520.0, 200)
	var dummy_c = _mk_dummy(300.0, 200) # belakang player
	await process_frame
	await process_frame

	var hm = Hands.new()
	root.add_child(hm)
	var cm = CombatS.new()
	cm.player = player
	cm.hand_manager = hm
	root.add_child(cm)
	cm.cash_in_resolved.connect(_on_resolved)
	cm.cash_in_failed.connect(_on_failed)
	await process_frame

	# --- 1. Pair clubs: single lock depan, dmg flat, sisa stay, i-frame ---
	player.facing = 1
	player.hp = 100
	player.invuln_timer = 0.0
	hm.hand.assign([_c(5, 2), _c(5, 3), _c(13, 1), _c(9, 0)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	last_name = ""
	cm.try_cash_in()
	# Pair flat 25, clubs = stagger, bukan spades = tanpa x1.5
	check(last_name == "PAIR", "Cash-In Pair resolved (dapat %s)" % last_name)
	check(last_dmg == 25, "Pair flat = 25 dmg (dapat %d)" % last_dmg)
	check(last_n == 1, "Pair single-lock 1 target (dapat %d)" % last_n)
	check(dummy_a.hp == 175, "Dummy depan kena 25 (hp %d)" % dummy_a.hp)
	check(dummy_b.hp == 200 and dummy_c.hp == 200, "Target lain aman")
	check(hm.hand.size() == 2, "Hanya yang dipakai kebuang, sisa stay (%d)" % hm.hand.size())
	check(player.invuln_timer >= 0.29, "i-frame 0.3s cash-in")
	check(dummy_a.stagger_timer >= 0.5, "Clubs = stun masif")

	# --- 2. Spades x1.5 simpel ---
	dummy_a.hp = 200
	hm.hand.assign([_c(5, 1), _c(5, 0), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(last_dmg == 37, "Pair spades dominan = 25x1.5=37 (dapat %d)" % last_dmg)
	check(dummy_a.hp == 163, "Dummy kena 37 (hp %d)" % dummy_a.hp)
	# Two pair spades dominan -> 40x1.5=60.
	dummy_a.hp = 200
	hm.hand.assign([_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3)])
	hm.selected_cards.assign(hm.hand.duplicate())
	cm.try_cash_in()
	check(last_dmg == 60, "Two pair spades = 60 (dapat %d)" % last_dmg)

	# --- 3. Hearts heal flat ---
	player.hp = 80
	hm.hand.assign([_c(7, 0), _c(7, 2), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(last_dmg == 25, "Pair hearts flat 25 (dapat %d)" % last_dmg)
	check(player.hp == 88, "Heal flat +8 (80 -> %d)" % player.hp)

	# --- 4. Diamonds shield ---
	player.invuln_timer = 0.0
	hm.hand.assign([_c(7, 3), _c(7, 2), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1]])
	cm.try_cash_in()
	check(player.invuln_timer >= 1.0, "Diamonds = shield 1.5s")

	# --- 5. Flush 360°: depan + belakang kena ---
	dummy_a.hp = 200
	dummy_a.dead = false
	dummy_b.hp = 200
	dummy_b.dead = false
	dummy_c.hp = 200
	dummy_c.dead = false
	hm.hand.assign([_c(14, 0), _c(13, 0), _c(9, 0), _c(7, 0), _c(5, 0), _c(2, 2)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1], hm.hand[2], hm.hand[3], hm.hand[4]])
	cm.try_cash_in()
	# Flush flat 90, hearts -> heal 8
	check(last_name == "FLUSH" and last_n == 3, "Flush 360 kena 3 target (%s x%d)" % [last_name, last_n])
	check(dummy_a.hp == 110 and dummy_c.hp == 110, "Depan + belakang kena 90 (hp %d/%d)" % [dummy_a.hp, dummy_c.hp])
	check(hm.hand.size() == 1, "Flush makan 5, sisa 1 (%d)" % hm.hand.size())

	# --- 6. Auto best-hand tanpa seleksi ---
	dummy_a.hp = 200
	dummy_a.dead = false
	dummy_b.hp = 200
	dummy_b.dead = false
	dummy_c.hp = 200
	dummy_c.dead = false
	player.facing = 1
	hm.hand.assign([_c(7, 1), _c(7, 2), _c(13, 1), _c(12, 3)])
	hm.selected_cards.clear()
	cm.try_cash_in()
	check(last_name == "PAIR" and last_dmg == 37, "Auto = pair 7 spades 37 (%s %d)" % [last_name, last_dmg])
	check(hm.hand.size() == 2, "Auto makan 2, sisa K Q (%d)" % hm.hand.size())

	# --- 7. Two Pair = double lock, belakang aman ---
	dummy_a.hp = 200
	dummy_b.hp = 200
	dummy_c.hp = 200
	hm.hand.assign([_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3), _c(13, 1)])
	hm.selected_cards.assign([hm.hand[0], hm.hand[1], hm.hand[2], hm.hand[3]])
	cm.try_cash_in()
	# Two pair flat 40 x1.5 spades = 60
	check(last_name == "TWO PAIR" and last_n == 2, "Two Pair double-lock (%s x%d)" % [last_name, last_n])
	check(dummy_a.hp == 140 and dummy_b.hp == 140, "2 depan kena 60 (hp %d/%d)" % [dummy_a.hp, dummy_b.hp])
	check(dummy_c.hp == 200, "Belakang aman dari double-lock")

	# --- 8. Straight = garis: jauh kena, belakang aman ---
	dummy_a.position = Vector2(750, 520)
	dummy_a.hp = 200
	dummy_c.hp = 200
	hm.hand.assign([_c(5, 2), _c(6, 3), _c(7, 1), _c(8, 2), _c(9, 0)])
	hm.selected_cards.assign(hm.hand.duplicate())
	cm.try_cash_in()
	check(last_name == "STRAIGHT" and last_n >= 1, "Straight piercing (%s x%d)" % [last_name, last_n])
	check(dummy_a.hp < 200 and dummy_c.hp == 200, "Jauh kena, belakang aman")

	# --- 9. Whiff: kartu <2 ---
	hm.hand.assign([_c(14, 1)])
	hm.selected_cards.clear()
	fail_reason = ""
	cm.try_cash_in()
	check(fail_reason != "", "Whiff kasih alasan, tidak crash")
	check(hm.hand.size() == 1, "Whiff tidak makan kartu")

	# --- 10. Seleksi cap 5 ---
	hm.hand.assign([_c(2, 0), _c(3, 1), _c(4, 2), _c(5, 3), _c(6, 0), _c(7, 1)])
	hm.selected_cards.clear()
	for i in range(6):
		hm.toggle_select(i)
	check(hm.selected_cards.size() == 5, "Seleksi cap 5 (dapat %d)" % hm.selected_cards.size())

	if failures == 0:
		print("ALL STEP3 TESTS PASSED")
	else:
		printerr("%d STEP3 TEST(S) FAILED" % failures)
	quit(failures)
