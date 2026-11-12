class_name Blender
extends GenericContainer

var supply
var rpm: float = 0
var ratedRpm: float = 3600
var rate_kgs: float = 2

const AllowedRecipes = [
	Common.Materials.Banana
]

func _init(Elevation, Temperature, Supply, Volume = 1.0, Rate = 2, RatedRpm = 3600, AllowedRecipes = [Common.Materials.Banana], Contents = {}):
	super(Elevation, Temperature, Volume, Contents)
	self.rate_kgs = Rate
	self.supply = Supply
	self.ratedRpm = RatedRpm

func getRpm():
	return rpm

func step(dt):
	if supply.energized():
		rpm = lerp(rpm, ratedRpm, 1.0 - exp(-0.4 * dt))
		if rpm < 1:
			rpm = 0.0
	else:
		rpm = lerp(rpm, 0.0, 1.0 - exp(-0.15 * dt))
		
	if self.total_mass() == 0.0:
		return

	for content in contents.keys():
		if not AllowedRecipes.has(content):
			continue

		var got = self.take(content, rate_kgs * dt * (rpm  / ratedRpm))
		var composition = Common.Info[content].Composition
		for component in composition:
			self.add(component, got * composition[component])
