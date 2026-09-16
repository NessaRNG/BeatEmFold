class_name CombatManager
extends Node
## Resolve Cash-In real-time (DECISIONS arsitektur: ... -> CombatManager -> ...).
## Bentuk AoE by rank (GDD #4B): Pair/single-lock, Two Pair/double,
## Three-Four/cone 90°, Straight/piercing line, Flush-FullHouse-SF/360°.
## Damage = Chips x Mult + suit bonus (GDD #5-6), i-frame 0.3s + magnet kecil.

signal cash_in_resolved(hand_name: String, damage: int, targets_hit: int)
signal cash_in_failed(reason: String)

const CASH_IN_IFRAME := 0.3
const MAGNET_RANGE := 300.0
const MAGNET_PULL := 40.0

# Base ala Balatro: {HandType: [chips, mult]}
const TABLE := {
	0: [5, 1], # HIGH CARD
	1: [10, 2], # PAIR
	2: [20, 2], # TWO PAIR
	3: [30, 3], # THREE
	4: [30, 4], # STRAIGHT
	5: [35, 4], # FLUSH
	6: [40, 4], # FULL HOUSE
	7: [60, 7], # FOUR
	8: [100, 8], # STRAIGHT FLUSH
}

var player: Player
var hand_manager: HandManager
var run_manager: RunManager
var jokers: JokerManager
## Tipe hand yang di-seal boss (mis. STRAIGHT). -1 = tidak ada.
var sealed_hand := -1


func try_cash_in() -> void:
	if player == null or hand_manager == null or player.dead:
		return
	var hand: Array = hand_manager.hand
	if hand.size() < 2:
		cash_in_failed.emit("BUTUH 2+ KARTU — PUKUL DULU!")
		return
	if run_manager != null and not run_manager.can_cash_in():
		cash_in_failed.emit("CASH-IN HABIS — JAB STALL!")
		return
	var used: Array = hand_manager.get_selected_cards()
	if used.size() > HandManager.MAX_SELECT:
		used = used.slice(0, HandManager.MAX_SELECT)
	if used.size() < 2:
		used = _auto_pick(hand)
	var res := PokerEvaluator.evaluate(used)
	var hand_type: int = res["type"]
	var scoring: Array = res["cards"]
	var sealed := sealed_hand >= 0 and hand_type == sealed_hand
	var hand_name: String = res["name"]
	var base: Array = TABLE[hand_type]
	var card_chips := 0
	for c in scoring:
		card_chips += c.base_chips()
	var level := 0
	if run_manager != null:
		level = run_manager.planet_level(hand_type)
	var mult: int = base[1] + int(ceil(level / 2.0))
	var chips: int = base[0] + level * 8 + card_chips
	var suit := _dominant_suit(scoring)
	var spades := 0
	for c in scoring:
		if c.suit == CardData.SPADES:
			spades += 1
	if jokers != null:
		mult += jokers.mult_bonus(player)
		chips += jokers.chips_bonus(suit)
	var damage := int(chips * mult)
	if suit == CardData.SPADES and spades >= 2:
		damage = int(damage * (1.5 if spades >= 3 else 1.25))
	if sealed:
		# Boss Blind: hand di-seal jadi High Card dari semua kartu dipakai.
		hand_name = "%s SEALED!" % res["name"]
		var used_chips := 0
		for c in used:
			used_chips += c.base_chips()
		damage = 5 + used_chips
		scoring = used

	var targets := _collect_targets(hand_type)
	_magnet(targets)
	var heavy: bool = suit == CardData.CLUBS or hand_type >= PokerEvaluator.FLUSH
	for t in targets:
		var dir := Vector2(signf(t.position.x - player.position.x), 0.0)
		if dir.x == 0.0:
			dir.x = float(player.facing)
		t.take_damage(damage, dir, heavy)
		if suit == CardData.CLUBS and not sealed:
			t.add_stagger(0.6)

	if not sealed:
		match suit:
			CardData.HEARTS:
				player.heal(maxi(1, int(damage / 8.0))) # lifesteal: jackpot heal besar
			CardData.DIAMONDS:
				player.grant_shield(1.5)
	player.invuln_timer = maxf(player.invuln_timer, CASH_IN_IFRAME)

	hand_manager.remove_cards(used)
	hand_manager.clear_selection()
	if run_manager != null:
		run_manager.use_cash_in()
	cash_in_resolved.emit(hand_name, damage, targets.size())


## Tanpa seleksi manual (tap Cash-In): pakai hand terbaik otomatis.
func _auto_pick(hand: Array) -> Array:
	var res := PokerEvaluator.evaluate(hand)
	var scoring: Array = res["cards"]
	if scoring.size() >= 2:
		return scoring.slice(0, HandManager.MAX_SELECT)
	var by_rank: Array = hand.duplicate()
	by_rank.sort_custom(func(a, b): return a.rank > b.rank)
	return by_rank.slice(0, 2)


## Suit dominan kartu scoring; seri -> suit kartu pertama.
func _dominant_suit(scoring: Array) -> int:
	var counts := {}
	for c in scoring:
		counts[c.suit] = int(counts.get(c.suit, 0)) + 1
	var best_suit: int = scoring[0].suit
	var best_n := -1
	for c in scoring:
		if counts[c.suit] > best_n:
			best_n = counts[c.suit]
			best_suit = c.suit
	return best_suit


func _alive_enemies() -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.get("dead"):
			out.append(e)
	return out


func _collect_targets(hand_type: int) -> Array:
	var enemies := _alive_enemies()
	var pp := player.position
	match hand_type:
		PokerEvaluator.TWO_PAIR:
			return _nearest_front(enemies, pp, 250.0, 2)
		PokerEvaluator.THREE, PokerEvaluator.FOUR:
			return _cone(enemies, pp, 210.0)
		PokerEvaluator.STRAIGHT:
			return _line(enemies, pp, 430.0)
		PokerEvaluator.FLUSH, PokerEvaluator.FULL_HOUSE, PokerEvaluator.STRAIGHT_FLUSH:
			return _radius(enemies, pp, 230.0)
		_: # HIGH CARD, PAIR: single lock depan
			return _nearest_front(enemies, pp, 230.0, 1)


func _is_front(e_pos: Vector2, pp: Vector2, lane_tol: float) -> bool:
	return (e_pos.x - pp.x) * player.facing > -4.0 and absf(e_pos.y - pp.y) <= lane_tol


func _nearest_front(enemies: Array, pp: Vector2, max_dist: float, count: int) -> Array:
	var cand: Array = []
	for e in enemies:
		var d: float = pp.distance_to(e.position)
		if d <= max_dist and _is_front(e.position, pp, 90.0):
			cand.append(e)
	cand.sort_custom(func(a, b): return pp.distance_to(a.position) < pp.distance_to(b.position))
	return cand.slice(0, count)


func _cone(enemies: Array, pp: Vector2, max_dist: float) -> Array:
	var out: Array = []
	for e in enemies:
		var d: float = pp.distance_to(e.position)
		if d <= max_dist and _is_front(e.position, pp, d):
			out.append(e)
	return out


func _line(enemies: Array, pp: Vector2, max_dist: float) -> Array:
	var out: Array = []
	for e in enemies:
		var dx: float = (e.position.x - pp.x) * player.facing
		if dx > -4.0 and dx <= max_dist and absf(e.position.y - pp.y) <= 44.0:
			out.append(e)
	return out


func _radius(enemies: Array, pp: Vector2, max_dist: float) -> Array:
	var out: Array = []
	for e in enemies:
		if pp.distance_to(e.position) <= max_dist:
			out.append(e)
	return out


func _magnet(targets: Array) -> void:
	var pp := player.position
	for t in targets:
		var to: Vector2 = pp - t.position
		if to.length() <= MAGNET_RANGE and to.length() > 80.0:
			t.position += to.normalized() * MAGNET_PULL
