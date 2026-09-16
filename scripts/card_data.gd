class_name CardData
extends Resource
## Satu kartu remi. rank 2..14 (11=J, 12=Q, 13=K, 14=A).
## suit: 0=Hearts, 1=Spades, 2=Clubs, 3=Diamonds.

@export var rank: int = 7
@export var suit: int = 1

## Konstanta suit (int, bukan enum — akses antar-script aman).
const HEARTS := 0
const SPADES := 1
const CLUBS := 2
const DIAMONDS := 3


static func rank_label(r: int) -> String:
	match r:
		11:
			return "J"
		12:
			return "Q"
		13:
			return "K"
		14:
			return "A"
		_:
			return str(r)


static func suit_symbol(s: int) -> String:
	match s:
		0:
			return "♥"
		1:
			return "♠"
		2:
			return "♣"
		_:
			return "♦"


static func suit_name(s: int) -> String:
	match s:
		0:
			return "Hearts"
		1:
			return "Spades"
		2:
			return "Clubs"
		_:
			return "Diamonds"


static func is_red(s: int) -> bool:
	return s == 0 or s == 3


## Teks 2 baris untuk slot UI ("Q\n♥").
func display() -> String:
	return "%s\n%s" % [rank_label(rank), suit_symbol(suit)]


## Satu baris untuk strip bawah kartu ("Q♥").
func short() -> String:
	return "%s%s" % [rank_label(rank), suit_symbol(suit)]


## Path face Kenney Playing Cards Pack (CC0).
func face_path() -> String:
	var r := "A"
	match rank:
		11:
			r = "J"
		12:
			r = "Q"
		13:
			r = "K"
		14:
			r = "A"
		_:
			r = "%02d" % rank
	return "res://assets/cards/card_%s_%s.png" % [suit_name(suit).to_lower(), r]


## Nilai chips dasar ala Balatro (dipakai Step 3 scoring).
func base_chips() -> int:
	match rank:
		11, 12, 13:
			return 10
		14:
			return 11
		_:
			return rank
