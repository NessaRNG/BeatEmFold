class_name CombatManager
extends Node
## Resolve Cash-In real-time.
## Bentuk AoE by rank: Pair/single-lock, Two Pair/double,
## Three-Four/cone 90°, Straight/piercing line, Flush-FullHouse-SF/360°.
## Damage flat per rank + suit simpel, i-frame 0.3s + magnet kecil.

signal cash_in_resolved(hand_name: String, damage: int, targets_hit: int)
signal cash_in_failed(reason: String)

const CASH_IN_IFRAME := 0.3
const MAGNET_RANGE := 300.0
const MAGNET_PULL := 40.0

# Damage flat per rank poker (tanpa Chips x Mult, tanpa Planet/Joker).
const TABLE := {
	0: 10, # HIGH CARD
	1: 25, # PAIR
	2: 40, # TWO PAIR
	3: 60, # THREE
	4: 80, # STRAIGHT
	5: 90, # FLUSH
	6: 120, # FULL HOUSE
	7: 150, # FOUR
	8: 200, # STRAIGHT FLUSH
}

const SEALED_DAMAGE := 15
const HEARTS_HEAL := 8
const SPADES_MULT := 1.5

var player: Player
var hand_manager: HandManager
var run_manager: RunManager
## Tipe hand yang di-seal boss (mis. STRAIGHT). -1 = tidak ada.
var sealed_hand := -1
## Tipe hand terakhir yang di-cash (dibaca main.gd untuk animasi, tanpa ubah signature signal).
var last_hand_type := 0


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
	var damage: int = TABLE[hand_type]
	var suit := _dominant_suit(scoring)
	if not sealed and suit == CardData.SPADES:
		damage = int(damage * SPADES_MULT)
	if sealed:
		# Boss seal: hand di-seal jadi damage flat kecil, tanpa suit bonus.
		hand_name = "%s SEALED!" % res["name"]
		damage = SEALED_DAMAGE
		scoring = used

	var targets := _collect_targets(hand_type)
	_magnet(targets)

	# --- Power-up: Afinitas + Finisher (jembatan kartu -> efek fisik) ---
	# Damage bonus dihitung SEBELUM take_damage; stagger/guard-break SESUDAH,
	# karena take_damage() menimpa stagger_timer (jadi efek harus dipakai belakangan).
	var n_spade := 0
	var n_heart := 0
	var n_club := 0
	var n_diamond := 0
	var club_stun := 0.0
	var has_finisher := false
	var finisher_card := false
	if run_manager != null and not sealed:
		n_spade = _count_suit(used, CardData.SPADES)
		n_heart = _count_suit(used, CardData.HEARTS)
		n_club = _count_suit(used, CardData.CLUBS)
		n_diamond = _count_suit(used, CardData.DIAMONDS)
		damage += n_spade * 2 * run_manager.powerup_count("aff_spade")
		club_stun = n_club * 0.15 * run_manager.powerup_count("aff_club")
		has_finisher = run_manager.powerup_count("finisher") > 0
		finisher_card = _has_high_card(used)

	var heavy: bool = suit == CardData.CLUBS or hand_type >= PokerEvaluator.FLUSH
	for t in targets:
		var dir := Vector2(signf(t.position.x - player.position.x), 0.0)
		if dir.x == 0.0:
			dir.x = float(player.facing)
		t.take_damage(damage, dir, heavy)
		if suit == CardData.CLUBS and not sealed:
			t.add_stagger(0.6)
		# Efek power-up setelah take_damage supaya tidak timpa.
		if club_stun > 0.0:
			t.add_stagger(club_stun)
		if has_finisher and finisher_card:
			t.break_guard(0.5)

	if run_manager != null and not sealed:
		player.heal(n_heart * 3 * run_manager.powerup_count("aff_heart"))
		if n_diamond > 0 and run_manager.powerup_count("aff_diamond") > 0:
			player.grant_shield(n_diamond * 0.25 * run_manager.powerup_count("aff_diamond"))

	if not sealed:
		match suit:
			CardData.HEARTS:
				player.heal(HEARTS_HEAL)
			CardData.DIAMONDS:
				player.grant_shield(1.5)
	player.invuln_timer = maxf(player.invuln_timer, CASH_IN_IFRAME)

	hand_manager.remove_cards(used)
	hand_manager.clear_selection()
	if run_manager != null:
		run_manager.use_cash_in()
	last_hand_type = hand_type
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


## Jumlah kartu bersuit tertentu dalam array kartu.
func _count_suit(cards: Array, suit: int) -> int:
	var n := 0
	for c in cards:
		if c.suit == suit:
			n += 1
	return n


## Ada kartu J/Q/K/A (rank >= 11) di antara kartu yang dipakai.
func _has_high_card(cards: Array) -> bool:
	for c in cards:
		if c.rank >= 11:
			return true
	return false


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
