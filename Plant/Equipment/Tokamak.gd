class_name Tokamak
extends IdealContainer

# Measured from blender
var MeasuredVolume = 18052.1095 # m^3
var OuterDiameter = 44.1104
var OuterWidth = 14.9689
var InnerWidth = 13.8225
var InnerHeight = 21.5684

# Derived
var MajorRadius = OuterDiameter / 2 - OuterWidth / 2
var MinorRadius = InnerWidth / 2
var AspectRatio = MajorRadius / MinorRadius
var Elongation = InnerHeight / InnerWidth

# Visual
var MaterialOverride

# Magnets
var TF
var EF
var CS
var VS

# Neutral Beams
var beams = []

# Constants
const MU0 = 4.0e-7 * PI
const CS_PLASMA_M = 0.04
const AVOGADRO = 6.02214076e23
const BREAKDOWN_VLOOP = 1.0
const BREAKDOWN_BT = 1.0
const BREAKDOWN_PURITY = 0.9
const BREAKDOWN_PRESSURE = 0.05
const EV = 1.602176634e-19 
const TAU_E = 1.0
const TAU_P = 30.0
const EF_FIELD_SCALE = 0.07
const Q_MIN = 2.0
const NE_MIN = 1.0e17
const DISRUPT_TIME = 0.6
const IP_FLATTOP = 14.0e6
const NE_REF = 3.0e19
const TE_REF = 1000.0
const NBCD_GAMMA = 0.2
const P_LH = 12.0e6
const ROT_MAX = 49.0
const ROT_REF_P = 20.0e6
const TAU_ROT = 2.0
const ELM_PERIOD = 1.5
const ELM_LEN = 0.15

# Plasma Variables
var plasmaCurrent: float = 0.0
var plasmaTemp: float = 0.0
var plasmaMajor: float
var plasmaMinor: float
var plasmaShift: float = 0.0
var plasmaElong: float
var lastCS: float = 0.0
var bvFlatTop: float
var gapOut: float
var gapIn: float
var plasmaQ95: float = 15.0
var pNBI: float = 0.0
var plasmaH: float = 0.0
var plasmaRot: float = 0.0
var elmClock: float = 0.0
var elmPulse: float = 0.0
var plasmaAngle: float = 0.0

# Tokamak
var lockout: bool = false
var disrupting: float = 0.0

func _init(Elevation, Temperature, RatedPressure, tf, ef, cs, vs, shader, Contents = {}):
	super(Elevation, Temperature, RatedPressure, MeasuredVolume, Contents)
	ratedPressure = RatedPressure
	TF = tf
	EF = ef
	CS = cs
	VS = vs
	MaterialOverride = shader
	plasmaMajor = _uniform("major_radius", 12.9)
	plasmaMinor = _uniform("minor_radius", 4.22) * _uniform("separatrix", 0.92)
	plasmaElong = _uniform("elongation", 1.55)
	bvFlatTop = MU0 * IP_FLATTOP / (4.0 * PI *plasmaMajor) * (log(8.0 * plasmaMajor / plasmaMinor) - 0.7)
	gapOut = MajorRadius + MinorRadius - (plasmaMajor + plasmaMinor)
	gapIn = (plasmaMajor - plasmaMinor) - (MajorRadius - MinorRadius)
	lastCS = cs.current

func _uniform(name, fallback):
	var v = MaterialOverride.get_shader_parameter(name)
	return fallback if v == null else v

func step(dt):
	if dt <= 0.0:
		return
	var rMaj = plasmaMajor + plasmaShift
	var area = plasmaMinor * plasmaMinor * plasmaElong * PI # m^2
	var vol = 2.0 * PI * rMaj * area # m^3
	var bt = TF.getFieldT() * TF.majorRadius / rMaj
	var vloop = CS_PLASMA_M * (CS.current - lastCS) / dt
	lastCS = CS.current
	
	var d2mol = contents.get(Common.Materials.D2, 0.0) / Common.MolarMass[Common.Materials.D2]
	var pTotal = getPressure()
	var purity = 0.0
	if pTotal > 0.0:
		purity = d2mol * Common.R * temperature / volume / pTotal
	var ne = 2.0 * d2mol * AVOGADRO / vol
	pNBI = 0.0
	for beam in beams:
		var frac = beam.absorbedFraction(ne, 2.0 * plasmaMinor)
		pNBI += beam.power * frac
		add(Common.Materials.D2, beam.gasKgs * frac * dt)
	var iCD = NBCD_GAMMA * pNBI / max(ne / 1.0e20, 0.01) / rMaj

	if plasmaCurrent > 0.0:
		contents[Common.Materials.D2] = contents.get(Common.Materials.D2, 0.0) * exp(-dt / TAU_P)

	if vloop < BREAKDOWN_VLOOP:
		lockout = false
	if plasmaCurrent <= 0.0 and not lockout and vloop >= BREAKDOWN_VLOOP and bt >= BREAKDOWN_BT and pTotal <= BREAKDOWN_PRESSURE and purity >= BREAKDOWN_PURITY:
		plasmaCurrent = 1000.0
		plasmaTemp = 10.0

	# CS Ohmic heating
	if plasmaCurrent > 0.0 and disrupting == 0.0:
		var lp = MU0 * rMaj * (log(8.0 * rMaj / plasmaMinor) - 1.5)
		var eta = 5.2e-5 * 17.0 / pow(max(plasmaTemp, 5.0), 1.5)
		var rp = eta * 2.0 * PI * rMaj / area
		var ipInf = vloop / rp + iCD
		plasmaCurrent = ipInf + (plasmaCurrent - ipInf) * exp(-dt * rp / lp)
		if plasmaCurrent < 1000.0:
			plasmaCurrent = 0.0
			plasmaTemp = 0.0
		else:
			var heatCap = max(3.0 * ne * vol * EV, 1.0)
			var pHeat = plasmaCurrent * plasmaCurrent * rp + pNBI
			plasmaH += (smoothstep(0.8 * P_LH, 1.2 * P_LH, pHeat) - plasmaH) * (1.0 - exp(-dt / 1.0))
			var tauE = TAU_E * (1.0 + plasmaH)
			var tEq = pHeat * tauE / heatCap # (p_ohm + p_nbi)  * tau_e / heatcap
			plasmaTemp += (clamp(tEq, 5.0, 20000.0) - plasmaTemp) * (1.0 - exp(-dt / tauE))
			var bvReq = MU0 * plasmaCurrent / (4.0 * PI * rMaj) * (log(8.0 * rMaj / plasmaMinor) - 0.7)
			var bv = EF.getFieldT() * EF_FIELD_SCALE
			var err = clamp((bvReq - bv) / bvFlatTop, -1.5, 1.5)
			plasmaShift += (err * plasmaMinor - plasmaShift) * (1.0 - exp(-dt / 0.5))
			plasmaQ95 = 5.0 * plasmaMinor * plasmaMinor * bt * (1.0 + plasmaElong * plasmaElong) / 2.0 / (rMaj * plasmaCurrent / 1.0e6)
			if plasmaQ95 < Q_MIN or plasmaShift > gapOut or plasmaShift < -gapIn or ne < NE_MIN:
				disrupting = 0.001
				print("DISRUPT q=", plasmaQ95, " shift=", plasmaShift, " gaps=", gapIn, " ", gapOut, " ne=", ne)
	elif disrupting > 0.0:
		disrupting += dt / DISRUPT_TIME
		plasmaCurrent *= exp(-dt / 0.1)
		if disrupting >= 1.0:
			plasmaCurrent = 0.0
			plasmaTemp = 0.0
			disrupting = 0.0
			lockout = true
	if plasmaCurrent <= 0.0:
		plasmaShift = 0.0
		plasmaQ95 = 15.0
		plasmaH = 0.0
		plasmaRot = 0.0
		elmClock = 0.0
		elmPulse = 0.0
	
	var rotTarget = ROT_MAX * clamp(pNBI / ROT_REF_P, 0.0, 1.0)
	plasmaRot += (rotTarget - plasmaRot) * (1.0 - exp(-dt / TAU_ROT))
	plasmaAngle = fmod(plasmaAngle + plasmaRot * dt, TAU)
	
	elmPulse = 0.0
	if plasmaH > 0.8:
		elmClock += dt
		if elmClock >= ELM_PERIOD:
			elmClock -= ELM_PERIOD
			contents[Common.Materials.D2] = contents.get(Common.Materials.D2, 0.0) * 0.97
		if elmClock < ELM_LEN:
			elmPulse = sin(PI * elmClock / ELM_LEN)
		else:
			elmClock = 0.0
	
	var ipFrac = plasmaCurrent / IP_FLATTOP
	MaterialOverride.set_shader_parameter("plasma_current", clamp(ipFrac, 0.0, 1.0))
	MaterialOverride.set_shader_parameter("startup", 1.0 - smoothstep(0.03, 0.3, ipFrac))
	MaterialOverride.set_shader_parameter("diverted", smoothstep(0.4, 0.8, ipFrac))
	MaterialOverride.set_shader_parameter("density", clamp(ne / NE_REF, 0.0, 1.0))
	MaterialOverride.set_shader_parameter("edge_temp", clamp(0.5 * plasmaTemp / TE_REF, 0.0, 1.0))
	MaterialOverride.set_shader_parameter("q95", clamp(plasmaQ95, 1.0, 15.0))
	MaterialOverride.set_shader_parameter("collapse", disrupting)
	MaterialOverride.set_shader_parameter("major_radius", plasmaMajor + plasmaShift)
	MaterialOverride.set_shader_parameter("h_mode", plasmaH)
	MaterialOverride.set_shader_parameter("elm", elmPulse)
	MaterialOverride.set_shader_parameter("turbulence", lerp(0.8, 0.25, plasmaH))
	MaterialOverride.set_shader_parameter("toroidal_speed", 0.0)
	MaterialOverride.set_shader_parameter("toroidal_angle", plasmaAngle)
