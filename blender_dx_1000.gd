extends CSGBox3D

var t: float = 0

func _process(dt):
	t += dt
	if t>= 0.5:
		t = 0
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/BN_B_WEIGHT").text = "%.2f" % Plant.BananaBlender.total_mass()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/BN_B_RPM").text = "%d" % Plant.BananaBlender.getRpm()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/PL_TK_WEIGHT").text = "%.2f" % Plant.PulpTank.total_mass()
