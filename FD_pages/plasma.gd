extends Control

func refresh():
	$PLASMACURRENT.text = Common.sig(Plant.TerraTokamak.plasmaCurrent / 1e6, 4)
	$PLASMAQ95.text = Common.sig(Plant.TerraTokamak.plasmaQ95, 3)
	$PLASMASHIFT.text = Common.sig(Plant.TerraTokamak.plasmaShift, 3)
	$PLASMATEMPERATURE.text = Common.sig(Plant.TerraTokamak.plasmaTemp/1000, 7)
	$VESSELPRESSURE.text = Common.sig(Plant.TerraTokamak.pressureMPa, 6)
	var t = int(Plant.TerraTokamak.plasmaTime)
	$PLASMATIME.text = "%02dH %02dM %02dS" % [(t / 60) / 60, t / 60,  t % 60]
	var lt = int(Plant.TerraTokamak.lastPulse)
	$LASTSHOTTIME.text = "%02dH %02dM %02dS" % [(lt / 60) / 60, lt / 60,  lt % 60]
