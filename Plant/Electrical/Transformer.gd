class_name Transformer
extends ElectricalLink

var ratedKva: float = 10000.0

func _init(from, to, source_voltage: float, output_voltage: float, RatedKva = 10000.0):
	super(from, to)
	ratio = output_voltage / source_voltage
	ratedKva = RatedKva

func getKva():
	return getLoad() / Common.PowerFactor

func getLoading():
	return getKva() / ratedKva * 100.0
