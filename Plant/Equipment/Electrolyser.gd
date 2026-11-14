class_name Electrolyser
extends GenericContainer

var supply
var d2tank
var oxygenVent
var rated_kw: float = 5.0
var kwh_per_kg: float = 5.6
var kw: float = 0.0

func _init(Elevation, Temperature, Supply, D2Tank, OxygenVent, Volume = 1.0, Contents = {}):
	super(Elevation, Temperature, Volume, Contents)
	supply = Supply
	d2tank = D2Tank
	oxygenVent = OxygenVent
	supply.loads.append(getLoadKw)

func getLoadKw():
	return kw

func step(dt):
	kw = 0.0
	if not supply.energized():
		return
	if d2tank.fill_fraction() > 0.95:
		return
	
	var feed = contents.get(Common.Materials.D2O, 0.0)
	if feed < 0.0:
		return
	var max_kg = rated_kw / kwh_per_kg / 3600.0 * dt
	var got = take(Common.Materials.D2O, min(feed, max_kg))
	kw = rated_kw * got / max_kg
	var parts = Common.Info[Common.Materials.D2O].Composition
	for part in parts:
		var amount = got * parts[part]
		var dest = d2tank if part == Common.Materials.D2 else oxygenVent
		add(part, amount - dest.add(part, amount))
