class_name RunManager
extends Node
## State run ala Balatro: uang, jatah Cash-In (Hands) + Discard per wave,
## level Planet per tipe hand. Reset tiap wave baru.

signal changed

const HANDS_PER_WAVE := 4
const DISCARDS_PER_WAVE := 3
const KILL_MONEY := 4
const BOSS_MONEY := 20

var money := 0
var hands_left := HANDS_PER_WAVE
var discards_left := DISCARDS_PER_WAVE
var hand_levels := {} # hand_type(int) -> level(int)
var wave_index := 0
## Skor endless + terbaik (tersimpan user://).
var score := 0
var best := 0

const SAVE_PATH := "user://beatemfold_save.cfg"


func load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("run", "best", 0))


func reset_for_wave(idx: int) -> void:
	wave_index = idx
	hands_left = HANDS_PER_WAVE
	discards_left = DISCARDS_PER_WAVE
	changed.emit()


func can_cash_in() -> bool:
	return hands_left > 0


func use_cash_in() -> void:
	hands_left = maxi(hands_left - 1, 0)
	changed.emit()


func can_discard() -> bool:
	return discards_left > 0


func use_discard() -> void:
	discards_left = maxi(discards_left - 1, 0)
	changed.emit()


func add_money(n: int) -> void:
	money = maxi(money + n, 0)
	changed.emit()


func spend(n: int) -> bool:
	if money < n:
		return false
	money -= n
	changed.emit()
	return true


func planet_level(hand_type: int) -> int:
	return int(hand_levels.get(hand_type, 0))


func upgrade_planet(hand_type: int) -> void:
	hand_levels[hand_type] = planet_level(hand_type) + 1
	changed.emit()


func add_score(n: int) -> void:
	score += n
	if score > best:
		best = score
	changed.emit()


func save_best() -> void:
	if score > best:
		best = score
	var cfg := ConfigFile.new()
	cfg.set_value("run", "best", best)
	cfg.save(SAVE_PATH)
