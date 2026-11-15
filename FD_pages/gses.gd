extends Control

const VALVE_CLOSED = preload("res://imported/VALVE_CLOSED.png")
const VALVE_OPEN = preload("res://imported/VALVE_OPEN.png")
const PUMP_CLOSED = preload("res://imported/PUMP_CLOSED.png")
const PUMP_TRIPPED = preload("res://imported/PUMP_TRIPPED.png")
const ELECTROLYSER_CLOSED = preload("res://imported/ELECTROLYSER_CLOSED.png")
const ELECTROLYSER_TRIPPED = preload("res://imported/ELECTROLYSER_TRIPPED.png")
const GIRDLER_CLOSED = preload("res://imported/GIRDLER_CLOSED.png")
const GIRDLOER_TRIPPED = preload("res://imported/GIRDLER_TRIPPED.png")

func refresh():
	$TK_105_LEVEL.text = Common.sig((Plant.WaterTank.fill_fraction() * 5), 4)
	$GS_101_LEVEL.text = Common.sig((Plant.SeparatorGirdlerSeparator.fill_fraction() * 5), 4)
	$TK_107_LEVEL.text = Common.sig((Plant.SeparatorProduct.fill_fraction() * 5), 4)
	$TK_110_LEVEL.text = Common.sig((Plant.DeuteriumTank.fill_fraction() * 5), 4)
	$EL_101_POWER.text = Common.sig((Plant.D2Electrolyser.getLoadKw()), 4)
	$TK_108_LEVEL.text = Common.sig((Plant.SeparatorEffluent.fill_fraction() * 5), 4)
	$EL_101_LEVEL.text = Common.sig((Plant.D2Electrolyser.fill_fraction() * 5), 4)
	$P_106_RPM.text = Common.sig((Plant.SeparatorSourcePump.getRpm()), 4)
	$P_105_RPM.text = Common.sig((Plant.D2ElectrolyserFeedPump.getRpm()), 4)
	$P_104_RPM.text = Common.sig((Plant.SeparatorEffluentDischargeToRadwastePump.getRpm()), 4)
	$P_103_RPM.text = Common.sig((Plant.SeparatorRecirculationPump.getRpm()), 4)
	
	$P_106.texture = PUMP_CLOSED if Plant.SeparatorSourcePump.energized() else PUMP_TRIPPED
	$P_103.texture = PUMP_CLOSED if Plant.SeparatorRecirculationPump.energized() else PUMP_TRIPPED
	$P_105.texture = PUMP_CLOSED if Plant.D2ElectrolyserFeedPump.energized() else PUMP_TRIPPED
	$P_104.texture = PUMP_CLOSED if Plant.SeparatorEffluentDischargeToRadwastePump.energized() else PUMP_TRIPPED
	$V_102.texture = VALVE_OPEN if Plant.SeparatorRecirculationIsolationValve.isOpen() else VALVE_CLOSED
	$V_103.texture = VALVE_OPEN if Plant.SeparatorEffluentDischargeToRadwasteIsolationValve.isOpen() else VALVE_CLOSED
	$EL_101.texture = ELECTROLYSER_CLOSED if Plant.D2Electrolyser.energized() else ELECTROLYSER_TRIPPED
	$GS_101.texture = GIRDLER_CLOSED if Plant.SeparatorGirdlerSeparator.energized() else GIRDLOER_TRIPPED
	
	$TK_105_BAR.set_value(Plant.WaterTank.fill_fraction())
	$GS_101_BAR.set_value(Plant.SeparatorGirdlerSeparator.fill_fraction())
	$TK_107_BAR.set_value(Plant.SeparatorProduct.fill_fraction())
	$TK_108_BAR.set_value(Plant.SeparatorEffluent.fill_fraction())
	$EL_101_BAR.set_value(Plant.D2Electrolyser.fill_fraction())
	$TK_110_BAR.set_value(Plant.DeuteriumTank.fill_fraction())
