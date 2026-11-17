class_name Pump
extends Link

var supply
var rated_head_m: float
var ratedRpm: float = 1450
var rpm: float = 0
var ratedKw: float = 10.0
var pumpSpeed: float = 0.0
var maxRatio: float = 1.0e9 # rougly 1.0e4 for roughing pumps
var timeSinceStart: float = 0.0
var previousEnergized: bool = false
var started: bool = false

func getTimeSinceStart():
	return timeSinceStart

func getRatedRpm():
	return ratedRpm

func getRpm():
	return rpm

func _init(Source, Sink, Coefficient, Supply, Head = 20.0, Speed = 0.0, Ratio = 1.0e9):
	super(Source, Sink, Coefficient)
	supply = Supply
	supply.loads.append(getLoadKw)
	previousEnergized = supply.energized()
	rated_head_m = Head
	pumpSpeed = Speed
	maxRatio = Ratio

func _capacity():
	if source is IdealContainer or sink is IdealContainer:
		for gate in gates:
			if not gate.isOpen():
				return 0.0
				
		if sink.getPressure() > source.getPressure() * maxRatio:
			return 0.0
		var rate = (rpm / ratedRpm) * pumpSpeed * source.total_mass() / source.volume
		return min(rate, max_flow_kgs)
	return super()

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
		
	if previousEnergized == false and supply.energized():
		started = true
	if previousEnergized == true and not supply.energized():
		started = false
	if started:
		timeSinceStart += dt
		
	previousEnergized = supply.energized()
	super(dt)
