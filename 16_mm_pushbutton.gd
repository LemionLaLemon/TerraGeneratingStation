extends Node3D

@export var breakerName: String = ""
var breaker
var closed: bool = false
@onready var collideArea = $StaticBody3D
@onready var sound = $Sound
@onready var solid = $Solid
@onready var transparent = $Transparent
@onready var normalSolidHeight = solid.position.y
@onready var normalTransparentHeight = solid.position.y
var tween
var held: bool = false

func _press(dx):
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(solid, "position:y", normalSolidHeight - dx, 0.06)
	tween.tween_property(transparent, "position:y", normalTransparentHeight - dx, 0.06)

func _ready():
	solid.set_surface_override_material(0, solid.get_active_material(0).duplicate())
	breaker = Plant.get(breakerName)
	if breaker == null:
		push_error("Breaker na kaput")
		return
		
	closed = breaker.isClosed()
	collideArea.input_ray_pickable = true
	collideArea.input_event.connect(_on_input_event)
	_setColor()
	
func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		held = true
		closed = not closed
		sound.play()
		breaker.open() if breaker.isClosed() else breaker.close()
		_setColor()
		_press(0.0025)
		
func _setColor():
	solid.get_surface_override_material(0).albedo_color = Color("FFFFFF") if closed else Color("C0C0C0")
	solid.get_surface_override_material(0).emission_enabled = true if closed else false

func _input(event):
	if held and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		held = false
		_press(0.0)
