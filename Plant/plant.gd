extends Node

const AMBIENT_TEMPERATURE = 25 # DEG C

# Environment
var TGSAtmosphere

# Electrical
var Grid
var TR_S1 # Startup transformer
var TR_S1_Secondary # To split to two buses
var CB_TR_S1_A # "Control" Breaker Grid <-> Bus A Tie
var CB_TR_S1_B
var BusA
var BusB
var TR_S2
var TR_S2_Secondary
var CB_TR_S2_C
var CB_TR_S2_D
var BusC
var BusD

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

# Primary Systems
var TerraTokamak
# Vacuums
var P_200
var P_201
var P_202
var P_203
var P_204
var P_205
var P_200Breaker
var P_201Breaker
var P_202Breaker
var P_203Breaker
var P_204Breaker
var P_205Breaker

var V_200
var V_201
var V_202
var V_203
var V_204
var V_205
var V_200Breaker
var V_201Breaker
var V_202Breaker
var V_203Breaker
var V_204Breaker
var V_205Breaker

# Radwaste
var EquipmentDrainCollectorTank

var links = []

func _ready():
	print(Common.Info[Common.Materials.Water].Density)
	Grid = Bus.new(230_000, 60, true)
	# Environment
	TGSAtmosphere = Atmosphere.new(Units.CtoK(AMBIENT_TEMPERATURE))
	
	# Radwaste
	EquipmentDrainCollectorTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 50000) # temporary "infinite" volmume
	
	# Electrical
	TR_S1_Secondary = Bus.new(4160, 60, false) 
	BusA = Bus.new(4160, 60, false)
	BusB = Bus.new(4160, 60, false)
	
	TR_S2_Secondary = Bus.new(34500, 60, false)
	BusC = Bus.new(34500, 60, false)
	BusD = Bus.new(34500, 60, false)
	
	TR_S1 = Transformer.new(Grid, TR_S1_Secondary, 230_000, 4160)
	CB_TR_S1_A = Breaker.new(TR_S1_Secondary, BusA, true)
	CB_TR_S1_B = Breaker.new(TR_S1_Secondary, BusB, true)
	
	TR_S2 = Transformer.new(Grid, TR_S2_Secondary, 230_000, 34500)
	CB_TR_S2_C = Breaker.new(TR_S2_Secondary, BusC, true)
	CB_TR_S2_D = Breaker.new(TR_S2_Secondary, BusD, true)
	
	BananaBlenderBreaker = Breaker.new(BusA, null)
	BananaConveyorBreaker = Breaker.new(BusA, null)
	
	# Blending stage
	BananaHopper = GenericContainer.new(8, Units.CtoK(AMBIENT_TEMPERATURE), 34500 / Common.Info[Common.Materials.Banana].Density, {Common.Materials.Banana: 5000})
	BananaBlender = Blender.new(2, Units.CtoK(AMBIENT_TEMPERATURE), BananaBlenderBreaker, 100 / Common.Info[Common.Materials.Banana].Density, 0.5)
	BananaConveyor = Conveyor.new(0, Units.CtoK(AMBIENT_TEMPERATURE), BananaConveyorBreaker, .05)
	links.append(BeltLink.new(BananaHopper, BananaBlender, BananaConveyor))
	
	# Separating stage
	PulpTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100 / Common.Info[Common.Materials.Banana].Density)
	PulpSieve = Sieve.new(BananaBlender, PulpTank, 1.0, [Common.Materials.Pulp, Common.Materials.Water, Common.Materials.K40], true)
	links.append(PulpSieve)
	
	# Distillation stage
	PulpStillBreaker = Breaker.new(BusA, null, false)
	PulpPumpBreaker = Breaker.new(BusA, null, false)
	SludgeTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100 / Common.Info[Common.Materials.Banana].Density)
	WaterTank = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 100 / Common.Info[Common.Materials.Banana].Density)
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
	SeparatorProduct = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 0.002)
	SeparatorEffluent = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 0.2)
	SeparatorGirdlerSeparator = GirdlerSeparator.new(0, Units.CtoK(AMBIENT_TEMPERATURE), SeparatorGirdlerSeparatorBreaker, SeparatorProduct, SeparatorEffluent, 0.05)
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
	DeuteriumTank = IdealContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), Units.PsitoPa(10000), 1.0, {Common.Materials.D2: 12.0})
	OxygenVent = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 1_000_000_000)
	D2Electrolyser = Electrolyser.new(0, Units.CtoK(AMBIENT_TEMPERATURE), D2ElectrolyserBreaker, DeuteriumTank, OxygenVent)
	D2ElectrolyserFeedPump = Pump.new(SeparatorProduct, D2Electrolyser, 1.0, D2ElectrolyserFeedPumpBreaker, 5.0)
	D2ElectrolyserFeedPump.ratedKw = 0.5
	links.append(D2ElectrolyserFeedPump)
	
	
	# Primary Systems
	TerraTokamak = Tokamak.new(8, Units.CtoK(AMBIENT_TEMPERATURE), Units.PsitoPa(30), {Common.Materials.Air: 21400})
	
	# Roughing Pump Vacuums
	P_200Breaker = Breaker.new(BusC, null, false)
	P_201Breaker = Breaker.new(BusC, null, false)
	P_202Breaker = Breaker.new(BusD, null, false)
	P_203Breaker = Breaker.new(BusD, null, false)
	P_200 = Pump.new(TerraTokamak, TGSAtmosphere, 30.0, P_200Breaker, 0.0, 20.0, 1.0e4)
	P_201 = Pump.new(TerraTokamak, TGSAtmosphere, 30.0, P_201Breaker, 0.0, 20.0, 1.0e4)
	P_202 = Pump.new(TerraTokamak, TGSAtmosphere, 30.0, P_202Breaker, 0.0, 20.0, 1.0e4)
	P_203 = Pump.new(TerraTokamak, TGSAtmosphere, 30.0, P_203Breaker, 0.0, 20.0, 1.0e4)
	links.append(P_200)
	links.append(P_201)
	links.append(P_202)
	links.append(P_203)
	
	V_200Breaker = Breaker.new(BusC, null, false)
	V_201Breaker = Breaker.new(BusC, null, false)
	V_202Breaker = Breaker.new(BusD, null, false)
	V_203Breaker = Breaker.new(BusD, null, false)
	V_204Breaker = Breaker.new(BusC, null, false)
	V_205Breaker = Breaker.new(BusD, null, false)
	
	V_200 = MotorOperatedValve.new(V_200Breaker)
	P_200.gates.append(V_200)
	V_201 = MotorOperatedValve.new(V_201Breaker)
	P_201.gates.append(V_201)
	V_202 = MotorOperatedValve.new(V_202Breaker)
	P_202.gates.append(V_202)
	V_203 = MotorOperatedValve.new(V_203Breaker)
	P_203.gates.append(V_203)
	
	P_204Breaker = Breaker.new(BusC, null, false)
	P_205Breaker = Breaker.new(BusD, null, false)
	P_204 = Pump.new(TerraTokamak, TGSAtmosphere, 1.0, P_204Breaker, 0.0, 100.0, 1.0e10)
	P_205 = Pump.new(TerraTokamak, TGSAtmosphere, 1.0, P_205Breaker, 0.0, 100.0, 1.0e10)
	links.append(P_204)
	links.append(P_205)
	
	V_204 = MotorOperatedValve.new(V_204Breaker)
	P_204.gates.append(V_204)
	V_205 = MotorOperatedValve.new(V_205Breaker)
	P_205.gates.append(V_205)
	
	print("Ready")
	print(TerraTokamak.MajorRadius)
	print(TerraTokamak.MinorRadius)
	print(TerraTokamak.AspectRatio)
	print(TerraTokamak.Elongation )

func _physics_process(dt):
	dt = dt * 32
	for link in links:
		link.step(dt)
	BananaBlender.step(dt)
	PulpStill.step(dt)
	SeparatorGirdlerSeparator.step(dt)
	D2Electrolyser.step(dt)
