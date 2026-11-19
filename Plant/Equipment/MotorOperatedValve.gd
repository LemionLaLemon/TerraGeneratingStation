class_name MotorOperatedValve
extends RefCounted

var supply
var travelTime: float = 10.0
var position: float = 0.0

func _init(Supply, TravelTime = 10.0):
	supply = Supply
	travelTime = TravelTime

func step(dt):
	if not supply.energized():
		return
	var target = 1.0 if supply.isClosed() else 0.0
	position = move_toward(position, target, dt / travelTime)

func isOpen():
	return position > 0.0

func getPosition():
	return position
