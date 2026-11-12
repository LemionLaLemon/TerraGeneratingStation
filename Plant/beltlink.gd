class_name BeltLink
extends Link

var belt

func _init(from, to, b):
	super(from, to)
	belt = b
	
func _capacity():
	return belt.capacity()
