extends Node3D

@export var breakerName: String = ""
var breaker
var closed: bool = false
@onready var collideArea = $StaticBody3D
@onready var sound = $Sound
@onready var handle = $Handle
@onready var flag = $Flag
var HandleNormalAngle = 0
var HandleOperationAngle = 45
var tween
var held: bool = false

func _press():
	if tween:
		tween.kill()
	var target = HandleNormalAngle
	if held:
		target = -HandleOperationAngle if breaker.isClosed() else HandleOperationAngle
	tween = create_tween()
	tween.tween_property(handle, "rotation_degrees:y", target, 0.05)

func _ready():
	flag.set_surface_override_material(0, flag.get_active_material(0).duplicate())
	breaker = Plant.get(breakerName)
	collideArea.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	collideArea.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
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
		breaker.close() if closed else breaker.open()
		_setColor()
		_press()
		
func _setColor():
	flag.get_surface_override_material(0).albedo_color = Color("FF0000") if closed else Color("00FF00")

func _input(event):
	if held and event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		held = false
		_press()
