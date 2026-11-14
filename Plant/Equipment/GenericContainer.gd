class_name GenericContainer
extends RefCounted

var contents = {}
var elevation: float = 0.0 # meters
var temperature: float = 20.0 # deg k
var volume: float = 1.0
var vessel_cap: float = 0.0 # heat capcity J/K

func _init(Elevation, Temperature, Volume = 1.0, Contents = {}):
	self.elevation = Elevation
	self.temperature = Temperature
	self.contents = Contents
	self.volume = Volume

func heat_capacity():
	var cap = vessel_cap
	for stuff in contents:
		cap += contents[stuff] * Common.Info[stuff].SpecificHeat
	return cap

func getTemperature():
	return temperature

func total_volume():
	var vol: float = 0
	for content in contents:
		vol += contents[content] / Common.Info[content].Density
	return vol

func fill_fraction():
	return total_volume() / volume

func total_mass():
	var total: float = 0.0
	for content in contents:
		total += contents[content]
	
	return total

func add(stuff, amount, temp = temperature):
	var room = (volume - total_volume()) * Common.Info[stuff].Density
	var accepted = min(amount, max(room, 0.0))
	var old_cap = heat_capacity()
	var new_cap = accepted * Common.Info[stuff].SpecificHeat
	if old_cap + new_cap > 0.0:
		temperature = (temperature * old_cap + temp * new_cap) / (old_cap + new_cap)
	contents[stuff] = contents.get(stuff, 0.0) + accepted
	return accepted

func take(stuff, amount):
	var got = min(amount, contents.get(stuff, 0.0))
	contents[stuff] = contents.get(stuff, 0.0) - got
	return got
