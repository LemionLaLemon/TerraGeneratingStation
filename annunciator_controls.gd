extends Node3D

signal ack
signal reset
signal test(on)

func _ready():
	$Acknowledge.pressed.connect(ack.emit)
	$Reset.pressed.connect(reset.emit)
	$Test.pressed.connect(test.emit.bind(true))
	$Test.released.connect(test.emit.bind(false))
