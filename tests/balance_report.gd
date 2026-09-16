extends SceneTree
## Laporan balancing: ukur damage asli via CombatManager + proyeksi TTK/ekonomi.
## godot --headless --path . -s tests/balance_report.gd

const Cards = preload("res://scripts/card_data.gd")
const Hands = preload("res://scripts/hand_manager.gd")
const PlayerS = preload("res://scripts/player.gd")
const DummyS = preload("res://scripts/dummy.gd")
const CombatS = preload("res://scripts/combat_manager.gd")
const RunS = preload("res://scripts/run_manager.gd")
const JokerS = preload("res://scripts/joker_manager.gd")
const WaveS = preload("res://scripts/wave_manager.gd")

var got_dmg := 0
var got_name := ""


func _c(rank: int, suit: int):
	var c = Cards.new()
	c.rank = rank
	c.suit = suit
	return c


func _on_res(n: String, d: int, _k: int) -> void:
	got_name = n
	got_dmg = d


func _init() -> void:
	var player = PlayerS.new()
	player.position = Vector2(400, 520)
	root.add_child(player)
	var dummy = DummyS.new()
	dummy.max_hp = 9999
	dummy.hp = 9999
	dummy.respawns = false
	dummy.position = Vector2(470, 520)
	root.add_child(dummy)
	var hm = Hands.new()
	root.add_child(hm)
	var run = RunS.new()
	root.add_child(run)
	var jok = JokerS.new()
	root.add_child(jok)
	var cm = CombatS.new()
	cm.player = player
	cm.hand_manager = hm
	cm.run_manager = run
	cm.jokers = jok
	root.add_child(cm)
	cm.cash_in_resolved.connect(_on_res)
	await process_frame
	await process_frame
	player.facing = 1

	print("=== CASH-IN DAMAGE (planet 0, no joker) ===")
	_cash(hm, run, cm, [_c(5, 2), _c(5, 3)], "pair 5 clubs")
	_cash(hm, run, cm, [_c(7, 1), _c(7, 2)], "pair 7 spades")
	_cash(hm, run, cm, [_c(13, 1), _c(13, 3)], "pair K spades")
	_cash(hm, run, cm, [_c(14, 0), _c(14, 1)], "pair A hearts")
	_cash(hm, run, cm, [_c(7, 1), _c(7, 2), _c(9, 1), _c(9, 3)], "two pair")
	_cash(hm, run, cm, [_c(9, 1), _c(9, 2), _c(9, 3)], "three 9")
	_cash(hm, run, cm, [_c(5, 2), _c(6, 3), _c(7, 1), _c(8, 2), _c(9, 0)], "straight")
	_cash(hm, run, cm, [_c(14, 0), _c(13, 0), _c(9, 0), _c(7, 0), _c(5, 0)], "flush hearts")
	_cash(hm, run, cm, [_c(13, 1), _c(13, 2), _c(13, 3), _c(9, 1), _c(9, 0)], "full house")
	print("=== PLANET PAIR LV2 ===")
	run.upgrade_planet(1)
	run.upgrade_planet(1)
	_cash(hm, run, cm, [_c(7, 1), _c(7, 2)], "pair 7 planet2")
	print("=== PROYEKSI ===")
	print("jab DPS: 19 dmg / ~1.0s = ~19 (striker 30HP = ~2 kombo)")
	print("wave0 HP total: 80 | wave1: 170 | boss: 150")
	print("striker DPS ke player diam: 8 dmg / ~1.0s siklus (token 1)")
	print("brute burst 12, fury 6x2, slammer slam 10/2.5s, boss slam 15/3s")
	print("heal hearts pair = mult (2-4) vs incoming elite ~20-40/wave")
	print("ekonomi loop0: wave0 $13 + elite $22 + boss $20 = $55")
	quit(0)


func _cash(hm, run, cm, cards: Array, label: String) -> void:
	run.reset_for_wave(0)
	hm.hand.assign(cards.duplicate())
	hm.selected_cards.assign(hm.hand.duplicate())
	cm.try_cash_in()
	print("%s -> %s = %d" % [label, got_name, got_dmg])
