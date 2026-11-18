class_name PowerUpData
extends RefCounted
## Definisi power-up stackable. Afinitas = jembatan kartu -> efek fisik.
## Tidak menyentuh TABLE damage poker / Chips x Mult / aturan poker.

const DEFS := {
	"fist_heavy": {"name": "Sarung Berat", "cat": "TINJU", "desc": "Jab +2 damage"},
	"fist_launch": {"name": "Finisher Launcher", "cat": "TINJU", "desc": "Jab ke-3 melayang (heavy)"},
	"fist_reach": {"name": "Jangkauan Panjang", "cat": "TINJU", "desc": "Hitbox jab +30px"},
	"move_reflex": {"name": "Refleks", "cat": "GERAK", "desc": "Dash i-frame +0.15s"},
	"move_footwork": {"name": "Footwork", "cat": "GERAK", "desc": "Dash cooldown -0.2s"},
	"move_breath": {"name": "Napas Panjang", "cat": "GERAK", "desc": "Cash-in +1 / wave"},
	"aff_heart": {"name": "Afinitas Heart", "cat": "AFINITAS", "desc": "+3 heal / kartu ♥"},
	"aff_spade": {"name": "Afinitas Spade", "cat": "AFINITAS", "desc": "+2 damage / kartu ♠"},
	"aff_club": {"name": "Afinitas Club", "cat": "AFINITAS", "desc": "+0.15s stun / kartu ♣"},
	"aff_diamond": {"name": "Afinitas Diamond", "cat": "AFINITAS", "desc": "+0.25s shield / kartu ♦"},
	"finisher": {"name": "Amunisi Finisher", "cat": "FINISHER", "desc": "J/Q/K/A = guard-break 0.5s"},
}

const IDS: Array = [
	"fist_heavy", "fist_launch", "fist_reach",
	"move_reflex", "move_footwork", "move_breath",
	"aff_heart", "aff_spade", "aff_club", "aff_diamond",
	"finisher",
]


static func get_def(id: String) -> Dictionary:
	return DEFS.get(id, {"name": id, "cat": "", "desc": ""})


static func is_affinity(id: String) -> bool:
	return id.begins_with("aff_")


## Pilih 3 unik. Utamakan yang belum dimiliki, sisanya boleh stack.
static func roll(owned: Dictionary, rng: RandomNumberGenerator) -> Array:
	var fresh: Array = []
	var repeat: Array = []
	for id in IDS:
		if int(owned.get(id, 0)) <= 0:
			fresh.append(id)
		else:
			repeat.append(id)
	# Fisher-Yates kecil
	for arr in [fresh, repeat]:
		for i in range(arr.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = arr[i]
			arr[i] = arr[j]
			arr[j] = tmp
	var out: Array = []
	for id in fresh:
		if out.size() >= 3:
			break
		out.append(id)
	for id in repeat:
		if out.size() >= 3:
			break
		out.append(id)
	return out
