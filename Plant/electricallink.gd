class_name ElectricalLink
extends RefCounted

var ratio: float = 1 # For transformer stuff
var upstream
var downstream
var closed = true

func _init(from, to):
	upstream = from
	downstream = to
	if to != null:
		to.feeds.append(self)

func energized():
	return closed and upstream.energized()
	
func getVoltage():
	return upstream.getVoltage() * ratio if energized() else 0.0
