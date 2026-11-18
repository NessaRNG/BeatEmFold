extends SceneTree
## Smoke test per-hand attack animation director. Headless.

const CombatS = preload("res://scripts/combat_manager.gd")
const HandS = preload("res://scripts/hand_manager.gd")
const DeckS = preload("res://scripts/deck.gd")
const CardS = preload("res://scripts/card_data.gd")
const PlayerS = preload("res://scripts/player.gd")
const RunS = preload("res://scripts/run_manager.gd")

var failures = 0
func check(c: bool, l: String) -> void:
	if c: print("PASS: %s" % l)
	else: failures += 1; printerr("FAIL: %s" % l)

func _card(r, s):
	var c := CardS.new(); c.rank = r; c.suit = s; return c

func _init() -> void:
	var player := PlayerS.new(); root.add_child(player)
	var hm := HandS.new(); hm.deck = DeckS.new(); root.add_child(hm)
	var run := RunS.new(); root.add_child(run)
	var cm := CombatS.new(); cm.player = player; cm.hand_manager = hm; cm.run_manager = run; root.add_child(cm)
	for i in range(20): await process_frame

	var hands := {
		0: [_card(7,0), _card(9,1)],
		1: [_card(7,0), _card(7,1)],
		2: [_card(7,0), _card(7,1), _card(9,2), _card(9,3)],
		3: [_card(7,0), _card(7,1), _card(7,2)],
		4: [_card(5,0), _card(6,1), _card(7,2), _card(8,3), _card(9,0)],
		5: [_card(2,0), _card(5,0), _card(9,0), _card(11,0), _card(13,0)],
		6: [_card(7,0), _card(7,1), _card(7,2), _card(9,0), _card(9,1)],
		7: [_card(7,0), _card(7,1), _card(7,2), _card(7,3)],
		8: [_card(9,0), _card(10,0), _card(11,0), _card(12,0), _card(13,0)],
	}
	for t in range(9):
		run.hands_left = 4
		var typed: Array[CardData] = []
		for c in hands[t]:
			typed.append(c)
		hm.hand = typed
		cm.try_cash_in()
		check(cm.last_hand_type == t, "Tangan %d -> type benar (dapat %d)" % [t, cm.last_hand_type])

	Engine.time_scale = 1.0
	if failures == 0: print("ALL STEP15 TESTS PASSED")
	else: printerr("%d STEP15 TEST(S) FAILED" % failures)
	quit(failures)
