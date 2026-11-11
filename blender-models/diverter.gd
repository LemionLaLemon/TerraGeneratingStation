extends Node3D

@onready var tokamak = self
var domes = []
var insideTargets = []
var outsideTargets = []

func _ready():
	for item in tokamak.get_children():
		if item.name.begins_with("Dome"):
			domes.append(item)
			
		if item.name.begins_with("Inner"):
			insideTargets.append(item)
			
		if item.name.begins_with("Outer"):
			outsideTargets.append(item)
