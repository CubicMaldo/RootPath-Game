extends Resource
class_name PortScanDatabase

## Base de datos de actividades de red para el minijuego Port Scanner Defender

@export var scans: Array[PortScanResource] = []

func get_all_scans() -> Array[PortScanResource]:
	return scans

func get_shuffled_scans() -> Array[PortScanResource]:
	var shuffled = scans.duplicate()
	shuffled.shuffle()
	return shuffled
