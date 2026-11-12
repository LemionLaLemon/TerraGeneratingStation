class_name Conveyor
extends GenericContainer

var powered: bool = false
var kg_per_m: float = 20
var belt_speed_ms: float = 0.5

func _init(Elevation, Temperature, Speed = 0.5, Contents = {}):
	self.elevation = Elevation
	self.temperature = Temperature
	self.belt_speed_ms = Speed
	self.contents = Contents

func speed():
	return belt_speed_ms if powered else 0.0

func capacity():
	if not powered:
		return 0.0
	return belt_speed_ms * kg_per_m

func trip():
	self.powered = false

func close():
	self.powered = true
