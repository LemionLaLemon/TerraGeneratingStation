class_name Sieve
extends Link

var passes = [Common.Materials.Pulp, Common.Materials.Water]
var clog: float = 0.0
var clog_per_kg: float = 0.002
var DEBUG_ClogBypass: float = false

func _init(from, to, max_flow = 1.0, Passes = [Common.Materials.Pulp, Common.Materials.Water], ClogBypass = false):
	source = from
	sink = to
	max_flow_kgs  = max_flow
	passes = Passes
	DEBUG_ClogBypass = ClogBypass

func _capacity():
	return super() * (1.0 - clog)

func step(dt):
	var fraction = clamp(_capacity() * dt / max(source.total_mass(), 0.001), 0.0, 1.0)
	for stuff in passes:
		var got = source.take(stuff, source.contents.get(stuff, 0.0) * fraction)
		source.add(stuff, got - sink.add(stuff, got))
		if stuff == Common.Materials.Pulp and not DEBUG_ClogBypass:
			clog = min(clog + got * clog_per_kg, 1.0)
