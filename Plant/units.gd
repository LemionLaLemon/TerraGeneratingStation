class_name Units
extends RefCounted

static func KtoC(K):
	return K - 273.15

static func CtoK(C):
	return C + 273.15

static func PatoPsi(Pa):
	return Pa / 6895

static func PsitoPa(Psi):
	return Psi * 6895

static func PatokPa(Pa):
	return Pa / 1000

static func kPatoPa(kPa):
	return kPa * 1000
