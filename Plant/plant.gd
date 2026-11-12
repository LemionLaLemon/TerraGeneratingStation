extends Node

const AMBIENT_TEMPERATURE = 25 # DEG C

var BananaHopper
var BananaBlender
var BananaConveyor
var links = []

func _ready():
	print("Ready")
	print(Common.Info[Common.Materials.H2O].Density)
	BananaHopper = GenericContainer.new(10, Units.CtoK(AMBIENT_TEMPERATURE), 100, {Common.Materials.Banana: 50})
	BananaBlender = GenericContainer.new(0, Units.CtoK(AMBIENT_TEMPERATURE))
	BananaConveyor = Conveyor.new(0, Units.CtoK(AMBIENT_TEMPERATURE), .05)
	links.append(BeltLink.new(BananaHopper, BananaBlender, BananaConveyor))
	BananaConveyor.close()

func _physics_process(dt):
		for link in links:
			link.step(dt)
