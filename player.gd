extends CharacterBody3D

@export var speed = 4.0
@export var mouse_sens = 0.003
var gravity = 9.8

@onready var cam = $Camera3D
@onready var cameraFOVNormal = cam.fov
var cameraFOVZoomed = 25.0
var zoomSpeed = 180.0
var rmbLock = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		cam.rotate_x(-event.relative.y * mouse_sens)
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			rmbLock = true
		elif not event.pressed and rmbLock:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			rmbLock = false
		

func _physics_process(dt):
	var dir = Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W): dir -= transform.basis.z
	if Input.is_physical_key_pressed(KEY_S): dir += transform.basis.z
	if Input.is_physical_key_pressed(KEY_A): dir -= transform.basis.x
	if Input.is_physical_key_pressed(KEY_D): dir += transform.basis.x
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= gravity * dt
	move_and_slide()
	
	var target = cameraFOVNormal
	if Input.is_key_pressed(KEY_E):
		target = cameraFOVZoomed
	
	cam.fov = lerp(cam.fov, target, 1.0 - exp(-10.0 * dt))
