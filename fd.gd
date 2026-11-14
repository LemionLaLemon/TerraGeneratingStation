extends Node3D

@export var page: PackedScene
@export var updatEvery: float = 0.5 # seconds
var pageNode
var t: float = 0.0

func _ready():
	pageNode = page.instantiate()
	$SubViewport.add_child(pageNode)

func _process(dt):
	t += dt
	if t >= updatEvery:
		t = 0.0
		pageNode.refresh()
		$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
