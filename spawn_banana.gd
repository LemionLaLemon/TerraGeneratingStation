extends CSGBox3D

@onready var banana = $banana

func _ready():
	while true:
		var bananaClone = banana.duplicate()
		get_parent().add_child(bananaClone)
		bananaClone.global_position = global_position
		bananaClone.continuous_cd = true
		bananaClone.visible = true
		bananaClone.get_node("banana/Cylinder").set_instance_shader_parameter("bruisedness", randf())
		await get_tree().create_timer(.01).timeout
