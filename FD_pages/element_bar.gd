extends ColorRect

@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var alarm_low: float = -INF
@export var alarm_high: float = INF
@export var normal_color: Color = Color("#00FF00")
@export var alarm_color: Color = Color("#FF0000")

func set_value(value: float):
	var frac = clamp(inverse_lerp(min_value, max_value, value), 0.0, 1.0)
	scale.y = frac
	color = alarm_color if (value < alarm_low or value > alarm_high) else normal_color
