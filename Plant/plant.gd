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

var BananaHopper
var BananaBlender
var BananaConveyorBreaker
var BananaConveyor
var links = []

func _ready():
	print(Common.Info[Common.Materials.H2O].Density)
	Grid = Bus.new(230_000, 60, true)
	
	TR_S_Secondary = Bus.new(120, 60, false) 
	BusA = Bus.new(120, 60, false)
	BusB = Bus.new(120, 60, false)
	
	TR_S = Transformer.new(Grid, TR_S_Secondary, 230_000, 120)
	CB_TR_S_A = Breaker.new(TR_S_Secondary, BusA, true)
	CB_TR_S_B = Breaker.new(TR_S_Secondary, BusB, true)
	BananaConveyorBreaker = Breaker.new(BusA, null)
	
	BananaHopper = GenericContainer.new(10, Units.CtoK(AMBIENT_TEMPERATURE), 100, {Common.Materials.Banana: 50})
	BananaBlender = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE))
	BananaConveyor = Conveyor.new(0, Units.CtoK(AMBIENT_TEMPERATURE), BananaConveyorBreaker, .05)
	links.append(BeltLink.new(BananaHopper, BananaBlender, BananaConveyor))
	print("Ready")

func _physics_process(dt):
		for link in links:
			link.step(dt)
