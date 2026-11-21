@tool
extends Node3D

@export_multiline var label: String = "":
	set(value):
		label = value
		if is_node_ready():
			$Label.text = value
@export var condition: String = ""
@export var interval: float = 0.1

@onready var lamp = $Cube

var expr = Expression.new()
var t = 0.0

func _ready():
	$Label.text = label
	t = randf() * interval
	if condition != "" and expr.parse(condition) != OK:
		push_error("Lamp na kaput")
	lamp.set_surface_override_material(1, lamp.get_active_material(1).duplicate())

func _process(dt):
	if Engine.is_editor_hint():
		return
	t += dt
	if t < interval:
		return
	t = 0.0
	if condition == "":
		lamp.get_surface_override_material(1).albedo_color = Color("7d7d7d")
		lamp.get_surface_override_material(1).emission_enabled = false

	var on = bool(expr.execute([], Plant))
	lamp.get_surface_override_material(1).albedo_color = Color("FFFFFF") if on else Color("7d7d7d")
	lamp.get_surface_override_material(1).emission_enabled = true if on else false
