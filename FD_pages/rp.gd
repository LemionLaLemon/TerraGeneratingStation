extends Control

const VALVE_CLOSED = preload("res://imported/VALVE_CLOSED.png")
const VALVE_OPEN = preload("res://imported/VALVE_OPEN.png")
const PUMP_CLOSED = preload("res://imported/PUMP_CLOSED.png")
const PUMP_TRIPPED = preload("res://imported/PUMP_TRIPPED.png")
const BLENDER_CLOSED = preload("res://imported/MIXER_CLOSED.png")
const BLENDER_TRIPPED = preload("res://imported/MIXER_TRIPPED.png")
const CONVEYOR_CLOSED = preload("res://imported/BELT_CLOSED.png")
const CONVEYOR_TRIPPED = preload("res://imported/BELT_TRIPPED.png")

func refresh():
	$P_200_RPM.text = Common.sig(Plant.P_200.getRpm(), 4)
	$P_201_RPM.text = Common.sig(Plant.P_201.getRpm(), 4)
	$P_202_RPM.text = Common.sig(Plant.P_202.getRpm(), 4)
	$P_203_RPM.text = Common.sig(Plant.P_203.getRpm(), 4)
	$VESSEL_PRESS_W.text = Common.sig(round(Plant.TerraTokamak.getPressure()), 6)
	$VESSEL_PRESS_N.text = Common.sig(Plant.TerraTokamak.getPressure() * 1000, 6)

	$P_200.texture = PUMP_CLOSED if Plant.P_200.energized() else PUMP_TRIPPED
	$P_201.texture = PUMP_CLOSED if Plant.P_201.energized() else PUMP_TRIPPED
	$P_202.texture = PUMP_CLOSED if Plant.P_202.energized() else PUMP_TRIPPED
	$P_203.texture = PUMP_CLOSED if Plant.P_203.energized() else PUMP_TRIPPED
	
	$V_200.texture = VALVE_OPEN if Plant.V_200.isOpen() else VALVE_CLOSED
	$V_201.texture = VALVE_OPEN if Plant.V_201.isOpen() else VALVE_CLOSED
	$V_202.texture = VALVE_OPEN if Plant.V_202.isOpen() else VALVE_CLOSED
	$V_203.texture = VALVE_OPEN if Plant.V_203.isOpen() else VALVE_CLOSED
