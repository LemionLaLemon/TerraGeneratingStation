extends CSGBox3D

@onready var banana = $banana

var maxBananas = 1600
var bananaCount = 1600

func findTopOfBananaPile() -> float:
	var top = 0
	for b in get_tree().get_nodes_in_group("bananas"):
		if b.global_position.y > 2.98:
			continue
		top = max(top, b.global_position.y)
	
	return top

func _ready():
	await get_tree().process_frame
	for i in maxBananas:
		var bananaClone = banana.duplicate()
		get_parent().add_child(bananaClone)
		var layer = floori(i / 100.0)
		var spot = Vector3(i % 10, layer, floori(i / 10.0) % 10)
		bananaClone.global_position = global_position + (spot - Vector3(5, 0, 5)) * 0.3 + Vector3(randf(), randf(), randf()) * 0.1
		bananaClone.rotation = Vector3(randf(), randf(), randf()) * TAU
		bananaClone.continuous_cd = true
		bananaClone.visible = true
