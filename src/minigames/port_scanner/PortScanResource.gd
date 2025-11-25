extends Resource
class_name PortScanResource

## Recurso que representa una actividad de red en el minijuego Port Scanner Defender

@export var source_ip: String = ""
@export var target_port: int = 0
@export var protocol: String = ""
@export var scan_type: String = ""
@export var packet_count: int = 0
@export var time_span: String = ""
@export_multiline var description: String = ""
@export var is_malicious: bool = false
@export var threat_type: String = ""
@export_multiline var explanation: String = ""
@export_multiline var hint: String = ""

func get_display_info() -> String:
	return "IP: %s → Puerto: %d (%s)" % [source_ip, target_port, protocol]

func get_port_name() -> String:
	match target_port:
		21: return "FTP"
		22: return "SSH"
		23: return "Telnet"
		25: return "SMTP"
		53: return "DNS"
		80: return "HTTP"
		110: return "POP3"
		143: return "IMAP"
		443: return "HTTPS"
		445: return "SMB"
		3306: return "MySQL"
		3389: return "RDP"
		5432: return "PostgreSQL"
		8080: return "HTTP-Alt"
		_: return "Desconocido"

func get_risk_indicators() -> Array[String]:
	var indicators: Array[String] = []
	
	if is_malicious:
		if packet_count > 100:
			indicators.append("Alto volumen de paquetes")
		if scan_type.contains("SYN") or scan_type.contains("stealth"):
			indicators.append("Escaneo sigiloso detectado")
		if time_span.contains("segundo"):
			indicators.append("Velocidad de escaneo sospechosa")
		if target_port in [23, 445, 3389]:
			indicators.append("Puerto de alto riesgo")
		if source_ip.contains("unknown") or source_ip.contains("spoofed"):
			indicators.append("Origen sospechoso")
	
	return indicators
