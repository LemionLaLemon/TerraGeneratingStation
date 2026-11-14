class_name ElectricalLink
extends RefCounted

var ratio: float = 1 # For transformer stuff
var upstream
var downstream
var closed = true
var loads = []

func _init(from, to):
	upstream = from
	downstream = to
	from.taps.append(self)
	if to != null:
		to.feeds.append(self)

func getLoad():
	if not energized():
		return 0.0
	if downstream != null:
		return downstream.getLoad()
	var total = 0.0
	for load in loads:
		total += load.call()
	return total

func energized():
	return closed and upstream.energized()
	
func getVoltage():
	return upstream.getVoltage() * ratio if energized() else 0.0
