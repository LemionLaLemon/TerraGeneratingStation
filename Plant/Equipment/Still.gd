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
	supply.loads.append(getLoadKw)
	condensate = Condensate
	vessel_cap = 1.0e6
	
func getLoadKw():
	return power_w / 1000.0 if supply.energized else 0.0
	
func step(dt):
	if not supply.energized():
		return
	
	var heat_cap = heat_capacity()
	var heat = power_w * dt
	
	if temperature < BOIL_K and heat_cap > 0.0:
		var used = min(heat, (BOIL_K - temperature) * heat_cap)
		temperature += used / heat_cap
		heat -= used
	
	if temperature >= BOIL_K and heat > 0.0:
		var steam = take(Common.Materials.Water, heat / LATENT_HEAT)
		add(Common.Materials.Water, steam - condensate.add(Common.Materials.Water, steam, BOIL_K))
	temperature = lerp(temperature, Units.CtoK(Plant.AMBIENT_TEMPERATURE), 1.0 - exp(-0.0005 * dt))
