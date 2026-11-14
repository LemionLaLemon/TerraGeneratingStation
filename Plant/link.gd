class_name Link
extends RefCounted

var gates = []
var source
var sink
var max_flow_kgs: float = 1.0
var flow_kgs: float = 0.0
var coefficient: float = 1 # kg/s per sqrt(mass)

func _head():
	return source.elevation - sink.elevation

func _init(from, to, max_flow = 1.0):
	source = from
	sink = to
	max_flow_kgs  = max_flow

func _capacity():
	for gate in gates:
		if not gate.isOpen():
			return 0.0
	if _head() <= 0.0:
		return 0.0
	return min(coefficient * sqrt(_head()), max_flow_kgs)

func step(dt):
	var mass = source.total_mass()
	if mass <= 0.0:
		flow_kgs = 0.0
		return
		
	var amount = min(_capacity() * dt, mass)
	var fraction = amount / mass
	for stuff in source.contents.keys():
		var got = source.take(stuff, source.contents[stuff] * fraction)
		source.add(stuff, got - sink.add(stuff, got, source.temperature))
		flow_kgs = amount / dt
