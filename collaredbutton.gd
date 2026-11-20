extends Node3D

@export var breakerName: String = ""
var breaker
var closed: bool = false
var armed: bool = false
@onready var collideArea = $StaticBody3D
@onready var sound = $Sound
@onready var button = $Button
@onready var normalButtonHeight = button.position.y
@onready var disarmedPosition = button.rotation_degrees.y # Normally closed because safety is safe
@onready var armedPosition = disarmedPosition - 90
var armTween
var pushTween

func _arm():
	if armTween:
		armTween.kill()
	armTween = create_tween()
	var target = armedPosition if armed else disarmedPosition
	armTween.tween_property(button, "rotation_degrees:y", target, 0.05)

func _press(dx):
	if pushTween:
		pushTween.kill()
	pushTween = create_tween().set_parallel(true)
	pushTween.tween_property(button, "position:y", normalButtonHeight - dx, 0.06)

func _ready():
	breaker = Plant.get(breakerName)
	collideArea.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	collideArea.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	if breaker == null:
		push_error("Breaker na kaput")
		return
		
	closed = not breaker.isClosed()
	collideArea.input_ray_pickable = true
	collideArea.input_event.connect(_on_input_event)

func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.shift_pressed and armed and not closed:
			armed = false
			_arm()
			return
		elif event.shift_pressed and armed and closed: # reset
			armed = false
			closed = false
			breaker.close()
			_arm()
			_press(0)
			return
		if not armed:
			armed = true
			_arm()
			return
		elif armed and not closed:
			closed = true
			sound.play()
			breaker.open()
			_press(0.003)
			return
		else: # reset
			armed = false
			closed = false
			breaker.close()
			_arm()
			_press(0)
			return
