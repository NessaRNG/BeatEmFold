class_name Deck
extends RefCounted
## Deck run 24 kartu (custom build, bukan 52 random — sesuai DECISIONS #9).
## Komposisi starter: ada run Hearts (potensi Straight/Flush), 3 pasang,
## dan filler berurutan supaya tiap hand MVP terasa hidup.

var cards: Array[CardData] = []
var discards: Array[CardData] = []


func _init() -> void:
	build_starter()
	shuffle()


func build_starter() -> void:
	cards.clear()
	# [rank, suit] — suit: 0=H 1=S 2=C 3=D
	var defs: Array = [
		[14, 0], [13, 0], [12, 0], [11, 0], [10, 0], # run Hearts
		[7, 1], [7, 2], # pair 7
		[9, 1], [9, 3], # pair 9
		[13, 1], [13, 2], # pair K
		[5, 2], [6, 2], [8, 2], # clubs berurutan
		[8, 0], [10, 1], [11, 2], [12, 1],
		[6, 0], [5, 3], [9, 0], [4, 3], [2, 3], [14, 1],
	]
	for d in defs:
		var c := CardData.new()
		c.rank = d[0]
		c.suit = d[1]
		cards.append(c)


func shuffle() -> void:
	cards.shuffle()


func remaining() -> int:
	return cards.size()


func draw() -> CardData:
	if cards.is_empty():
		_recycle()
	if cards.is_empty():
		return null
	return cards.pop_back()


func discard(c: CardData) -> void:
	discards.append(c)


func _recycle() -> void:
	# Kartu buangan balik jadi deck. Kalau kosong juga (awal run),
	# bangun starter baru — sandbox MVP tidak pernah macet.
	if discards.is_empty():
		build_starter()
	else:
		cards = discards
		discards = []
	shuffle()
