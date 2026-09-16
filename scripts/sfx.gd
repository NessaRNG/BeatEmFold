class_name Sfx
extends Node
## Manager SFX: pool 8 player, pitch acak, null-safe dipanggil statis.
## Aset: Kenney Impact/Interface/Casino (CC0, lihat assets/LICENSE-kenney.txt).

static var instance: Sfx

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var cursor := 0


static func play_sfx(sfx_name: String, vol_db: float = 0.0, pitch: float = 1.0, pitch_var: float = 0.0) -> void:
	if instance != null:
		instance._play(sfx_name, vol_db, pitch, pitch_var)


func _ready() -> void:
	instance = self
	var files := {
		"punch_m": "res://assets/sfx/punch_m.ogg",
		"punch_h": "res://assets/sfx/punch_h.ogg",
		"slide": "res://assets/sfx/slide.ogg",
		"place": "res://assets/sfx/place.ogg",
		"shuffle": "res://assets/sfx/shuffle.ogg",
		"chips": "res://assets/sfx/chips.ogg",
		"confirm": "res://assets/sfx/confirm.ogg",
		"click": "res://assets/sfx/click.ogg",
		"error": "res://assets/sfx/error.ogg",
		"open": "res://assets/sfx/open.ogg",
	}
	for k in files:
		streams[k] = load(files[k])
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		pool.append(p)


func _play(sfx_name: String, vol_db: float, pitch: float, pitch_var: float) -> void:
	if not streams.has(sfx_name):
		return
	var p := pool[cursor]
	cursor = (cursor + 1) % pool.size()
	p.stream = streams[sfx_name]
	p.volume_db = vol_db
	if pitch_var > 0.0:
		p.pitch_scale = pitch + randf_range(-pitch_var, pitch_var)
	else:
		p.pitch_scale = pitch
	p.play()
