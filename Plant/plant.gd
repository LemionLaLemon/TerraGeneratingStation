extends Node

const AMBIENT_TEMPERATURE = 25 # DEG C

# Electrical
var Grid
var TR_S # Startup transformer
var TR_S_Secondary # To split to two buses
var CB_TR_S_A # "Control" Breaker Grid <-> Bus A Tie
var CB_TR_S_B
var BusA
var BusB

# Blending stage
var BananaHopper
var BananaBlenderBreaker
var BananaBlender
var BananaConveyorBreaker
var BananaConveyor

# Separating stage
var PulpSieve
var PulpTank

# Distillation stage
var SludgeTank
var PulpPump
var PulpPumpBreaker
var PulpStill
var PulpStillBreaker
var WaterTank
var SludgePump
var SludgePumpBreaker
var SludgeValve
var SludgeValveBreaker

# Separating stage 2
var SeparatorGirdlerSeparator
var SeparatorGirdlerSeparatorBreaker
var SeparatorProduct
var SeparatorEffluent
var SeparatorRecirculationIsolationValve
var SeparatorRecirculationIsolationValveBreaker
var SeparatorRecirculationPump
var SeparatorRecirculationPumpBreaker
var SeparatorSourcePump
var SeparatorSourcePumpBreaker
var SeparatorEffluentDischargeToRadwastePump #
var SeparatorEffluentDischargeToRadwastePumpBreaker
var SeparatorEffluentDischargeToRadwasteIsolationValve
var SeparatorEffluentDischargeToRadwasteIsolationValveBreaker

# Electrolysis
var D2Electrolyser
var D2ElectrolyserBreaker
var D2ElectrolyserFeedPump
var D2ElectrolyserFeedPumpBreaker
var DeuteriumTank
var OxygenVent

# Radwaste
var EquipmentDrainCollectorTank

var links = []

func _ready():
	print(Common.Info[Common.Materials.Water].Density)
	Grid = Bus.new(230_000, 60, true)
	# Radwaste
	EquipmentDrainCollectorTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 50000) # temporary "infinite" volmume
	
	# Electrical
	TR_S_Secondary = Bus.new(4160, 60, false) 
	BusA = Bus.new(4160, 60, false)
	BusB = Bus.new(4160, 60, false)
	
	TR_S = Transformer.new(Grid, TR_S_Secondary, 230_000, 4160)
	CB_TR_S_A = Breaker.new(TR_S_Secondary, BusA, true)
	CB_TR_S_B = Breaker.new(TR_S_Secondary, BusB, true)
	BananaBlenderBreaker = Breaker.new(BusA, null)
	BananaConveyorBreaker = Breaker.new(BusA, null)
	
	# Blending stage
	BananaHopper = GenericContainer.new(8, Units.CtoK(AMBIENT_TEMPERATURE), 34000, {Common.Materials.Banana: 50})
	BananaBlender = Blender.new(2, Units.CtoK(AMBIENT_TEMPERATURE), BananaBlenderBreaker, 100, 0.5)
	BananaConveyor = Conveyor.new(0, Units.CtoK(AMBIENT_TEMPERATURE), BananaConveyorBreaker, .05)
	links.append(BeltLink.new(BananaHopper, BananaBlender, BananaConveyor))
	
	# Separating stage
	PulpTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100)
	PulpSieve = Sieve.new(BananaBlender, PulpTank, 1.0, [Common.Materials.Pulp, Common.Materials.Water, Common.Materials.K40], true)
	links.append(PulpSieve)
	
	# Distillation stage
	PulpStillBreaker = Breaker.new(BusA, null, false)
	PulpPumpBreaker = Breaker.new(BusA, null, false)
	SludgeTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100)
	WaterTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100)
	PulpStill = Still.new(0, Units.CtoK(AMBIENT_TEMPERATURE), PulpStillBreaker, WaterTank)
	PulpPump = Pump.new(PulpTank, PulpStill, 1.0, PulpPumpBreaker, 15.0)
	links.append(PulpPump)
	SludgeValveBreaker = Breaker.new(BusA, null, false)
	SludgePumpBreaker = Breaker.new(BusA, null, false)
	SludgeValve = MotorOperatedValve.new(SludgeValveBreaker)
	SludgePump = Pump.new(PulpStill, SludgeTank, 1.0, SludgePumpBreaker)
	SludgePump.gates.append(SludgeValve)
	links.append(SludgePump)
	
	# Separating stage 2
	SeparatorSourcePumpBreaker = Breaker.new(BusA, null, false)
	SeparatorRecirculationIsolationValveBreaker = Breaker.new(BusA, null, false)
	SeparatorRecirculationPumpBreaker = Breaker.new(BusA, null, false)
	SeparatorGirdlerSeparatorBreaker = Breaker.new(BusA, null, false)
	SeparatorEffluentDischargeToRadwasteIsolationValveBreaker = Breaker.new(BusA, null, false)
	SeparatorEffluentDischargeToRadwastePumpBreaker = Breaker.new(BusA, null, false)
	SeparatorProduct = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 200)
	SeparatorEffluent = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 200)
	SeparatorGirdlerSeparator = GirdlerSeparator.new(0, Units.CtoK(AMBIENT_TEMPERATURE), SeparatorGirdlerSeparatorBreaker, SeparatorProduct, SeparatorEffluent, 400)
	SeparatorSourcePump = Pump.new(WaterTank, SeparatorGirdlerSeparator, 1.0, SeparatorSourcePumpBreaker)
	SeparatorRecirculationPump = Pump.new(SeparatorEffluent, SeparatorGirdlerSeparator, 1.0, SeparatorRecirculationPumpBreaker)
	SeparatorRecirculationIsolationValve = MotorOperatedValve.new(SeparatorRecirculationIsolationValveBreaker)
	SeparatorRecirculationPump.gates.append(SeparatorRecirculationIsolationValve)
	links.append(SeparatorSourcePump)
	links.append(SeparatorRecirculationPump)
	SeparatorEffluentDischargeToRadwastePump = Pump.new(SeparatorEffluent, EquipmentDrainCollectorTank, 1.0, SeparatorEffluentDischargeToRadwastePumpBreaker)
	SeparatorEffluentDischargeToRadwasteIsolationValve = MotorOperatedValve.new(SeparatorEffluentDischargeToRadwasteIsolationValveBreaker)
	SeparatorEffluentDischargeToRadwastePump.gates.append(SeparatorEffluentDischargeToRadwasteIsolationValve)
	links.append(SeparatorEffluentDischargeToRadwastePump)
	
	# Electrolysis
	D2ElectrolyserBreaker = Breaker.new(BusB, null, false)
	D2ElectrolyserFeedPumpBreaker = Breaker.new(BusB, null, false)
	DeuteriumTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 50)
	OxygenVent = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 1_000_000_000)
	D2Electrolyser = Electrolyser.new(0, Units.CtoK(AMBIENT_TEMPERATURE), D2ElectrolyserBreaker, DeuteriumTank, OxygenVent)
	D2ElectrolyserFeedPump = Pump.new(SeparatorProduct, D2Electrolyser, 1.0, D2ElectrolyserFeedPumpBreaker, 5.0)
	D2ElectrolyserFeedPump.ratedKw = 0.5
	links.append(D2ElectrolyserFeedPump)
	
	print("Ready")

func _physics_process(dt):
	for link in links:
		link.step(dt)
	BananaBlender.step(dt)
	PulpStill.step(dt)
	SeparatorGirdlerSeparator.step(dt)
	
	print(BusA.getLoad(), " ", BusA.getVoltage(), " ", Common.PowerFactor, " ", BusA.getAmps())
