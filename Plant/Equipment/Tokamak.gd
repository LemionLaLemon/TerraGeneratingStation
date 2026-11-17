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

func _init(Elevation, Temperature, RatedPressure = Units.PsitoPa(1080), Contents = {}):
	super(Elevation, Temperature, RatedPressure, MeasuredVolume, Contents)
	ratedPressure = RatedPressure
