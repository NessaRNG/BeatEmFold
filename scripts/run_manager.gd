class_name RunManager
extends Node
## State run simpel: uang, jatah Cash-In + Discard per wave.
## Reset tiap wave baru.

signal changed

const HANDS_PER_WAVE := 4
const DISCARDS_PER_WAVE := 3
const KILL_MONEY := 4
const BOSS_MONEY := 20

var money := 0
var hands_left := HANDS_PER_WAVE
var discards_left := DISCARDS_PER_WAVE
var wave_index := 0
## Skor endless + terbaik (tersimpan user://).
var score := 0
var best := 0

## Power-up stackable: id -> jumlah stack. Bertahan lintas wave/loop.
var powerups: Dictionary = {}
var _powerup_rng := RandomNumberGenerator.new()

const SAVE_PATH := "user://beatemfold_save.cfg"


func add_powerup(id: String) -> void:
	powerups[id] = int(powerups.get(id, 0)) + 1
	changed.emit()


func powerup_count(id: String) -> int:
	return int(powerups.get(id, 0))


func hands_per_wave() -> int:
	return HANDS_PER_WAVE + powerup_count("move_breath")


func roll_powerup_choices() -> Array:
	return PowerUpData.roll(powerups, _powerup_rng)


func load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best = int(cfg.get_value("run", "best", 0))


func reset_for_wave(idx: int) -> void:
	wave_index = idx
	hands_left = hands_per_wave()
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
