class_name KeyButton
extends Button
## Tombol + shortcut keyboard satu huruf. Label otomatis "(M) MULAI".
## Aktif via _unhandled_key_input (tidak butuh fokus, jalan juga saat pause
## bila process_mode ALWAYS). Tanpa mouse pun bisa main penuh.

var hotkey := 0


func setup(label_text: String, key: int) -> void:
	hotkey = key
	text = "(%s)%s" % [OS.get_keycode_string(key), label_text.substr(1)]
	pressed.connect(_drop_focus)


func _drop_focus() -> void:
	var vp := get_viewport()
	if vp != null and vp.gui_get_focus_owner() == self:
		vp.gui_release_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if hotkey == 0 or disabled or not visible:
		return
	if not is_inside_tree():
		return
	var vp := get_viewport()
	if vp == null:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if int(k.physical_keycode) == hotkey or int(k.keycode) == hotkey:
		_drop_focus()
		pressed.emit()
		vp.set_input_as_handled()
