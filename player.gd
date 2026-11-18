extends CharacterBody3D

@export var speed = 4.0
@export var mouse_sens = 0.003
var gravity = 9.8

@onready var cam = $Camera3D
@onready var cameraFOVNormal = cam.fov
@onready var Arm = get_parent().get_node("CanvasLayer/Control/Arm")
@onready var Dot = get_parent().get_node("CanvasLayer/Control/Dot")
var cameraFOVZoomed: float = 25.0
var zoomDefault: float = 25.0
var zoomMin: float = 3.0
var zoomSpeed: float = 180.0
var rmbLock = false
var hovered: CollisionObject3D = null
var hitPos = Vector3.ZERO
var hitNormal = Vector3.UP
var reach = 3.0
var armTween
var armTip = Vector2(1660, 800)
var armShoulder = Vector2(3800, 1500)
var armComp = Vector2.ZERO
var armScale = Vector2.ONE
var pokeTween

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_viewport().physics_object_picking = false
	get_viewport().size_changed.connect(_fitArm)
	_fitArm()

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
	
	if event is InputEventMouseButton and event.pressed and Input.is_key_pressed(KEY_E):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cameraFOVZoomed = max(cameraFOVZoomed * 0.85, zoomMin)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cameraFOVZoomed = min(cameraFOVZoomed / 0.85, cameraFOVNormal)
	if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_RIGHT and hovered:
		hovered.input_event.emit(cam, event, hitPos, hitNormal, 0)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and Arm.visible:
		_pokeArm()

func _process(dt):
	var captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not rmbLock
	var rmb = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var show = captured and rmb
	if show and not Arm.visible:
		_swingArm()
	Arm.visible = show
	Dot.visible = captured and not rmb

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
	else:
		cameraFOVZoomed = zoomDefault
	
	cam.fov = lerp(cam.fov, target, 1.0 - exp(-10.0 * dt))
	
	var obj = null
	var pos = get_viewport().get_mouse_position()
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pos = get_viewport().get_visible_rect().size / 2
	var from = cam.project_ray_origin(pos)
	var q = PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(pos) * reach)
	q.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		obj = hit.collider
		hitPos = hit.position
		hitNormal = hit.normal
	if obj != hovered:
		if hovered: 
			hovered.mouse_exited.emit()
		if obj: 
			obj.mouse_entered.emit()
		hovered = obj

func _fitArm():
	var v = get_viewport().get_visible_rect().size
	var s = max(v.y * 0.5 / 1104.0, v.x * .5 / 2436.0) * 1.02
	Arm.position -= armComp
	Arm.scale = Vector2(s, s)
	armScale = Arm.scale
	armComp = (armTip - armShoulder) * (1.0 - s)
	Arm.pivot_offset = armShoulder
	Arm.position += armComp

func _swingArm():
	if armTween:
		armTween.kill()
	Arm.rotation_degrees = -40.0
	armTween = create_tween()
	armTween.tween_property(Arm, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _pokeArm():
	if pokeTween:
		pokeTween.kill()
	Arm.scale = armScale
	pokeTween = create_tween()
	pokeTween.tween_property(Arm, "scale", armScale * 0.97, 0.04)
	pokeTween.tween_property(Arm, "scale", armScale * 1.05, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pokeTween.tween_property(Arm, "scale", armScale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
