extends CSGBox3D

var t: float = 0

func _process(dt):
	t += dt
	if t>= 0.5:
		t = 0
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/ST_TK_WEIGHT").text = "%.2f" % Plant.PulpStill.total_mass()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/PL_ST_TEMPERATURE").text = "%.1f" % Units.KtoC(Plant.PulpStill.getTemperature())
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/SL_TK_WEIGHT").text = "%.2f" % Plant.SludgeTank.total_mass()
		self.get_node("SubViewport/CenterContainer/Panel2/Panel3/COND_TK_WEIGHT").text = "%.2f" % Plant.WaterTank.total_mass()
