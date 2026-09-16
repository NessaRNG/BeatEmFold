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


func wave_title(idx: int) -> String:
	return "WAVE %d" % (idx + 1)


func wave_banner(idx: int) -> String:
	var loop := loop_of(idx)
	var buff := " (+%d%% HP)" % int(loop * 40) if loop > 0 else ""
	match kind_of(idx):
		0:
			return "WAVE %d — STRIKER + DASHER!%s" % [idx + 1, buff]
		1:
			return "ELITE: BRUTE + FURY + SLAMMER!%s" % buff
		_:
			return "BOSS: %s DI-SEAL! AWAS SLAM!" % seal_name(wave_sealed(idx))


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
		d.ai_speed = float(e.get("speed", 120.0))
		d.ai_windup = float(e.get("windup", 0.6))
		d.ai_recover = float(e.get("recover", 0.4))
		d.strike_hits = int(e.get("hits", 1))
		d.strike_gap = float(e.get("gap", 0.25))
		d.strike_lunge = float(e.get("lunge", 0.0))
		d.money_value = int(e.get("money", 4))
		if e.has("slam"):
			d.slam_damage = int(e["slam"])
			d.slam_range = float(e.get("slam_range", 130.0))
			d.slam_interval = float(e.get("slam_interval", 3.0))
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
			return list
		_:
			return [
				{"hp": _hp(150, loop, true), "pos": Vector2(850, 520),
					"ai": true, "look": "boss", "name": "BOSS", "w": 56.0,
					"h": 84.0, "spr": 1.5, "color": Color("ffb0b0"),
					"boss": true, "speed": 60.0, "money": 20 + 5 * loop,
					"slam": 15 + 2 * loop},
			]


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
