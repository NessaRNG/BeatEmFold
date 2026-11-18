class_name WaveManager
extends Node
## Endless: pola fight/elite/boss berulang, scaling per loop.
## loop = idx/3, kind = idx%3. HP +40%/loop, dmg +1/loop, penyerang 1->3.

signal wave_cleared(index: int)

const SEALS := [4, 5, 1] # STRAIGHT, FLUSH, PAIR (rotasi boss)

var spawned: Array = []
var active_index := -1
var cleared_fired := false
var boss_ref: Dummy


static func kind_of(idx: int) -> int:
	return idx % 3


static func loop_of(idx: int) -> int:
	return int(idx / 3.0)


## Tier stage per 5 boss (15 wave): 0 ALLEY, 1 ROOFTOP, 2 CLUB. Sinkron stage_bg.
static func tier_of(idx: int) -> int:
	return int(loop_of(idx) / 5.0) % 3


static func tier_name(t: int) -> String:
	match t:
		1:
			return "ROOFTOP"
		2:
			return "CLUB"
		_:
			return "ALLEY"


func wave_title(idx: int) -> String:
	return "WAVE %d" % (idx + 1)


func wave_banner(idx: int) -> String:
	var loop := loop_of(idx)
	var buff := " (+%d%% HP)" % int(loop * 40) if loop > 0 else ""
	var tier := tier_name(tier_of(idx))
	match kind_of(idx):
		0:
			return "WAVE %d [%s] — %s!%s" % [idx + 1, tier, _fight_names(tier_of(idx)), buff]
		1:
			return "ELITE [%s]: %s!%s" % [tier, _elite_names(tier_of(idx)), buff]
		_:
			return "%s BOSS: %s SEALED! WATCH THE SLAM!" % [tier, seal_name(wave_sealed(idx))]


func _fight_names(t: int) -> String:
	match t:
		1:
			return "PUNK + RUNNER"
		2:
			return "RAZOR + VOLT"
		_:
			return "STRIKER + DASHER"


func _elite_names(t: int) -> String:
	match t:
		1:
			return "ENFORCER + BERSERKER + WRECKER"
		2:
			return "TITAN + RAVAGER + DEMOLISHER"
		_:
			return "BRUTE + FURY + SLAMMER"


func _boss_name(t: int) -> String:
	match t:
		1:
			return "KINGPIN"
		2:
			return "DON"
		_:
			return "BOSS"


func seal_name(t: int) -> String:
	match t:
		4:
			return "STRAIGHT"
		5:
			return "FLUSH"
		_:
			return "PAIR"


func wave_sealed(idx: int) -> int:
	if kind_of(idx) == 2:
		return SEALS[loop_of(idx) % SEALS.size()]
	return -1


func start_wave(idx: int, parent: Node) -> void:
	_clear_old()
	active_index = idx
	cleared_fired = false
	boss_ref = null
	var loop := loop_of(idx)
	Dummy.max_attackers = mini(1 + loop, 3)
	Dummy.reset_tokens()
	# Skala agresi per loop: windup cepat, recover singkat, jalan cepat,
	# jaga jarak rapat, slam sering. Loop 0 = base, tidak berubah.
	var windup_mul := maxf(0.65, 1.0 - 0.12 * loop)
	var speed_bonus := 15.0 * loop
	var hold_dist := maxf(140.0, 220.0 - 25.0 * loop)
	var slam_mul := maxf(0.7, 1.0 - 0.1 * loop)
	var dummy_script := load("res://scripts/dummy.gd") as GDScript
	for e in _entries(idx, loop):
		var d = dummy_script.new()
		d.respawns = false
		d.max_hp = e["hp"]
		d.hp = e["hp"]
		d.position = e["pos"]
		d.ai_enabled = bool(e.get("ai", false))
		d.display_name = str(e.get("name", "DUMMY"))
		d.look = str(e.get("look", "striker"))
		d.sprite_scale = float(e.get("spr", 1.0))
		d.body_w = float(e.get("w", 36.0))
		d.body_h = float(e.get("h", 56.0))
		if e.has("color"):
			d.body_color = e["color"]
		d.ai_damage = int(e.get("dmg", 8))
		d.ai_speed = float(e.get("speed", 120.0)) + speed_bonus
		d.ai_windup = maxf(0.28, float(e.get("windup", 0.6)) * windup_mul)
		d.ai_recover = maxf(0.22, float(e.get("recover", 0.4)) - 0.06 * loop)
		d.ai_hold_dist = hold_dist
		d.strike_hits = int(e.get("hits", 1))
		d.strike_gap = maxf(0.18, float(e.get("gap", 0.25)) - 0.02 * loop)
		d.strike_lunge = float(e.get("lunge", 0.0))
		d.money_value = int(e.get("money", 4))
		if e.has("slam"):
			d.slam_damage = int(e["slam"])
			d.slam_range = float(e.get("slam_range", 130.0))
			d.slam_interval = float(e.get("slam_interval", 3.0)) * slam_mul
		if bool(e.get("boss", false)):
			d.is_boss = true
			boss_ref = d
		parent.add_child(d)
		spawned.append(d)


func _hp(base: int, loop: int, boss: bool = false) -> int:
	if boss:
		return roundi(base * (1.0 + 0.5 * loop))
	return roundi(base * (1.0 + 0.4 * loop))


func _entries(idx: int, loop: int) -> Array:
	var tier := tier_of(idx)
	match kind_of(idx):
		0:
			var list := [
				{"hp": _hp(30, loop), "pos": Vector2(700, 500), "ai": true,
					"look": "striker", "dmg": 8 + loop, "money": 4 + loop},
				{"hp": _hp(30, loop), "pos": Vector2(860, 545), "ai": true,
					"look": "striker", "dmg": 8 + loop, "money": 4 + loop},
				{"hp": _hp(20, loop), "pos": Vector2(1010, 505), "ai": true,
					"look": "dasher", "name": "DASHER", "w": 30.0, "h": 46.0,
					"color": Color("ffd28f"), "dmg": 6 + loop, "speed": 200.0,
					"windup": 0.4, "recover": 0.3, "money": 5 + loop, "lunge": 50.0},
			]
			var extra := ["striker", "dasher"]
			for i in range(mini(loop, 2)):
				if extra[i % 2] == "dasher":
					list.append({"hp": _hp(20, loop),
						"pos": Vector2(650 + i * 170, 540 - i * 20), "ai": true,
						"look": "dasher", "name": "DASHER", "w": 30.0, "h": 46.0,
						"color": Color("ffd28f"), "dmg": 6 + loop,
						"speed": 200.0, "windup": 0.4, "recover": 0.3,
						"money": 5 + loop, "lunge": 50.0})
				else:
					list.append({"hp": _hp(30, loop),
						"pos": Vector2(650 + i * 170, 540 - i * 20), "ai": true,
						"look": "striker", "dmg": 8 + loop, "money": 4 + loop})
			_apply_tier(list, tier)
			return list
		1:
			var list := [
				{"hp": _hp(60, loop), "pos": Vector2(720, 510), "ai": true,
					"look": "brute", "name": "BRUTE", "w": 46.0, "h": 68.0,
					"spr": 1.25, "color": Color("ff8f8f"), "dmg": 12 + loop,
					"speed": 140.0, "windup": 0.7, "money": 8 + loop},
				{"hp": _hp(40, loop), "pos": Vector2(880, 545), "ai": true,
					"look": "fury", "name": "FURY", "w": 34.0, "h": 52.0,
					"color": Color("ff9fb0"), "dmg": 6 + loop, "speed": 150.0,
					"windup": 0.5, "money": 6 + loop, "hits": 2, "gap": 0.25},
				{"hp": _hp(70, loop), "pos": Vector2(1020, 505), "ai": true,
					"look": "slammer", "name": "SLAMMER", "w": 50.0, "h": 72.0,
					"spr": 1.3, "color": Color("cfa8ff"), "dmg": 0,
					"speed": 55.0, "money": 8 + loop,
					"slam": 10 + loop, "slam_range": 110.0, "slam_interval": 2.5},
			]
			if loop >= 1:
				list.append({"hp": _hp(40, loop), "pos": Vector2(620, 520),
					"ai": true, "look": "fury", "name": "FURY", "w": 34.0,
					"h": 52.0, "color": Color("ff9fb0"), "dmg": 6 + loop,
					"speed": 150.0, "windup": 0.5, "money": 6 + loop,
					"hits": 2, "gap": 0.25})
			_apply_tier(list, tier)
			return list
		_:
			var boss := [
				{"hp": _hp(150, loop, true), "pos": Vector2(850, 520),
					"ai": true, "look": "boss", "name": "BOSS", "w": 56.0,
					"h": 84.0, "spr": 1.5, "color": Color("ffb0b0"),
					"boss": true, "speed": 60.0, "money": 20 + 5 * loop,
					"slam": 15 + 2 * loop},
			]
			_apply_tier(boss, tier)
			return boss


## Tier per stage: nama + tint + bonus stat. Loop<5 (tier 0) = base utuh.
func _apply_tier(list: Array, tier: int) -> void:
	if tier <= 0:
		return
	var dmg_bonus := 2 * tier
	var spd_bonus := 10.0 * tier
	var money_bonus := tier
	for e in list:
		if e.has("dmg") and int(e["dmg"]) > 0:
			e["dmg"] = int(e["dmg"]) + dmg_bonus
		if e.has("speed"):
			e["speed"] = float(e["speed"]) + spd_bonus
		if e.has("money"):
			e["money"] = int(e["money"]) + money_bonus
		if e.has("spr"):
			e["spr"] = float(e["spr"]) + 0.1 * tier
		if e.has("slam_range"):
			e["slam_range"] = float(e["slam_range"]) + 10.0 * tier
		var look := str(e.get("look", "striker"))
		var nm := str(e.get("name", "DUMMY"))
		match look:
			"striker":
				e["name"] = "PUNK" if tier == 1 else "RAZOR"
				e["look"] = "punk" if tier == 1 else "razor"
			"dasher":
				e["name"] = "RUNNER" if tier == 1 else "VOLT"
				e["look"] = "runner" if tier == 1 else "volt"
				e["color"] = Color("ffb14d") if tier == 1 else Color("5affd2")
				if tier >= 2 and not e.has("lunge"):
					e["lunge"] = 20.0
			"brute":
				e["name"] = "ENFORCER" if tier == 1 else "TITAN"
				e["look"] = "enforcer" if tier == 1 else "titan"
				e["color"] = Color("ffb14d") if tier == 1 else Color("ff5a5a")
			"fury":
				e["name"] = "BERSERKER" if tier == 1 else "RAVAGER"
				e["look"] = "berserker" if tier == 1 else "ravager"
				e["color"] = Color("ff7bd2") if tier == 1 else Color("ff3f6e")
				if tier >= 2:
					e["hits"] = 3
			"slammer":
				e["name"] = "WRECKER" if tier == 1 else "DEMOLISHER"
				e["look"] = "wrecker" if tier == 1 else "demolisher"
				e["color"] = Color("9db8ff") if tier == 1 else Color("7bff9e")
			"boss":
				e["name"] = _boss_name(tier)
				e["look"] = "kingpin" if tier == 1 else ("don" if tier == 2 else "boss")
				e["color"] = Color("ffc46b") if tier == 1 else Color("ff6b6b")
				e["spr"] = 1.6 if tier == 1 else 1.7
				if nm != "BOSS" and nm != "":
					e["name"] = _boss_name(tier)


func _process(_delta: float) -> void:
	if active_index < 0 or cleared_fired or spawned.is_empty():
		return
	for e in spawned:
		if is_instance_valid(e) and not e.get("dead"):
			return
	cleared_fired = true
	wave_cleared.emit(active_index)


func _clear_old() -> void:
	for e in spawned:
		if is_instance_valid(e):
			e.queue_free()
	spawned.clear()
