class_name Still
extends GenericContainer

const LATENT_HEAT = 2.26e6
const BOIL_K = 373.15
var supply
var condensate
var power_w: float = 700000

func _init(Elevation, Temperature, Supply, Condensate, Volume = 1.0, Contents = {}):
	super(Elevation, Temperature, Volume, Contents)
	supply = Supply
	condensate = Condensate
	
func step(dt):
	if not supply.energized():
		return
	
	var heat = power_w * dt
	
	if temperature < BOIL_K:
		var cap = 0.0
		for content in contents.keys():
			cap += contents[content] * Common.Info[content].SpecificHeat
		
		if cap > 0.0:
			var used = min(heat, (BOIL_K - temperature) * cap)
			temperature += used / cap
			heat -= used
	
	if temperature >= BOIL_K and heat > 0.0:
		var steam = take(Common.Materials.Water, heat / LATENT_HEAT)
		add(Common.Materials.Water, steam - condensate.add(Common.Materials.Water, steam))
