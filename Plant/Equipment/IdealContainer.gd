class_name IdealContainer
extends GenericContainer

func _init(Elevation, Temperature, RatedPressure = Units.PsitoPa(1080), Volume = 1.0, Contents = {}):
	super(Elevation, Temperature, Volume, Contents)
	ratedPressure = RatedPressure
	
func getPressure():
	var mol = 0
	for content in contents:
		mol += contents[content] / Common.MolarMass[content]
	return (mol * Common.R * temperature) / volume

func fill_fraction():
	return getPressure() / ratedPressure
	
func add(stuff, amount, temp = temperature):
	var accepted = amount
	var old_cap = heat_capacity()
	var new_cap = accepted * Common.Info[stuff].SpecificHeat
	if old_cap + new_cap > 0.0:
		temperature = (temperature * old_cap + temp * new_cap) / (old_cap + new_cap)
	contents[stuff] = contents.get(stuff, 0.0) + accepted
	return accepted
