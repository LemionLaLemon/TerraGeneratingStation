extends Node3D

var tiles = []
var testing = false
var horn = false
var ringback = false
@onready var alarm = $Alarm
@onready var ringbackAlarm = $Ringback
@export var controls: Node3D

func _ready():
	tiles = get_children().filter(func(c): return c.has_method("update"))
	controls.ack.connect(ack)
	controls.reset.connect(reset)
	controls.test.connect(test)
	alarm.volume_db = -80.0
	alarm.play(fmod(Time.get_ticks_msec(), 500.0) / 1000.0)
	ringbackAlarm.volume_db = -80.0
	ringbackAlarm.play(fmod(Time.get_ticks_msec(), 800.0) / 1000.0)

func _process(dt):
	var ms = Time.get_ticks_msec()
	var fast = int(ms / 250) % 2 == 0
	var slow = int(ms / 500) % 2 == 0
	horn = false
	ringback = false
	for tile in tiles:
		tile.update()
		if tile.state == tile.States.Alarm:
			horn = true
		if tile.state == tile.States.Ringback:
			ringback = true
		tile.set_lit(tile.lit(fast, slow, testing))
	alarm.volume_db = 0.0 if horn else -80.0
	ringbackAlarm.volume_db = -12.5 if ringback else -80.0

func ack():
	for tile in tiles: 
		tile.ack()

func reset():
	for tile in tiles:
		tile.reset()

func test(on):
	testing = on
