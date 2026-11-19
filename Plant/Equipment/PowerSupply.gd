class_name PowerSupply
extends RefCounted

var supply
var maxVolts: float
var maxAmps: float
var efficiency: float = 0.95
var voltage: float = 0.0
var current: float = 0.0

func _init(Supply, MaxVolts, MaxAmps, Efficiency):
	supply = Supply
	maxVolts = MaxVolts
	maxAmps = MaxAmps
	efficiency = Efficiency
	supply.loads.append(getLoadKw)

func available():
	return supply.energized()

func getMaxVolts():
	return maxVolts if available() else 0.0

func getLoadKw():
	return abs(voltage * current) / 1000.0 / efficiency
