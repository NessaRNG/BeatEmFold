class_name JokerData
extends Resource
## Joker pasif (GDD #6, target 12-15; MVP: 3 dulu).

@export var id: String = ""
@export var jname: String = ""
@export var desc: String = ""
@export var price: int = 5


static func starter_pool() -> Array:
	var out: Array = []
	var defs := [
		["bloodlust", "Bloodlust", "+2 Mult saat HP < 50%", 6],
		["spade_drill", "Spade Drill", "Spades dominan +30 Chips", 6],
		["parry", "Parry Manual", "Tiap buang kartu shield 1 dtk", 5],
	]
	for d in defs:
		var j := JokerData.new()
		j.id = d[0]
		j.jname = d[1]
		j.desc = d[2]
		j.price = d[3]
		out.append(j)
	return out
