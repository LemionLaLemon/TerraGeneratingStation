extends Node3D

var tiles = []
var testing = false
var horn = false
@onready var alarm = $Alarm
@export var controls: Node3D

func _ready():
	tiles = get_children().filter(func(c): return c.has_method("update"))
	controls.ack.connect(ack)
	controls.reset.connect(reset)
	controls.test.connect(test)

func _process(dt):
	var ms = Time.get_ticks_msec()
	var fast = int(ms / 250) % 2 == 0
	var slow = int(ms / 500) % 2 == 0
	horn = false
	for tile in tiles:
		tile.update()
		if tile.state == tile.States.Alarm:
			horn = true
		tile.set_lit(tile.lit(fast, slow, testing))
	if horn and not alarm.playing:
		alarm.play()
	elif not horn and alarm.playing:
		alarm.stop()

func ack():
	for tile in tiles: 
		tile.ack()

func reset():
	for tile in tiles:
		tile.reset()

func test(on):
	testing = on
