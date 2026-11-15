extends Node3D

@export var channels: Array[DXChannel] = []
@export var dx_ID: String = "GROUP 1"
@export var updateEvery: float = 0.5 # seconds
@export var chart_min: float = 0.0
@export var chart_max: float = 100.0
@export var window_minutes: float = 10.0
@onready var screen = self.get_node("SubViewport/Screen/Values")
@onready var paperLabel = self.get_node("PaperLabel")
var exprs = []
var base

var t: float = 0
var t2: float = 0

func _ready():
	base = Plant
	for i in screen.get_child_count():
		var node = screen.get_child(i)
		var c = channels[i] if i < channels.size() else null
		exprs.append(null)
		node.visible = c != null and c.expression != ""
		if not node.visible:
			continue
		var e = Expression.new()
		if e.parse(c.expression, ["Units"]) != OK:
			push_error(e.get_error_text())
			node.visible = false
			continue
		exprs[i] = e
		node.get_node("Label").text = c.label_text
		node.get_node("Unit").text = c.unit_text
	for i in paperLabel.get_child_count():
		var node = paperLabel.get_child(i)
		var c = channels[i] if i < channels.size() else null
		if c == null:
			node.visible = false
			continue
		node.text = c.paper_label_text
	$SubViewport/Screen/Graph.setup(channels, updateEvery, window_minutes, chart_min, chart_max)
	$SubViewport/Screen/Scale.set_range(chart_min, chart_max)
	for i in screen.get_child_count():
		$SubViewport/Screen/Scale.get_node(str(i + 1)).visible = exprs[i] != null
	$SubViewport/Screen/Top/ID.text = dx_ID

func _process(_dt):
	t += _dt
	t2 += _dt
	if t2 >= 1:
		t2 = 0
		var d = Time.get_datetime_dict_from_system()
		$SubViewport/Screen/Top/TIME.text = "%04d/%02d/%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
	if t>=updateEvery:
		t = 0
		for i in exprs.size():
			if exprs[i] == null:
				continue
			var c = channels[i]
			var v = exprs[i].execute([Units], base)
			screen.get_child(i).get_node("Value").text = "-" if exprs[i].has_execute_failed() else c.format % (v + c.offset)
			$SubViewport/Screen/Graph.push(i, v + c.offset)
			$SubViewport/Screen/Scale.set_cursor(i, v + c.offset)
