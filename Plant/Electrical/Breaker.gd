class_name Breaker
extends ElectricalLink

func _init(from, to, Closed = false):
	super(from, to)
	closed = Closed
	
func close():
	closed = true

func open():
	closed = false
	
func isClosed():
	return closed
