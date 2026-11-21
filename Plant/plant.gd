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
var SeparatorEffluentDischargeToRadwastePump
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
var V_206 # CV
var V_207 # CV
var V_206Breaker
var V_207Breaker
var C_206
var C_207
var V_200Breaker
var V_201Breaker
var V_202Breaker
var V_203Breaker
var V_204Breaker
var V_205Breaker

# Toroidal Field Magnets
var CB_500
var CB_501
var TFPowerSupply
var TFDumpResistor
var TFMagnet
var TFMagnetTripRelay
var TFMagnetController

# Equlibrium Field Magnets
var CB_502
var CB_503
var EFPowerSupply
var EFDumpResistor
var EFMagnet
var EFMagnetTripRelay
var EFMagnetController

# Central Solenoid
var CB_504
var CB_505
var CSPowerSupply
var CSDumpResistor
var CSMagnet
var CSMagnetTripRelay
var CSMagnetController

# Central Solenoid
var CB_506
var CB_507
var VSPowerSupply
var VSDumpResistor
var VSMagnet
var VSMagnetTripRelay
var VSMagnetController

# Neutral Beams
var NeutralBeamC
var NeutralBeamD
var NeutralBeamCBreaker
var NeutralBeamDBreaker
var NeutralBeamCController
var NeutralBeamDController

# Radwaste
var EquipmentDrainCollectorTank

# Sim parameter breakers
var Accel32x
var Accel64x
var GridBO

# "Breakers"
var CSPrechargeButton
var CSDischargeButton

var links = []

func _ready():
	print(Common.Info[Common.Materials.Water].Density)
	Grid = Bus.new(230_000, 60, true)
	Accel32x = Breaker.new(Grid, null, false)
	Accel64x = Breaker.new(Grid, null, false)
	GridBO = Breaker.new(Grid, null, false)
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
	links.append(SludgeValve)
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
	links.append(SeparatorRecirculationIsolationValve)
	SeparatorRecirculationPump.gates.append(SeparatorRecirculationIsolationValve)
	links.append(SeparatorSourcePump)
	links.append(SeparatorRecirculationPump)
	SeparatorEffluentDischargeToRadwastePump = Pump.new(SeparatorEffluent, EquipmentDrainCollectorTank, 1.0, SeparatorEffluentDischargeToRadwastePumpBreaker)
	SeparatorEffluentDischargeToRadwasteIsolationValve = MotorOperatedValve.new(SeparatorEffluentDischargeToRadwasteIsolationValveBreaker)
	links.append(SeparatorEffluentDischargeToRadwasteIsolationValve)
	SeparatorEffluentDischargeToRadwastePump.gates.append(SeparatorEffluentDischargeToRadwasteIsolationValve)
	links.append(SeparatorEffluentDischargeToRadwastePump)
	
	# Electrolysis
	D2ElectrolyserBreaker = Breaker.new(BusB, null, false)
	D2ElectrolyserFeedPumpBreaker = Breaker.new(BusB, null, false)
	DeuteriumTank = IdealContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), Units.PsitoPa(10000), 1.0, {Common.Materials.D2: 120.0})
	OxygenVent = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE), 1_000_000_000)
	D2Electrolyser = Electrolyser.new(0, Units.CtoK(AMBIENT_TEMPERATURE), D2ElectrolyserBreaker, DeuteriumTank, OxygenVent)
	D2ElectrolyserFeedPump = Pump.new(SeparatorProduct, D2Electrolyser, 1.0, D2ElectrolyserFeedPumpBreaker, 5.0)
	D2ElectrolyserFeedPump.ratedKw = 0.5
	links.append(D2ElectrolyserFeedPump)
	
	# Toroidal Field Magnet
	CB_500 = Breaker.new(BusC, null, false)
	CB_501 = Breaker.new(BusC, null, true)
	TFMagnetTripRelay = Breaker.new(BusC, null, true)
	TFPowerSupply = PowerSupply.new(CB_500, 300.0, 60000.0, 0.95)
	TFDumpResistor = DumpResistor.new(0.1, 50.0, Units.CtoK(AMBIENT_TEMPERATURE))
	TFMagnet = Magnet.new(TFPowerSupply, CB_501, TFDumpResistor, TFMagnetTripRelay, 4.0, 0.0001, 13000.0)
	TFMagnetController = PIDController.new(TFMagnet, "setpoint", TFMagnet, "current", 13000, 0, 0, 0)
	links.append(TFMagnetController)
	
	# Equilibrium Field Magnet
	CB_502 = Breaker.new(BusC, null, false)
	CB_503 = Breaker.new(BusC, null, true)
	EFMagnetTripRelay = Breaker.new(BusC, null, true)
	EFPowerSupply = PowerSupply.new(CB_502, 300.0, 60000.0, 0.95)
	EFDumpResistor = DumpResistor.new(0.1, 50.0, Units.CtoK(AMBIENT_TEMPERATURE))
	EFMagnet = Magnet.new(EFPowerSupply, CB_503, EFDumpResistor, EFMagnetTripRelay, 4.0, 0.0001, 10000.0)
	EFMagnetController = PIDController.new(EFMagnet, "setpoint", EFMagnet, "current", 10000, 0, 0, 0)
	links.append(EFMagnetController)
	
	# Central Solenoid
	CB_504 = Breaker.new(BusD, null, false)
	CB_505 = Breaker.new(BusD, null, true)
	CSMagnetTripRelay = Breaker.new(BusD, null, true)
	CSPowerSupply = PowerSupply.new(CB_504, 600.0, 60000.0, 0.95)
	CSDumpResistor = DumpResistor.new(0.1, 50.0, Units.CtoK(AMBIENT_TEMPERATURE))
	CSMagnet = Magnet.new(CSPowerSupply, CB_505, CSDumpResistor, CSMagnetTripRelay, 4.0, 0.0001, 10000.0)
		
	# Vertical Stability
	CB_506 = Breaker.new(BusD, null, false)
	CB_507 = Breaker.new(BusD, null, true)
	VSMagnetTripRelay = Breaker.new(BusD, null, true)
	VSPowerSupply = PowerSupply.new(CB_506, 600.0, 60000.0, 0.95)
	VSDumpResistor = DumpResistor.new(0.1, 50.0, Units.CtoK(AMBIENT_TEMPERATURE))
	VSMagnet = Magnet.new(VSPowerSupply, CB_507, VSDumpResistor, VSMagnetTripRelay, 0.5, 0.0001, 10000.0)
	VSMagnetController = PIDController.new(VSMagnet, "setpoint", VSMagnet, "current", 10000, 0, 0, 0)
	links.append(VSMagnetController)
	
	# Primary Systems
	TerraTokamak = Tokamak.new(8, Units.CtoK(AMBIENT_TEMPERATURE), Units.PsitoPa(30), TFMagnet, EFMagnet, CSMagnet, VSMagnet, Plant.get_tree().current_scene.find_child("PlasmaVolume", true, false).get_active_material(0), {Common.Materials.D2: 0.0003}) # Common.Materials.Air: 21400, 
	
	# cringe controller needs tokamak
	CSMagnetController = PIDController.new(CSMagnet, "setpoint", CSMagnet, "current", 10000, 0, 0, 0)
	links.append(CSMagnetController)
	CSDischargeButton = Breaker.new(BusC, null, false)
	CSPrechargeButton = Breaker.new(BusC, null, false)
	
	# Neutral Beams
	NeutralBeamCBreaker = Breaker.new(BusC, null, false)
	NeutralBeamDBreaker = Breaker.new(BusD, null, false)
	NeutralBeamC = NeutralBeam.new(NeutralBeamCBreaker, DeuteriumTank, 10.0e6, 1.0e5, 0.3)
	NeutralBeamD = NeutralBeam.new(NeutralBeamDBreaker, DeuteriumTank, 10.0e6, 1.0e5, 0.3)
	links.append(NeutralBeamC)
	links.append(NeutralBeamD)
	NeutralBeamCController = PIDController.new(NeutralBeamC, "demand", NeutralBeamC, "powerMW", 10.0, 0, 0, 0)
	NeutralBeamDController = PIDController.new(NeutralBeamD, "demand", NeutralBeamD, "powerMW", 10.0, 0, 0, 0)
	links.append(NeutralBeamCController)
	links.append(NeutralBeamDController)
	TerraTokamak.beams.append(NeutralBeamC)
	TerraTokamak.beams.append(NeutralBeamD)
	
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
	links.append(V_200)
	P_200.gates.append(V_200)
	V_201 = MotorOperatedValve.new(V_201Breaker)
	links.append(V_201)
	P_201.gates.append(V_201)
	V_202 = MotorOperatedValve.new(V_202Breaker)
	links.append(V_202)
	P_202.gates.append(V_202)
	V_203 = MotorOperatedValve.new(V_203Breaker)
	links.append(V_203)
	P_203.gates.append(V_203)
	
	# Turbo Molecular Pump Vacuums
	P_204Breaker = Breaker.new(BusC, null, false)
	P_205Breaker = Breaker.new(BusD, null, false)
	P_204 = Pump.new(TerraTokamak, TGSAtmosphere, 1.0, P_204Breaker, 0.0, 100.0, 1.0e10)
	P_205 = Pump.new(TerraTokamak, TGSAtmosphere, 1.0, P_205Breaker, 0.0, 100.0, 1.0e10)
	links.append(P_204)
	links.append(P_205)
	
	V_204 = MotorOperatedValve.new(V_204Breaker)
	links.append(V_204)
	P_204.gates.append(V_204)
	V_205 = MotorOperatedValve.new(V_205Breaker)
	links.append(V_205)
	P_205.gates.append(V_205)
	
	V_206Breaker = Breaker.new(BusC, null, true)
	V_206 = MotorOperatedValve.new(V_206Breaker)
	V_206.close()
	links.append(V_206)
	P_204.gates.append(V_206)
	C_206 = PIDController.new(V_206, "demand", TerraTokamak, "pressureMPa", 20.0, -1.0, -0.01, 0.0)
	links.append(C_206)
	V_207Breaker = Breaker.new(BusD, null, true)
	V_207 = MotorOperatedValve.new(V_207Breaker)
	V_207.close()
	links.append(V_207)
	P_205.gates.append(V_207)
	C_207 = PIDController.new(V_207, "demand", TerraTokamak, "pressureMPa", 20.0, -1.0, -0.01, 0.0)
	links.append(C_207)
	
	print("Ready")
	print(TerraTokamak.MajorRadius)
	print(TerraTokamak.MinorRadius)
	print(TerraTokamak.AspectRatio)
	print(TerraTokamak.Elongation )

func _physics_process(dt):
	if Accel32x.isClosed():
		dt = dt * 32
	if Accel64x.isClosed():
		dt = dt * 64
	if GridBO.isClosed():
		Grid.setEnergized(false)
	else:
		Grid.setEnergized(true)
	for link in links:
		link.step(dt)
	
	# Interlocks and Inhibits
	# Central Solenoid
	if CSDischargeButton.isClosed() and CSMagnet.current <= -9990.0 and TFMagnet.getFieldT() >= 1.0 and TerraTokamak.getPressure() < 0.05:
		CSMagnetController.setDemand(10000)
		CSDischargeButton.open()
	elif CSPrechargeButton.isClosed() and TerraTokamak.plasmaCurrent <= 0.0:
		CSMagnetController.setDemand(-10000)
		CSPrechargeButton.open()
	
	# Turbo Molecular Pumps
	var tmpP = TerraTokamak.getPressure()
	if P_204Breaker.isClosed() and (tmpP > 50.0 or (P_204.rpm < 1.0 and tmpP > 15.0)):
		P_204Breaker.open()
	if P_205Breaker.isClosed() and (tmpP > 50.0 or (P_205.rpm < 1.0 and tmpP > 15.0)):
		P_205Breaker.open()
	
	BananaBlender.step(dt)
	PulpStill.step(dt)
	SeparatorGirdlerSeparator.step(dt)
	D2Electrolyser.step(dt)
	TFMagnet.step(dt)
	EFMagnet.step(dt)
	CSMagnet.step(dt)
	VSMagnet.step(dt)
	TerraTokamak.step(dt)
