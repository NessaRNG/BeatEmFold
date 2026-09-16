class_name HandManager
extends Node
## Tangan 6 slot. Tiap jab yang KENA musuh = draw 1 (dipicu sinyal
## Player.hit_landed dari main.gd). Penuh? kartu tertua auto-buang (FIFO)
## supaya tempo agresif tetap jalan — sesuai GDD "Pukul = draw".

signal hand_changed(cards: Array[CardData])
signal best_hand_changed(hand_name: String, hand_type: int)
signal selection_changed(selected: Array)

const MAX_HAND := 6
const MAX_SELECT := 5

var deck: Deck
var hand: Array[CardData] = []
## Kartu terpilih (referensi identitas, bukan indeks — tahan terhadap FIFO).
var selected_cards: Array = []


func draw_card() -> CardData:
	_ensure_deck()
	var c := deck.draw()
	if c == null:
		return null
	if hand.size() >= MAX_HAND:
		var evicted: CardData = hand.pop_front()
		selected_cards.erase(evicted)
		deck.discard(evicted)
	hand.append(c)
	_emit()
	return c


func deal(n: int) -> void:
	for i in range(n):
		draw_card()


## Buang kartu pilihan (dipakai Cash-In Step 3). Sisa kartu stay.
func remove_cards(to_remove: Array) -> void:
	_ensure_deck()
	for c in to_remove:
		if hand.has(c):
			hand.erase(c)
			deck.discard(c)
			selected_cards.erase(c)
	_emit()


## Toggle kartu slot-i saat tahan select_mode. Cap 5 (aturan Cash-In 2-5).
func toggle_select(i: int) -> void:
	if i < 0 or i >= hand.size():
		return
	var c: CardData = hand[i]
	if selected_cards.has(c):
		selected_cards.erase(c)
	else:
		if selected_cards.size() >= MAX_SELECT:
			selected_cards.pop_front()
		selected_cards.append(c)
	selection_changed.emit(selected_cards.duplicate())


func clear_selection() -> void:
	if selected_cards.is_empty():
		return
	selected_cards.clear()
	selection_changed.emit(selected_cards.duplicate())


func get_selected_cards() -> Array:
	var out: Array = []
	for c in selected_cards:
		if hand.has(c):
			out.append(c)
	return out


func _ensure_deck() -> void:
	if deck == null:
		deck = Deck.new()


func _emit() -> void:
	hand_changed.emit(hand.duplicate())
	var res := PokerEvaluator.evaluate(hand)
	best_hand_changed.emit(res["name"], res["type"])
