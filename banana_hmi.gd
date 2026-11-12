extends CSGBox3D

var t: float = 0

func _process(dt):
	t += dt
	if t>= 0.5:
		t = 0
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/BN_H_WEIGHT").text = "%.2f" % Plant.BananaHopper.total_mass()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/BN_C_RATE").text = "%.2f" % Plant.BananaConveyor.speed()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/BN_B_WEIGHT").text = "%.2f" % Plant.BananaBlender.total_mass()
