class_name GenericContainer
extends RefCounted

var contents = {}
var elevation: float = 0.0 # meters
var temperature: float = 20.0 # deg k
var volume: float = 1.0

func _init(Elevation, Temperature, Volume = 1.0, Contents = {}):
	self.elevation = Elevation
	self.temperature = Temperature
	self.contents = Contents
	self.volume = Volume

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

func add(stuff, amount):
	var room = (volume - total_volume()) * Common.Info[stuff].Density
	var accepted = min(amount, max(room, 0.0))
	contents[stuff] = contents.get(stuff, 0.0) + accepted
	return accepted

func take(stuff, amount):
	var got = min(amount, contents.get(stuff, 0.0))
	contents[stuff] = contents.get(stuff, 0.0) - got
	return got
