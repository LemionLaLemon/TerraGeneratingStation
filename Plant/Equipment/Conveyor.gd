class_name Conveyor
extends GenericContainer

var supply
var kg_per_m: float = 20
var belt_speed_ms: float = 0.5

func _init(Elevation, Temperature, Supply, Speed = 0.5, Contents = {}):
	self.elevation = Elevation
	self.temperature = Temperature
	self.belt_speed_ms = Speed
	self.contents = Contents
	self.supply = Supply

func speed():
	return belt_speed_ms if supply.energized() else 0.0

func capacity():
	if not supply.energized():
		return 0.0
	return belt_speed_ms * kg_per_m
