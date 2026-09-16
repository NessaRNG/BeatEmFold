class_name UiTheme
extends RefCounted
## Tema neon back-alley: font Kenney Pixel/Mini (CC0), button + panel + label.

static var _theme: Theme
static var _font_px: Font
static var _font_mini: Font


static func font_px() -> Font:
	if _font_px == null:
		_font_px = load("res://assets/fonts/Kenney Pixel.ttf")
	return _font_px


static func font_mini() -> Font:
	if _font_mini == null:
		_font_mini = load("res://assets/fonts/Kenney Mini.ttf")
	return _font_mini


static func build() -> Theme:
	if _theme != null:
		return _theme
	var th := Theme.new()
	th.default_font = font_mini()
	th.default_font_size = 18
	# --- Button ---
	var normal := _btn(Color("1c1626f2"), Color("6b5a8e"))
	var hover := _btn(Color("2a2138f2"), Color("ff5fd2"))
	var pressed := _btn(Color("3a2b52f2"), Color("ffd94d"))
	var disabled := _btn(Color("14141af2"), Color("3a3a44"))
	th.set_stylebox("normal", "Button", normal)
	th.set_stylebox("hover", "Button", hover)
	th.set_stylebox("pressed", "Button", pressed)
	th.set_stylebox("disabled", "Button", disabled)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", Color("f2f2f2"))
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color("ffd94d"))
	th.set_color("font_disabled_color", "Button", Color("555560"))
	th.set_font("font", "Button", font_px())
	th.set_font_size("font_size", "Button", 16)
	# --- Label: outline agar kebaca di atas laga ---
	th.set_color("font_outline_color", "Label", Color("0a0a12"))
	th.set_constant("outline_size", "Label", 5)
	_theme = th
	return th


static func _btn(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_corner_radius_all(7)
	s.content_margin_left = 16.0
	s.content_margin_right = 16.0
	s.content_margin_top = 10.0
	s.content_margin_bottom = 10.0
	return s


## Panel gaya slot/kartu: bg + border + radius.
static func panel_style(bg: Color, border: Color, bw: int = 1, radius: int = 7) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(radius)
	return s


## Label judul pixel + outline.
static func style_title(lb: Label, size: int, color: Color = Color.WHITE) -> void:
	lb.add_theme_font_override("font", font_px())
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", color)
	lb.add_theme_color_override("font_outline_color", Color("0a0a12"))
	lb.add_theme_constant_override("outline_size", maxi(int(size / 4.0), 4))


## Label body mini + outline tipis.
static func style_body(lb: Label, size: int, color: Color = Color("f2f2f2")) -> void:
	lb.add_theme_font_override("font", font_mini())
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", color)
	lb.add_theme_color_override("font_outline_color", Color("0a0a12"))
	lb.add_theme_constant_override("outline_size", 4)
