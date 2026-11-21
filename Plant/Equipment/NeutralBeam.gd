class_name NeutralBeam
extends RefCounted

var supply
var source
var ratedPower
var energyEv
var efficiency
var power: float = 0.0 # nb power
var powerMW: float = 0.0
var demand: float = 0.0
var rampTau: float = 10.0
var gasKgs: float = 0.0

const ELEMENTARY_CHARGE = 1.602176634e-19
const D_ATOM_KG = 3.3435837e-27
const SIGMA = 3.0e-20 # eff stopping cross section 100keV

func _init(Supply, Source, RatedPowerW, EnergyEv, Efficiency):
	supply = Supply
	source = Source
	ratedPower = RatedPowerW
	energyEv = EnergyEv
	efficiency = Efficiency
	supply.loads.append(getLoadKw)

func getLoadKw():
	return power / efficiency / 1000.0

func absorbedFraction(ne, pathLength):
	return 1.0 - exp(-ne * SIGMA * pathLength)

func step(dt):
	var target = clamp(demand, 0.0, ratedPower / 1.0e6) * 1.0e6 if supply.energized() else 0.0
	power = lerp(power, target, 1.0 - exp(-dt / rampTau))
	if power < 1.0:
		power = 0.0
	gasKgs = power / (energyEv * ELEMENTARY_CHARGE) * D_ATOM_KG
	if gasKgs > 0.0:
		var wanted = gasKgs * dt
		var got = source.take(Common.Materials.D2, wanted)
		if got < wanted:
			power *= got / wanted
			gasKgs = got / dt
	powerMW = power / 1.0e6
