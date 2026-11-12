class_name Common
extends RefCounted

# enums for every material usable
enum Materials {
	Banana,
	H2O,
	H2,
	K40,
}

# bit masks
enum States {
	Solid = 1,
	Liquid = 2,
	Gas = 4,
	Plasma = 8
}

# density in kg/m^3
# specific heat in J/(kg * K)
const Info = {
	Materials.Banana: {
		"Density": 950.0,
		"SpecificHeat": 3350.0,
		"State": States.Solid
	},
	Materials.H2O: {
		"Density": 998.2,
		"SpecificHeat": 4184.0,
		"State": States.Liquid | States.Solid | States.Gas
	}
}
