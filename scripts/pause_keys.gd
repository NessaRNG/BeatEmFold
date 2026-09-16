class_name PauseKeys
extends Node
## Listener input global yang tetap jalan saat tree paused
## (process_mode ALWAYS): ESC/P pause, T restart, M menu, Enter/Y/L lanjut.

var game: Node2D
var esc_was := false
var t_was := false
var m_was := false
var enter_was := false
var y_was := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if game == null:
		return
	var esc := Input.is_physical_key_pressed(KEY_ESCAPE) or Input.is_physical_key_pressed(KEY_P)
	if esc and not esc_was:
		game.toggle_pause()
	esc_was = esc
	var t := Input.is_physical_key_pressed(KEY_T)
	if t and not t_was:
		game.restart_run()
	t_was = t
	var m := Input.is_physical_key_pressed(KEY_M)
	if m and not m_was:
		game.to_menu()
	m_was = m
	var enter := Input.is_action_just_pressed("cashin")
	if enter and not enter_was:
		game.confirm_end()
	enter_was = enter
	var y := Input.is_physical_key_pressed(KEY_Y)
	if y and not y_was:
		game._start_tutorial()
	y_was = y
