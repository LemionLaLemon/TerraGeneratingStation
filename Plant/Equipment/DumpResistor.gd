class_name DumpResistor
extends RefCounted

var resistance: float
var heatCapacityMJ: float
var temperature: float
var ambient: float
var coolingTau: float = 3600.0

func _init(Resistance, HeatCapacityMJ, Ambient):
	resistance = Resistance
	heatCapacityMJ = HeatCapacityMJ
	ambient = Ambient
	temperature = Ambient

func absorb(joules):
	temperature += joules / (heatCapacityMJ * 1.0e6)

func step(dt):
	temperature = lerp(temperature, ambient, 1.0 - exp(-dt / coolingTau))
