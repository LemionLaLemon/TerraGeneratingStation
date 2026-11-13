class_name MotorOperatedValve
extends RefCounted

var supply

func _init(Supply):
	supply = Supply

func isOpen():
	return supply.energized()
