@tool
extends Node3D

var maxNeedleAngle: float = -51.2 # deg
var minNeedleAngle: float = 0.0 # deg

var tickBase = 144
var tickStart = 983
var tickEnd = 38
var majorLen = 35
var minorLen = 25
var majorWidth = 6
var minorWidth = 3

var fontSize = 36
var tickFontSize = 22

var controller: PIDController
var actShown: float = NAN
var demShown: float = NAN
var response: float = 4.0 # response time

# Buttons
@onready var raise = $RAISE
@onready var lower = $LOWER
@onready var auto = $AUTO
@onready var man = $MAN
var normalY = 0.024
var pressedY = 0.02
var restY = {}       # button -> its resting position.y
var pressTweens = {} # button -> its running press tween
var raiseHeld: bool = false
var lowerHeld: bool = false
var modeShown = null # last AUTO/MAN state shown on the buttons
@export var rate: float = 0.1 # fraction of the scale moved per second while RAISE/LOWER is held

# The controller owns its setpoint (demand). RAISE/LOWER will change this later.
var setpoint: float = 50.0:
	set(v):
		setpoint = clamp(v, minValue, maxValue)
		setDemand(setpoint)

@export var controllerName: String = ""
@export var minValue: float = 0.0:
	set(v):
		minValue = v
		refreshViews()
@export var maxValue: float = 100.0:
	set(v):
		maxValue = v
		refreshViews()
@export var majorStep: float = 30.0:
	set(v):
		majorStep = v
		refreshViews()
@export var minorDivisions: int = 5:
	set(v):
		minorDivisions = v
		refreshViews()
@export var unit: String = "mPaA":
	set(v):
		unit = v
		refreshViews()
@export var previewActual: float = 10.0:
	set(v):
		previewActual = v
		setActual(v)

@onready var demNeedle = $DEMNEEDLE
@onready var actNeedle = $ACTNEEDLE
@onready var scaleView = $ScaleView
@onready var unitView = $UnitView
@onready var ticks = $ScaleView/Ticks
@onready var unitLabel = $UnitView/Label

func _ready():
	if not Engine.is_editor_hint():
		controller = Plant.get(controllerName)
		if controller == null:
			push_error("Controller na kaput")
		_setupButton(raise, _onRaise)
		_setupButton(lower, _onLower)
		_setupButton(auto, _onAuto)
		_setupButton(man, _onMan)
	ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not ticks.draw.is_connected(drawTicks):
		ticks.draw.connect(drawTicks)
	unitLabel.add_theme_font_size_override("font_size", fontSize)
	refreshViews()
	setDemand(setpoint)
	setActual(previewActual)

func _process(dt):
	if Engine.is_editor_hint() or controller == null:
		return
	if controller.auto != modeShown:
		modeShown = controller.auto
		_pressButton(auto, modeShown)
		_pressButton(man, not modeShown)
	var dir = int(raiseHeld) - int(lowerHeld)
	if dir != 0:
		controller.setDemand(clamp(controller.getDemand() + dir * rate * (maxValue - minValue) * dt, minValue, maxValue))
	var a = controller.getActual()
	actShown = a if is_nan(actShown) else lerp(actShown, float(a), 1.0 - exp(-response * dt))
	setActual(actShown)
	var d = controller.getDemand()
	demShown = d if is_nan(demShown) else lerp(demShown, float(d), 1.0 - exp(-response * dt))
	setDemand(demShown)

# ---- Buttons ----
func _setupButton(btn, handler):
	restY[btn] = btn.position.y
	var body = btn.get_node("StaticBody3D")
	body.input_ray_pickable = true
	body.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	body.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))
	body.input_event.connect(handler)

func _pressButton(btn, down):
	if pressTweens.get(btn):
		pressTweens[btn].kill()
	var target = restY[btn] - (normalY - pressedY) if down else restY[btn]
	pressTweens[btn] = create_tween()
	pressTweens[btn].tween_property(btn, "position:y", target, 0.06)

func _isLeftPress(event):
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

# AUTO and MAN latch: the one you pressed stays down, the other pops up (done in _process)
func _onAuto(camera, event, pos, normal, shape_idx):
	if _isLeftPress(event) and controller:
		controller.setAuto()

func _onMan(camera, event, pos, normal, shape_idx):
	if _isLeftPress(event) and controller:
		controller.setManual()

# RAISE and LOWER are momentary: down while the mouse is held
func _onRaise(camera, event, pos, normal, shape_idx):
	if _isLeftPress(event):
		raiseHeld = true
		_pressButton(raise, true)

func _onLower(camera, event, pos, normal, shape_idx):
	if _isLeftPress(event):
		lowerHeld = true
		_pressButton(lower, true)

func _input(event):
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if raiseHeld:
			raiseHeld = false
			_pressButton(raise, false)
		if lowerHeld:
			lowerHeld = false
			_pressButton(lower, false)

func valueToY(v):
	return tickStart - (tickStart - tickEnd) * (v - minValue) / (maxValue - minValue)

func labelText(v):
	if absf(v - round(v)) < 0.0001:
		return "%d" % int(round(v))
	return Common.sig(v, 4)

func needleAngle(v):
	var f = clamp((v - minValue) / (maxValue - minValue), 0.0, 1.0)
	return lerp(minNeedleAngle, maxNeedleAngle, f)

func setDemand(v):
	if not is_node_ready():
		return
	demNeedle.rotation_degrees.x = needleAngle(v)

func setActual(v):
	if not is_node_ready():
		return
	actNeedle.rotation_degrees.x = needleAngle(v)

func refreshViews():
	if not is_node_ready():
		return
	unitLabel.text = unit
	ticks.queue_redraw()
	await get_tree().process_frame
	scaleView.render_target_update_mode = SubViewport.UPDATE_ONCE
	unitView.render_target_update_mode = SubViewport.UPDATE_ONCE

func drawTicks():
	var font = ticks.get_theme_default_font()
	if maxValue <= minValue or majorStep <= 0.0 or minorDivisions < 1:
		return
	var minorStep = majorStep / minorDivisions
	var count = int(floor((maxValue - minValue) / minorStep + 0.0001))
	for i in range(count + 1):
		var v = minValue + minorStep * i
		var y = valueToY(v)
		if i % minorDivisions == 0:
			ticks.draw_line(Vector2(tickBase - majorLen, y), Vector2(tickBase, y), Color.BLACK, majorWidth)
			var text = labelText(v)
			var w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize).x
			var h = font.get_ascent(tickFontSize) - font.get_descent(tickFontSize)
			ticks.draw_string(font, Vector2(tickBase - majorLen - 6 - w, (y + h / 2) + 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fontSize, Color.BLACK)
		else:
			ticks.draw_line(Vector2(tickBase - minorLen, y), Vector2(tickBase, y), Color.BLACK, minorWidth)
