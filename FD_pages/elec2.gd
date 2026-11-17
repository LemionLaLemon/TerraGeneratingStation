extends Control

const IMG_CLOSED =  preload("res://imported/CLOSED.png")
const IMG_OPEN = preload("res://imported/TRIPPED.png")

func refresh():
	$TR_S_VOLTS.text = "%.2f" % (Plant.TR_S2_Secondary.getVoltage()/1000)
	$TR_S_FREQ.text = "%.2f" % (Plant.TR_S2_Secondary.getFrequency())
	$TR_S_LOAD.text = "%.2f" % (Plant.TR_S2_Secondary.getLoad())
	
	$BUS_A_VOLTS.text = "%.2f" % (Plant.BusC.getVoltage()/1000)
	$BUS_A_FREQ.text = "%.2f" % (Plant.BusC.getFrequency())
	$BUS_A_LOAD.text = "%.2f" % (Plant.BusC.getLoad())
	
	$BUS_B_VOLTS.text = "%.2f" % (Plant.BusD.getVoltage()/1000)
	$BUS_B_FREQ.text = "%.2f" % (Plant.BusD.getFrequency())
	$BUS_B_LOAD.text = "%.2f" % (Plant.BusD.getLoad())
	
	$CB_TR_S_A.texture = IMG_CLOSED if Plant.CB_TR_S2_C.isClosed() else IMG_OPEN
	$CB_TR_S_B.texture = IMG_CLOSED if Plant.CB_TR_S2_D.isClosed() else IMG_OPEN
