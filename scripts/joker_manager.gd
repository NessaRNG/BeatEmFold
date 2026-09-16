class_name JokerManager
extends Node
## Koleksi Joker + hook pasif (on_cash_in mult/chips, on_discard).

signal changed

var owned: Array = [] # Array[JokerData]


func has(id: String) -> bool:
	for j in owned:
		if j.id == id:
			return true
	return false


func add(j) -> void:
	if not has(j.id):
		owned.append(j)
		changed.emit()


func mult_bonus(player: Player) -> int:
	var bonus := 0
	if has("bloodlust") and player.hp * 2 < player.max_hp:
		bonus += 2
	return bonus


func chips_bonus(suit: int) -> int:
	if has("spade_drill") and suit == CardData.SPADES:
		return 30
	return 0


func on_discard(player: Player) -> void:
	if has("parry"):
		player.grant_shield(1.0)


func names() -> Array:
	var out: Array = []
	for j in owned:
		out.append(j.jname)
	return out
