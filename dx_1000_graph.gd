extends ColorRect

var points: int
var lo: float
var hi: float
var channels: Array[DXChannel] = []
var pens: Array = []
var history: Array = []

func setup(chs: Array[DXChannel], every: float, minutes: float, a: float, b: float):
	channels = chs
	lo = a
	hi = b
	points = int(minutes * 60.0 / every)
	pens.clear()
	var n = 1
	while has_node(str(n)):
		pens.append(get_node(str(n)))
		n += 1
	history.clear()
	for i in pens.size():
		history.append([])
			
func push(i: int, v: float):
	if i >= pens.size():
		return
	var h = history[i]
	h.append(v)
	if h.size() > points:
		h.pop_front()
	var pts = PackedVector2Array()
	for k in h.size():
		var x = size.x * clamp(inverse_lerp(lo, hi, h[k]), 0.0, 1.0)
		var y = size.y * (h.size() - 1 - k) / float(points - 1)
		pts.append(Vector2(round(x), round(y)))
	pens[i].points = pts
