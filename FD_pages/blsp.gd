extends Control

const VALVE_CLOSED = preload("res://imported/VALVE_CLOSED.png")
const VALVE_OPEN = preload("res://imported/VALVE_OPEN.png")
const PUMP_CLOSED = preload("res://imported/PUMP_CLOSED.png")
const PUMP_TRIPPED = preload("res://imported/PUMP_TRIPPED.png")
const BLENDER_CLOSED = preload("res://imported/MIXER_CLOSED.png")
const BLENDER_TRIPPED = preload("res://imported/MIXER_TRIPPED.png")
const CONVEYOR_CLOSED = preload("res://imported/BELT_CLOSED.png")
const CONVEYOR_TRIPPED = preload("res://imported/BELT_TRIPPED.png")

static func sig(v: float, digits: int = 4) -> String:
	var a = abs(v)
	if a >= pow(10, digits):
		return "Ol."
	var n = 1 if a < 1.0 else int(floor(log(a) / log(10.0) + 1e-9)) + 1
	var d = digits - n
	var p = pow(10, d)
	var t = floor(a * p + 1e-9) / p
	if a > 0.0 and t == 0.0:
		return "Ul."
	var s = ("-" if v < 0.0 else "") + "%.*f" % [d, t]
	if s.contains("."):
		s = s.rstrip("0")
		if s.ends_with("."):
			s += "0"
	return s
	
func refresh():
	$TK_101_WEIGHT.text = sig(Plant.BananaHopper.total_mass(), 5)
	$CV_101_RATE.text = sig(Plant.BananaConveyor.speed(), 3)
	$BL_101_LEVEL.text = sig((Plant.BananaBlender.fill_fraction() * 5), 4)
	$BL_101_RPM.text = sig(Plant.BananaBlender.getRpm(), 4)
	$TK_104_LEVEL.text = sig((Plant.PulpTank.fill_fraction() * 5), 4)
	$TK_105_LEVEL.text = sig((Plant.WaterTank.fill_fraction() * 5), 4)
	$TK_106_LEVEL.text = sig((Plant.SludgeTank.fill_fraction() * 5), 4)
	$E_101_TEMP.text = sig(Units.KtoC(Plant.PulpStill.getTemperature()), 4)
	$E_101_LEVEL.text = sig((Plant.PulpStill.fill_fraction() * 5), 4)
	$P_101_RPM.text = sig(Plant.PulpPump.getRpm(), 4)
	$P_102_RPM.text = sig(Plant.SludgePump.getRpm(), 4)
	
	$CV_101.texture = CONVEYOR_CLOSED if Plant.BananaConveyor.energized() else CONVEYOR_TRIPPED
	$BL_101.texture = BLENDER_CLOSED if Plant.BananaBlender.energized() else BLENDER_TRIPPED
	$P_101.texture = PUMP_CLOSED if Plant.PulpPump.energized() else PUMP_TRIPPED
	$P_102.texture = PUMP_CLOSED if Plant.SludgePump.energized() else PUMP_TRIPPED
	$V_101.texture = VALVE_OPEN if Plant.SludgeValve.isOpen() else VALVE_CLOSED
	
	$TK_101_BAR.set_value(Plant.BananaHopper.fill_fraction())
	$BL_101_BAR.set_value(Plant.BananaBlender.fill_fraction())
	$E_101_BAR.set_value(Plant.PulpStill.fill_fraction())
	$TK_104_BAR.set_value(Plant.PulpTank.fill_fraction())
	$TK_105_BAR.set_value(Plant.WaterTank.fill_fraction())
	$TK_106_BAR.set_value(Plant.SludgeTank.fill_fraction())
