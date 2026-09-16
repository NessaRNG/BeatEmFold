class_name PokerEvaluator
extends RefCounted
## Fungsi murni: nilai kartu di tangan (2-6 kartu) -> hand poker terbaik.
## Target GDD: PAIR, TWO PAIR, THREE, STRAIGHT, FLUSH, FULL HOUSE.
## Bonus gratis: HIGH CARD, FOUR OF A KIND, STRAIGHT FLUSH (dipakai Step 3).
##
## Return: {"type": HandType, "name": String, "cards": Array[CardData]}
## "cards" = kartu pembentuk kombo (dipakai highlight + scoring Step 3).

## Tipe hand sebagai int const (bukan enum — akses antar-script aman).
const HIGH_CARD := 0
const PAIR := 1
const TWO_PAIR := 2
const THREE := 3
const STRAIGHT := 4
const FLUSH := 5
const FULL_HOUSE := 6
const FOUR := 7
const STRAIGHT_FLUSH := 8


static func evaluate(cards: Array) -> Dictionary:
	if cards.size() < 2:
		return _res(HIGH_CARD, "HIGH CARD", cards.duplicate())
	var by_rank := {}
	var by_suit := {}
	for c in cards:
		if not by_rank.has(c.rank):
			by_rank[c.rank] = []
		by_rank[c.rank].append(c)
		if not by_suit.has(c.suit):
			by_suit[c.suit] = []
		by_suit[c.suit].append(c)

	var flush_suit := -1
	for s in by_suit:
		if by_suit[s].size() >= 5:
			flush_suit = s

	var unique_ranks: Array = by_rank.keys()
	unique_ranks.sort()
	var straight_high := _straight_high(unique_ranks)

	if flush_suit != -1:
		var sf_high := _straight_high(_unique_sorted(by_suit[flush_suit]))
		if sf_high > 0:
			return _res(STRAIGHT_FLUSH, "STRAIGHT FLUSH",
				_pick_straight(by_suit[flush_suit], sf_high))

	var fours: Array = []
	var threes: Array = []
	var pairs: Array = []
	for r in by_rank:
		var n: int = by_rank[r].size()
		if n >= 4:
			fours.append(r)
		elif n == 3:
			threes.append(r)
		elif n == 2:
			pairs.append(r)
	fours.sort()
	fours.reverse()
	threes.sort()
	threes.reverse()
	pairs.sort()
	pairs.reverse()

	if not fours.is_empty():
		return _res(FOUR, "FOUR OF A KIND", by_rank[fours[0]].duplicate())

	if not threes.is_empty() and (not pairs.is_empty() or threes.size() > 1):
		var out: Array = by_rank[threes[0]].duplicate()
		if threes.size() > 1:
			var second: Array = by_rank[threes[1]].duplicate()
			out.append(second[0])
			out.append(second[1])
		else:
			out.append_array(by_rank[pairs[0]])
		return _res(FULL_HOUSE, "FULL HOUSE", out)

	if flush_suit != -1:
		return _res(FLUSH, "FLUSH", by_suit[flush_suit].duplicate())

	if straight_high > 0:
		return _res(STRAIGHT, "STRAIGHT", _pick_straight(cards, straight_high))

	if not threes.is_empty():
		return _res(THREE, "THREE OF A KIND", by_rank[threes[0]].duplicate())

	if pairs.size() >= 2:
		var two: Array = []
		two.append_array(by_rank[pairs[0]])
		two.append_array(by_rank[pairs[1]])
		return _res(TWO_PAIR, "TWO PAIR", two)

	if pairs.size() == 1:
		return _res(PAIR, "PAIR", by_rank[pairs[0]].duplicate())

	var high_rank: int = unique_ranks.back()
	return _res(HIGH_CARD, "HIGH CARD", [by_rank[high_rank][0]])


## Rank tertinggi dari straight yang ada, 0 = tidak ada.
## sorted_unique: rank unik terurut naik. As dual: 14 tinggi + 1 rendah (wheel).
static func _straight_high(sorted_unique: Array) -> int:
	var ranks: Array = sorted_unique.duplicate()
	if ranks.has(14):
		ranks.push_front(1)
	var best := 0
	var run := 1
	for i in range(1, ranks.size()):
		if ranks[i] == ranks[i - 1] + 1:
			run += 1
			if run >= 5:
				best = ranks[i]
		elif ranks[i] == ranks[i - 1]:
			pass
		else:
			run = 1
	return best


static func _unique_sorted(pool: Array) -> Array:
	var seen := {}
	for c in pool:
		seen[c.rank] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## Ambil 1 kartu per rank pembentuk straight (high-4 .. high).
static func _pick_straight(pool: Array, high: int) -> Array:
	var need := {}
	for k in range(5):
		var r: int = high - k
		if r <= 1:
			r = 14 # As rendah (wheel) tersimpan sebagai rank 14
		need[r] = true
	var out: Array = []
	for c in pool:
		if need.has(c.rank):
			out.append(c)
			need.erase(c.rank)
	return out


static func _res(t: int, n: String, scoring: Array) -> Dictionary:
	return {"type": t, "name": n, "cards": scoring}
