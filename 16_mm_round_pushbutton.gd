extends Node3D

signal pressed
signal released

@onready var collideArea = $StaticBody3D
@onready var sound = $Sound
@onready var solid = $Top
@onready var normalSolidHeight = solid.position.y
var tween
var held: bool = false

func _ready():
	solid.set_surface_override_material(0, solid.get_active_material(0).duplicate())
	collideArea.input_ray_pickable = true
	collideArea.input_event.connect(_on_input_event)

func _press(dx):
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(solid, "position:y", normalSolidHeight - dx, 0.06)

func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		held = true
		sound.play()
		_press(0.0025)
		pressed.emit()

func _input(event):
	if held and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		held = false
		_press(0.0)
		released.emit()
