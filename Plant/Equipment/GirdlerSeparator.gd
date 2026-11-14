class_name GirdlerSeparator
extends GenericContainer

var supply
var product
var effluent
var rate_kgs: float = 1.0
var recovery: float = 0.2
var target = Common.Materials.D2O
var splits = [Common.Materials.Water]

func _init(Elevation, Temperature, Supply, Product, Effluent, Volume = 1.0, Contents = {}):
	super(Elevation, Temperature, Volume, Contents)
	supply = Supply
	supply.loads.append(getLoadKw)
	product = Product
	effluent = Effluent

func getLoadKw():
	return 20.0 if supply.energized() else 0.0

func step(dt):
	if not supply.energized():
		return
		
	var budget = rate_kgs * dt
	for stuff in contents.keys():
		var got = take(stuff, min(contents[stuff], budget))
		budget -= got
		var parts = {stuff: 1.0}
		if splits.has(stuff):
			parts = Common.Info[stuff].Composition
		for part in parts:
			var amount = got * parts[part]
			var kept = amount * recovery if part == target else 0.0
			add(part, kept - product.add(part, kept))
			add(part, (amount - kept) - effluent.add(part, amount - kept))
