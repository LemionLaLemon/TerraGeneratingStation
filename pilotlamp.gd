extends Node3D

@export var condition: String = ""
@export var floatCondition: String = ""
@export var interval: float = 0.1

@onready var lampRed = $Lamp_001
@onready var lampGreen = $Lamp

var expr = Expression.new()
var floatexpr = Expression.new()
var t = 0.0

func _ready():
	t = randf() * interval
	if (condition != "" and expr.parse(condition) != OK) or (floatCondition != "" and floatexpr.parse(floatCondition) != OK):
		push_error("Lamp na kaput")
	lampRed.set_surface_override_material(0, lampRed.get_active_material(0).duplicate())
	lampGreen.set_surface_override_material(0, lampGreen.get_active_material(0).duplicate())

func _process(dt):
	t += dt
	if t < interval:
		return
	t = 0.0
	if not condition == "":
		var on = bool(expr.execute([], Plant))
		lampRed.get_surface_override_material(0).albedo_color = Color("FF0000") if on else Color("7d0000")
		lampGreen.get_surface_override_material(0).albedo_color = Color("007d00") if on else Color("00FF00")
		lampRed.get_surface_override_material(0).emission_enabled = true if on else false
		lampGreen.get_surface_override_material(0).emission_enabled = false if on else true
	if not floatCondition == "":
		var pos = float(floatexpr.execute([], Plant))
		if pos == 0:
			lampRed.get_surface_override_material(0).albedo_color = Color("7d0000")
			lampGreen.get_surface_override_material(0).albedo_color = Color("00FF00")
			lampRed.get_surface_override_material(0).emission_enabled = false
			lampGreen.get_surface_override_material(0).emission_enabled = true
		elif pos == 1:
			lampRed.get_surface_override_material(0).albedo_color = Color("FF0000")
			lampGreen.get_surface_override_material(0).albedo_color = Color("007d00")
			lampRed.get_surface_override_material(0).emission_enabled = true
			lampGreen.get_surface_override_material(0).emission_enabled = false
		else:
			lampRed.get_surface_override_material(0).albedo_color = Color("FF0000")
			lampGreen.get_surface_override_material(0).albedo_color = Color("00FF00")
			lampRed.get_surface_override_material(0).emission_enabled = true
			lampGreen.get_surface_override_material(0).emission_enabled = true
			
