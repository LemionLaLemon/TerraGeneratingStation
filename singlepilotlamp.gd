extends Node3D

@export var condition: String = ""
@export var interval: float = 0.1

@onready var lamp = $Lamp

var expr = Expression.new()
var t = 0.0

func _ready():
	t = randf() * interval
	if condition != "" and expr.parse(condition) != OK:
		push_error("Lamp na kaput")
	lamp.set_surface_override_material(0, lamp.get_active_material(0).duplicate())

func _process(dt):
	t += dt
	if t < interval:
		return
	t = 0.0
	if condition == "":
		lamp.get_surface_override_material(0).albedo_color = Color("7d7d7d")
		lamp.get_surface_override_material(0).emission_enabled = false

	var on = bool(expr.execute([], Plant))
	lamp.get_surface_override_material(0).albedo_color = Color("FFFFFF") if on else Color("7d7d7d")
	lamp.get_surface_override_material(0).emission_enabled = true if on else false
