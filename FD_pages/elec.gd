extends Control

const IMG_CLOSED =  preload("res://imported/CLOSED.png")
const IMG_OPEN = preload("res://imported/TRIPPED.png")

func refresh():
	$TR_S_VOLTS.text = str(Plant.TR_S_Secondary.getVoltage())
	$TR_S_FREQ.text = str(Plant.TR_S_Secondary.getFrequency())
	#LOAD
	
	$BUS_A_VOLTS.text = str(Plant.BusA.getVoltage())
	$BUS_A_FREQ.text = str(Plant.BusA.getFrequency())
	#LOAD
	
	$BUS_B_VOLTS.text = str(Plant.BusB.getVoltage())
	$BUS_B_FREQ.text = str(Plant.BusB.getFrequency())
	#LOAD
	
	$CB_TR_S_A.texture = IMG_CLOSED if Plant.CB_TR_S_A.isClosed() else IMG_OPEN
	$CB_TR_S_B.texture = IMG_CLOSED if Plant.CB_TR_S_B.isClosed() else IMG_OPEN
