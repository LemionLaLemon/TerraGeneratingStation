class_name Magnet
extends RefCounted

var ps
var fd
var dump
var inductance: float = 10.0
var resistance : float = 0.01
var dumpResistance: float = 0.5
var ratedAmps: float = 50000.0
var maxVolts: float =  1000.0
var current: float = 0.0
var voltage: float = 0.0
var setpoint: float = 0.0
var relay
var turns: float = 36000.0
var majorRadius = 14.57
var wasTripped: bool

func _init(PS, FD, Dump, Relay, L, R, RatedAmps):
	ps = PS
	fd = FD
	dump = Dump
	relay = Relay
	inductance = L
	resistance = R
	ratedAmps = RatedAmps

func getFieldT():
	return 4.0e-7 * PI * turns * current / (2.0 * PI * majorRadius)

func getLoadKw():
	return abs(voltage * current) / 1000.0

func getEnergyMJ():
	return 0.5 * inductance * current * current / 1.0e6

func trip():
	if relay:
		relay.open()

func step(dt):
	var tripped = relay != null and not relay.isClosed()
	if tripped != wasTripped:
		if tripped:
			fd.open()
		else:
			fd.close()
		wasTripped = tripped
	if tripped and ps.supply.isClosed():
		ps.supply.open()
	if relay and not relay.isClosed() and not relay.energized():
		ps.supply.open()
	if not fd.isClosed():
		if ps.supply.isClosed():
			ps.supply.open()
		var i0 = current
		current *= exp(-(resistance + dump.resistance) * dt / inductance)
		var lost = 0.5 * inductance * (i0 * i0 - current * current)
		dump.absorb(lost * dump.resistance / (resistance + dump.resistance))
		voltage = 0.0
		ps.voltage = 0.0
		ps.current = 0.0
	elif ps.available():
		var maxDelta = ps.getMaxVolts() / inductance * dt
		var di = clamp(setpoint - current, -maxDelta, maxDelta)
		current += di
		voltage = inductance * di / dt + current * resistance
		ps.voltage = voltage
		ps.current = current
	else:
		current *= exp(-resistance * dt / inductance)
		voltage = 0.0
		ps.voltage = 0.0
		ps.current = 0.0
	dump.step(dt)
	if abs(current) > 1.1 * ratedAmps:
		trip()
