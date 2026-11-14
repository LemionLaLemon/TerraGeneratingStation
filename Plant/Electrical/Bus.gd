class_name Bus
extends RefCounted

var voltage: float = 120
var nominalVoltage: float = 120
var frequency: float = 60
var isSource: bool = false
var feeds = []
var taps = []
var ratedAmps: float = 2000 # switchgear medium

func _init(Voltage = 120, Frequency = 60, IsSource = false, RatedAmps = 2000):
	voltage = Voltage
	nominalVoltage = Voltage
	frequency = Frequency
	isSource = IsSource
	ratedAmps = RatedAmps
	
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
	
func getLoad():
	var total: float = 0
	for link in taps:
		total += link.getLoad()
	return total

func getAmps():
	var v = getVoltage()
	if v <= 0.0:
		return 0.0
	return getLoad() * 1000.0 / (sqrt(3.0) * v * Common.PowerFactor)

func getLoading():
	return getAmps() / ratedAmps * 100.0

func getFrequency():
	return frequency if getVoltage() > 0 else 0.0

func getNominalVoltage():
	return nominalVoltage
