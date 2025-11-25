extends Resource
class_name ConnectionResource

## Recurso que representa una conexión de red en el minijuego Network Defender

@export var ip_address: String = ""
@export var port: int = 80
@export var protocol: String = "TCP"
@export var process_name: String = ""
@export var is_suspicious: bool = false
@export var reason: String = ""
@export_multiline var hint: String = ""

func get_connection_info() -> String:
	return "IP: %s | Puerto: %d | Protocolo: %s | Proceso: %s" % [ip_address, port, protocol, process_name]
