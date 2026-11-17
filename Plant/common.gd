class_name Common
extends RefCounted

# enums for every material usable
enum Materials {
	Banana,
	Pulp,
	Water, # Natural Water
	Air, # Environment Air
	H2O, # Light Water
	D2, # Hydrogen-2
	D2O, # Heavy Water
	K40, # Potassium-40
	O, # Oxygen (specific isotope not useful)
	O2, # Dioxygen
	N2, #Dinitrogen
	Ar # Argon
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
# composition MUST add up to exactly 1
const Info = {
	Materials.Banana: {
		"Density": 950.0,
		"SpecificHeat": 3350.0,
		"State": States.Solid,
		"Composition": {
			Materials.Pulp: 0.25,
			Materials.Water: 0.749,
			Materials.K40: 0.001
		}
	},
	Materials.Pulp: { # Final use of pulp, no more useful extractable components
		"Density": 1500.0,
		"SpecificHeat": 1550.0,
		"State": States.Solid | States.Liquid,
	},
	Materials.Water: {
		"Density": 998.2,
		"SpecificHeat": 4184.0,
		"State": States.Liquid | States.Solid | States.Gas,
		"Composition": {
			Materials.H2O: 0.999827,
			Materials.D2O: 0.000173
		}
	},
	Materials.D2O: {
		"Density": 1105.6,
		"SpecificHeat": 4219.0,
		"State": States.Liquid | States.Solid | States.Gas,
		"Composition": {
			Materials.D2: 0.2011,
			Materials.O: 0.7989
		}
	},
	# i can't be bothered to fill these in by hand anymore
	Materials.D2:    {"Density": 0.167, "SpecificHeat": 7240.0, "State": States.Gas | States.Liquid | States.Solid},
	Materials.K40:   {"Density": 862.0, "SpecificHeat": 757.0, "State": States.Solid | States.Liquid},
	Materials.O:     {"Density": 1.31, "SpecificHeat": 920.0, "State": States.Gas | States.Liquid | States.Solid},
	Materials.H2O: {"Density": 998.2, "SpecificHeat": 4184.0, "State": States.Liquid | States.Solid | States.Gas},
	Materials.Air: {
		"Density": 1.184,
		"SpecificHeat": 1005.0,
		"State": States.Gas,
		"Composition": {
			Materials.N2: 0.7556,
			Materials.O2: 0.2315,
			Materials.Ar: 0.0129
		}
	},
	Materials.N2: {
		"Density": 1.145,
		"SpecificHeat": 1040.0,
		"State": States.Gas
	},
	Materials.O2: {
		"Density": 1.308,
		"SpecificHeat": 918.0,
		"State": States.Gas
	},
	Materials.Ar: {
		"Density": 1.633,
		"SpecificHeat": 520.0,
		"State": States.Gas
	},
}

# Ideal gas law stuff
const R = 8.314462
const MolarMass = {
	Materials.D2: 0.004028,
	Materials.O: 0.031998,
	Materials.Air: 0.02897,
	Materials.N2: 0.028014,
	Materials.O2: 0.031998,
	Materials.Ar: 0.039948,
}

# Electrical
const PowerFactor = 0.85 # pretty awful

# Functions
static func sig(v: float, digits: int = 4) -> String:
	var a = abs(v)
	if a >= pow(10, digits):
		return "Ol."
	var n = 1 if a < 1.0 else int(floor(log(a) / log(10.0) + 1e-9)) + 1
	var d = digits - n
	var p = pow(10, d)
	var t = floor(a * p + 1e-9) / p
	if a > 0.0 and t == 0.0:
		return "Ul."
	var s = ("-" if v < 0.0 else "") + "%.*f" % [d, t]
	if s.contains("."):
		s = s.rstrip("0")
		if s.ends_with("."):
			s += "0"
	return s
