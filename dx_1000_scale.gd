extends ColorRect

@export var majors: int = 6
@export var minors: int = 9
@export var major_len: int = 20
@export var minor_len: int = 10
@export var tick_color := Color("#686868")
@export var text_color := Color("#000000")
@export var label_y: float = 12.0
var lo = 0.0
var hi = 100.0

func set_range(a: float, b: float):
	lo = a
	hi = b
	queue_redraw()

func set_cursor(i: int, v: float):
	var c = get_node(str(i + 1))
	var frac = clamp(inverse_lerp(lo, hi, v), 0.0, 1.0)
	c.position.x = round(size.x * frac - c.size.x * 0.5)

func _draw():
	var f = get_theme_default_font()
	var fs = get_theme_default_font_size()
	var steps = (majors - 1) * (minors + 1)
	for s in range(steps + 1):
		var x = round(size.x * s / steps) + 0.5
		var major = s % (minors + 1) == 0
		draw_line(Vector2(x, size.y), Vector2(x, size.y - (major_len if major else minor_len)), tick_color)
		if major:
			var text = Common.sig(lerp(lo, hi, s / float(steps)))
			var w = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(f, Vector2(clamp(x - w * 0.5, 0.0, size.x - w), label_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_color)
