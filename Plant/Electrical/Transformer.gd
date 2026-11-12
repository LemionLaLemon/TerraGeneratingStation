class_name Transformer
extends ElectricalLink

func _init(from, to, source_voltage: float, output_voltage: float):
	super(from, to)
	ratio = output_voltage / source_voltage
