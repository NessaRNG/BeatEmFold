extends SceneTree
## Smoke test Step 2: dijalankan via
## godot --headless --path . -s tests/test_step2.gd
## (pakai preload karena run -s tidak baca cache global class)

const Cards = preload("res://scripts/card_data.gd")
const Evaluator = preload("res://scripts/poker_evaluator.gd")
const DeckScript = preload("res://scripts/deck.gd")
const Hands = preload("res://scripts/hand_manager.gd")

var failures = 0
var emit_count = 0


func _on_hand_emit(_cards: Array) -> void:
	emit_count += 1


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


func _init() -> void:
	# --- Evaluator: tiap target GDD ---
	var r = Evaluator.evaluate([_c(7, 1), _c(7, 2), _c(13, 1), _c(12, 3)])
	check(r["name"] == "PAIR" and r["cards"].size() == 2, "PAIR terdeteksi (7-7)")

	r = Evaluator.evaluate([_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3), _c(14, 0)])
	check(r["name"] == "TWO PAIR" and r["cards"].size() == 4, "TWO PAIR terdeteksi")

	r = Evaluator.evaluate([_c(9, 1), _c(9, 2), _c(9, 3), _c(5, 2)])
	check(r["name"] == "THREE OF A KIND", "THREE OF A KIND terdeteksi")

	r = Evaluator.evaluate([_c(5, 2), _c(6, 3), _c(7, 1), _c(8, 2), _c(9, 0)])
	check(r["name"] == "STRAIGHT" and r["cards"].size() == 5, "STRAIGHT terdeteksi")

	r = Evaluator.evaluate([_c(14, 1), _c(2, 2), _c(3, 0), _c(4, 3), _c(5, 1)])
	check(r["name"] == "STRAIGHT", "Wheel A-2-3-4-5 = STRAIGHT")

	r = Evaluator.evaluate([_c(14, 0), _c(13, 0), _c(9, 0), _c(7, 0), _c(5, 0)])
	check(r["name"] == "FLUSH" and r["cards"].size() == 5, "FLUSH terdeteksi")

	r = Evaluator.evaluate([_c(13, 1), _c(13, 2), _c(13, 3), _c(9, 1), _c(9, 0)])
	check(r["name"] == "FULL HOUSE" and r["cards"].size() == 5, "FULL HOUSE terdeteksi")

	r = Evaluator.evaluate([_c(14, 1), _c(13, 3), _c(9, 2), _c(7, 0), _c(5, 1)])
	check(r["name"] == "HIGH CARD", "HIGH CARD fallback")

	# --- Bonus ranking ---
	r = Evaluator.evaluate([_c(8, 0), _c(8, 1), _c(8, 2), _c(8, 3), _c(14, 1)])
	check(r["name"] == "FOUR OF A KIND", "FOUR OF A KIND terdeteksi")

	r = Evaluator.evaluate([_c(5, 0), _c(6, 0), _c(7, 0), _c(8, 0), _c(9, 0)])
	check(r["name"] == "STRAIGHT FLUSH", "STRAIGHT FLUSH terdeteksi")

	# --- 6 kartu: pilih yang terkuat ---
	r = Evaluator.evaluate([_c(5, 0), _c(6, 0), _c(7, 0), _c(8, 0), _c(9, 0), _c(10, 0)])
	check(r["name"] == "STRAIGHT FLUSH", "6 kartu flush-run = STRAIGHT FLUSH")

	r = Evaluator.evaluate([_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3), _c(13, 1), _c(5, 2)])
	check(r["name"] == "TWO PAIR", "6 kartu campur = TWO PAIR")

	# --- Deck ---
	var deck = DeckScript.new()
	check(deck.remaining() == 24, "Deck starter 24 kartu (dapat %d)" % deck.remaining())
	var seen = {}
	for i in range(30): # lebih dari 24: recycle jalan, tidak macet
		var c = deck.draw()
		if c == null:
			check(false, "draw tidak boleh null (recycle)")
			break
		seen[c.display()] = true
	check(seen.size() > 10, "Draw 30x bervariasi (%d unik display)" % seen.size())

	# --- HandManager ---
	var hm = Hands.new()
	root.add_child(hm)
	await process_frame
	emit_count = 0
	hm.hand_changed.connect(_on_hand_emit)
	hm.deal(3)
	check(hm.hand.size() == 3, "Deal 3 -> hand 3")
	var first = hm.hand[0]
	for i in range(5):
		hm.draw_card()
	check(hm.hand.size() == 6, "Hand cap 6 (dapat %d)" % hm.hand.size())
	check(not hm.hand.has(first), "FIFO: kartu tertua terbuang saat penuh")
	check(emit_count == 8, "hand_changed fired tiap draw (dapat %d)" % emit_count)

	# remove_cards (bekal Cash-In Step 3)
	var hm2 = Hands.new()
	root.add_child(hm2)
	await process_frame
	hm2.hand.assign([_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3)])
	var doomed = [hm2.hand[0], hm2.hand[1]]
	hm2.remove_cards(doomed)
	check(hm2.hand.size() == 2, "remove_cards buang yang dipilih saja (sisa %d)" % hm2.hand.size())

	if failures == 0:
		print("ALL STEP2 TESTS PASSED")
	else:
		printerr("%d STEP2 TEST(S) FAILED" % failures)
	quit(failures)
