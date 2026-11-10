extends Node3D

@export var belt_speed = 1.0
@export var belt_direction = Vector3.RIGHT
var uv_per_meter = .8

func _ready():
	var top = get_node("Cube_004")
	top.create_trimesh_collision()
	
	var body = top.get_child(top.get_child_count() - 1)
	body.constant_linear_velocity = belt_direction.normalized() * belt_speed

	var material = top.get_active_material(0)
	material.set_shader_parameter("Speed", belt_speed * uv_per_meter)
