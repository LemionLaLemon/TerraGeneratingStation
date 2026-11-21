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
	$P_204_RPM.text = Common.sig(Plant.P_204.getRpm(), 4)
	$P_205_RPM.text = Common.sig(Plant.P_205.getRpm(), 4)
	$V_206_PERCENT.text = Common.sig(Plant.V_206.getPosition() * 100.0, 3)
	$V_207_PERCENT.text = Common.sig(Plant.V_207.getPosition() * 100.0, 3)
	$VESSEL_PRESS_W.text = Common.sig(round(Plant.TerraTokamak.getPressure()), 6)
	$VESSEL_PRESS_N.text = Common.sig(Plant.TerraTokamak.getPressure() * 1000, 6)

	$P_204.texture = PUMP_CLOSED if Plant.P_204.energized() else PUMP_TRIPPED
	$P_205.texture = PUMP_CLOSED if Plant.P_205.energized() else PUMP_TRIPPED
	
	$V_204.texture = VALVE_OPEN if Plant.V_204.isOpen() else VALVE_CLOSED
	$V_205.texture = VALVE_OPEN if Plant.V_205.isOpen() else VALVE_CLOSED
	$V_206.texture = VALVE_OPEN if Plant.V_206.isOpen() else VALVE_CLOSED
	$V_207.texture = VALVE_OPEN if Plant.V_207.isOpen() else VALVE_CLOSED
