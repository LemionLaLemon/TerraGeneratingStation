extends Node3D

enum States {
	Normal,
	Alarm,
	Acknowledged,
	Ringback
}

@export_multiline var label: String = ""
@export var condition: String = ""
@export var ringback: bool = true
@export var litColor: Color = Color("#FFFFFF")
@export var unlitColor: Color = Color("808080")
@onready var tile = $Cube
var state = States.Normal
var expr = Expression.new()

func _ready():
	if expr.parse(condition) != OK:
		push_error("Annunciator " + label + " condition na kaput")
	$Label.text = label
	tile.set_surface_override_material(1, tile.get_active_material(1).duplicate())
	set_lit(false)

func active() -> bool:
	var v = expr.execute([], Plant)
	return not expr.has_execute_failed() and v

func update():
	var a = active()
	match state:
		States.Normal:
			if a:
				state = States.Alarm
		States.Acknowledged:
			if not a:
				state = States.Ringback if ringback else States.Normal
		States.Ringback:
			if a:
				state = States.Alarm

func ack():
	if state == States.Alarm:
		state = States.Acknowledged

func reset():
	if state == States.Ringback:
		state = States.Normal

func lit(fast, slow, test) -> bool:
	return test or state == States.Acknowledged or (state == States.Alarm and fast) or (state == States.Ringback and slow)

func set_lit(on: bool):
	tile.get_surface_override_material(1).albedo_color = litColor if on else unlitColor
	tile.get_surface_override_material(1).emission_enabled = on
