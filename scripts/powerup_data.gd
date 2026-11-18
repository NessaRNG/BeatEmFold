class_name PowerUpData
extends RefCounted
## Definisi power-up stackable. Afinitas = jembatan kartu -> efek fisik.
## Tidak menyentuh TABLE damage poker / Chips x Mult / aturan poker.

const DEFS := {
	"fist_heavy": {"name": "Heavy Gloves", "cat": "FIST", "cat_label": "STRIKE", "desc": "Punches hit harder"},
	"fist_launch": {"name": "Finisher Launcher", "cat": "FIST", "cat_label": "STRIKE", "desc": "Final punch sends enemies flying"},
	"fist_reach": {"name": "Long Reach", "cat": "FIST", "cat_label": "STRIKE", "desc": "Your fists reach farther"},
	"move_reflex": {"name": "Reflex", "cat": "MOVEMENT", "cat_label": "AGILITY", "desc": "More time to dodge after a hit"},
	"move_footwork": {"name": "Footwork", "cat": "MOVEMENT", "cat_label": "AGILITY", "desc": "Dash again sooner"},
	"move_breath": {"name": "Deep Breath", "cat": "MOVEMENT", "cat_label": "AGILITY", "desc": "One extra cash-in each wave"},
	"aff_heart": {"name": "Heart Affinity", "cat": "AFFINITY", "cat_label": "SUIT POWER", "desc": "♥ cards heal you"},
	"aff_spade": {"name": "Spade Affinity", "cat": "AFFINITY", "cat_label": "SUIT POWER", "desc": "♠ cards hit harder"},
	"aff_club": {"name": "Club Affinity", "cat": "AFFINITY", "cat_label": "SUIT POWER", "desc": "♣ cards freeze enemies"},
	"aff_diamond": {"name": "Diamond Affinity", "cat": "AFFINITY", "cat_label": "SUIT POWER", "desc": "♦ cards protect you"},
	"finisher": {"name": "Finisher Ammo", "cat": "FINISHER", "cat_label": "FINISHER", "desc": "Face cards break enemy guard"},
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
