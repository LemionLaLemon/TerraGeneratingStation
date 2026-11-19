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

var expr = Expression.new()
var shown: float = NAN
var response: float = 4.0 # response time

@export var expression: String = "":
	set(v):
		expression = v
		expr.parse(expression)
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
@export var previewValue: float = 10.0:
	set(v):
		previewValue = v
		setValue(v)

@onready var needle = $Needle
@onready var scaleView = $ScaleView
@onready var unitView = $UnitView
@onready var ticks = $ScaleView/Ticks
@onready var unitLabel = $UnitView/Label

func _ready():
	ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not ticks.draw.is_connected(drawTicks):
		ticks.draw.connect(drawTicks)
	unitLabel.add_theme_font_size_override("font_size", fontSize)
	expr.parse(expression)
	refreshViews()
	setValue(previewValue)

func _process(dt):
	if Engine.is_editor_hint():
		return
	var v = expr.execute([], Plant)
	if expr.has_execute_failed() or not (v is float or v is int):
		return
	shown = v if is_nan(shown) else lerp(shown, float(v), 1.0 - exp(-response * dt))
	setValue(shown)

func valueToY(v):
	return tickStart - (tickStart - tickEnd) * (v - minValue) / (maxValue - minValue)

func labelText(v):
	if absf(v - round(v)) < 0.0001:
		return "%d" % int(round(v))
	return Common.sig(v, 4)

func setValue(v):
	if not is_node_ready():
		return
	var f = clamp((v - minValue) / (maxValue - minValue), 0.0, 1.0)
	needle.rotation_degrees.x = lerp(minNeedleAngle, maxNeedleAngle, f)
	
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
