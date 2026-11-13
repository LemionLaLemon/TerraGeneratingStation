extends Node3D

@export var channels: Array[DXChannel] = []
@export var updateEvery: float = 0.5 # seconds

@onready var screen = self.get_node("SubViewport/Screen")
var exprs = []
var base

var t: float = 0

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
		if e.parse(c.expression) != OK:
			push_error(e.get_error_text())
			node.visible = false
			continue
		exprs[i] = e
		node.get_node("Label").text = c.label_text
		node.get_node("Unit").text = c.unit_text

func _process(_dt):
	t += _dt
	if t>=updateEvery:
		t = 0
		for i in exprs.size():
			if exprs[i] == null:
				continue
			var c = channels[i]
			var v = exprs[i].execute([], base)
			screen.get_child(i).get_node("Value").text = "----" if exprs[i].has_execute_failed() else c.format % (v + c.offset)
