class_name MotorOperatedValve
extends RefCounted

var supply # motor power: the breaker feeding the actuator
var travelTime: float = 5.0
var position: float = 0.0
var demand: float = NAN
var commandOpen: bool = false # the operator's command; behaves like a breaker (see close/open/isClosed)

func _init(Supply, TravelTime = 5.0):
	supply = Supply
	travelTime = TravelTime
	supply.close() # motor power is normally available; the operator command is separate

func step(dt):
	if not supply.energized():
		return
	var target
	if is_nan(demand):
		target = 1.0 if commandOpen else 0.0
	else:
		target = demand if commandOpen else position
	position = move_toward(position, target, dt / travelTime)

# Breaker-style command interface, so a switch can drive the valve like it did the breaker.
# close() = energise the open command (valve travels open), open() = valve travels shut.
func close():
	commandOpen = true

func open():
	commandOpen = false

func isClosed():
	return commandOpen

func setDemand(Dem):
	demand = clamp(Dem, 0.0, 1.0)

func isOpen():
	return position > 0.0

func getPosition():
	return position
