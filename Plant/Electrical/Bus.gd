class_name Bus
extends RefCounted

var voltage: float = 120
var nominalVoltage: float = 120
var frequency: float = 60
var isSource: bool = false
var feeds = []

func _init(Voltage = 120, Frequency = 60, IsSource = false):
	voltage = Voltage
	nominalVoltage = Voltage
	frequency = Frequency
	isSource = IsSource
	
func energized():
	if isSource:
		return true
	for link in feeds:
		if link.closed and link.upstream.energized():
			return true
	return false

func getVoltage():
	if isSource:
		return voltage
	for link in feeds:
		if link.closed and link.upstream.energized():
			return link.upstream.getVoltage() * link.ratio
	return 0.0

func getNominalVoltage():
	return nominalVoltage
