class_name Atmosphere
extends IdealContainer

func _init(Temperature):
	super(-INF, Temperature, 101325, 0, INF)

func getPressure():
	return 101325.0 # PaA

func getTemperature():
	return temperature

func total_volume():
	return INF

func fill_fraction():
	return 0.0

func total_mass():
	return 0.0

func add(stuff, amount, temp = temperature):
	return amount

func take(stuff, amount):
	return amount
