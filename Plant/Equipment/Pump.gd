class_name Pump
extends Link

var supply
var rated_head_m: float
var ratedRpm: float = 1450
var rpm: float = 0
var ratedKw: float = 10.0

func getRpm():
	return rpm

func _init(Source, Sink, Coefficient, Supply, Head = 20.0):
	super(Source, Sink, Coefficient)
	supply = Supply
	supply.loads.append(getLoadKw)
	rated_head_m = Head

func energized():
	return supply.energized()

func getLoadKw():
	return ratedKw * pow(rpm / ratedRpm, 3)

func _head():
	return super() + rated_head_m * pow(rpm / ratedRpm, 2)

func step(dt):
	if supply.energized():
		rpm = lerp(rpm, ratedRpm, 1.0 - exp(-1.0 * dt))
	else:
		rpm = lerp(rpm, 0.0, 1.0 - exp(-0.5 * dt))
	
	if rpm < 1:
		rpm = 0.0
		
	super(dt)
