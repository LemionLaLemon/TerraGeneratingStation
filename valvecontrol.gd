extends Node3D

@export var breakerName: String = ""
var breaker
var closed: bool = false
@onready var collideArea = $StaticBody3D
@onready var sound = $Sound
@onready var handle = $Handle
var closedPosition = -90
var openPosition = -180
var tween

func _press():
	if tween:
		tween.kill()
	tween = create_tween()
	var target = closedPosition if closed else openPosition
	tween.tween_property(handle, "rotation_degrees:y", target, 0.05)

func _ready():
	breaker = Plant.get(breakerName)
	collideArea.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	collideArea.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	if breaker == null:
		push_error("Breaker na kaput")
		return
		
	closed = breaker.isClosed()
	handle.rotation_degrees.y = closedPosition if closed else openPosition
	collideArea.input_ray_pickable = true
	collideArea.input_event.connect(_on_input_event)

func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		closed = not closed
		sound.play()
		print(breaker.isClosed())
		breaker.close() if closed else breaker.open()
		print(breaker.isClosed())
		_press()
