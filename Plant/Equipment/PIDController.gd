class_name PIDController
extends RefCounted

var kp: float = 1.0
var ki: float = 0.1
var kd: float = 1.0
var auto: bool = false
var setpoint: float = 0.0
var manual_out: float = 0.0
var out: float = 0.0
var _i: float = 0.0
var _prev: float = 0.0
var controlEquipment
var controlProperty
var controllingEquipment
var controllingProperty
var multiply

func _init(ControlEquipment, ControlProperty, ControllingEquipment, ControllingProperty, Multiply = 1, P = 1.0, I = 0.1, D = 1.0):
	controlEquipment = ControlEquipment
	controlProperty = ControlProperty
	controllingEquipment = ControllingEquipment
	controllingProperty = ControllingProperty
	multiply = Multiply
	kp = P
	ki = I
	kd = D

func setAuto(Bool = true):
	auto = Bool

func setManual():
	auto = false

func setDemand(v):
	if auto:
		setpoint = v
	else:
		out = clamp(v / multiply, -1.0, 1.0)

func getDemand():
	return setpoint if auto else out * multiply

func getActual():
	return controllingEquipment.get(controllingProperty)

func step(dt):
	var pv = controllingEquipment.get(controllingProperty)
	if not auto:
		_i = out
		_prev = pv
		setpoint = pv
		controlEquipment.set(controlProperty, out * multiply)
		return
	var e = setpoint - pv
	var d = (pv - _prev) / dt
	_prev = pv
	var u = kp * e + _i - kd*d
	out = clamp(u, -1.0, 1.0)
	if out == u:
		_i += ki * e * dt
	controlEquipment.set(controlProperty, out * multiply)
