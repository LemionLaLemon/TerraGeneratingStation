extends Control

@export var x_divs: int = 10
@export var y_divs: int = 10
@export var grid_color := Color("#505050")

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw():
	for i in range(1, x_divs):
		var x = round(size.x * i / x_divs) + 0.5
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color)
	for i in range(1, y_divs):
		var y = round(size.y * i / y_divs) + 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color)
