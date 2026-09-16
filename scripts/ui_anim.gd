class_name UiAnim
extends RefCounted
## Helper animasi transisi UI: fade, pop, rise + stagger delay.
## Dipanggil SETELAH layout final. Aman headless (tween biasa).


static func fade_in(c: Control, dur: float = 0.25, delay: float = 0.0, ignore_pause: bool = false) -> void:
	if not is_instance_valid(c):
		return
	c.modulate.a = 0.0
	var t := c.create_tween()
	if ignore_pause:
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(c, "modulate:a", 1.0, dur).set_delay(delay)


static func pop_in(c: Control, dur: float = 0.22, delay: float = 0.0, ignore_pause: bool = false, from: float = 0.7) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(from, from)
	c.modulate.a = 0.0
	var t := c.create_tween()
	if ignore_pause:
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	t.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	t.tween_property(c, "modulate:a", 1.0, dur * 0.7).set_delay(delay)


static func rise_in(c: Control, dist: float = 26.0, dur: float = 0.25, delay: float = 0.0, ignore_pause: bool = false) -> void:
	if not is_instance_valid(c):
		return
	var target: Vector2 = c.position
	c.position = target + Vector2(0, dist)
	c.modulate.a = 0.0
	var t := c.create_tween()
	if ignore_pause:
		t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.set_parallel(true)
	t.tween_property(c, "position", target, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
	t.tween_property(c, "modulate:a", 1.0, dur).set_delay(delay)


static func punch(c: Control, amount: float = 1.18, dur: float = 0.14) -> void:
	if not is_instance_valid(c):
		return
	c.pivot_offset = c.size * 0.5
	var t := c.create_tween()
	t.tween_property(c, "scale", Vector2(amount, amount), dur * 0.5)
	t.tween_property(c, "scale", Vector2.ONE, dur * 0.5)
