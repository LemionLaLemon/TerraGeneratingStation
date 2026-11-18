extends Control

func refresh():
	var totalDt = 1.0 / Engine.physics_ticks_per_second * (32 if Plant.Accel32x.isClosed() else 1) * (64 if Plant.Accel64x.isClosed() else 1)
	$TIMESTEP.text = "%.4f" % totalDt
	$GRIDBO.text = "ACTIVE" if Plant.GridBO.isClosed() else "INACTIVE"
