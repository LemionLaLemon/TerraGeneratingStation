extends StaticBody3D

var breaker

func _ready():
	breaker = Plant.PulpPumpBreaker
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	
func _on_input_event(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		breaker.open() if breaker.isClosed() else breaker.close()
