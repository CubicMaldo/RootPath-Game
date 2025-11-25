extends Resource
class_name EmailResource

## Recurso que representa un correo electrónico en el minijuego Email Phishing Detector

@export var sender_email: String = ""
@export var sender_name: String = ""
@export var subject: String = ""
@export_multiline var body: String = ""
@export var has_link: bool = false
@export var link_url: String = ""
@export var is_phishing: bool = false
@export var phishing_type: String = ""
@export_multiline var explanation: String = ""
@export_multiline var hint: String = ""

func get_display_sender() -> String:
	return "%s <%s>" % [sender_name, sender_email]

func get_red_flags() -> Array[String]:
	var flags: Array[String] = []
	
	if is_phishing:
		if sender_email.contains("@") and not sender_email.ends_with(".com") and not sender_email.ends_with(".org") and not sender_email.ends_with(".net"):
			flags.append("Dominio sospechoso")
		if subject.contains("URGENTE") or subject.contains("IMPORTANTE") or subject.contains("¡"):
			flags.append("Lenguaje urgente")
		if body.contains("haga clic") or body.contains("verificar cuenta") or body.contains("premio"):
			flags.append("Solicita acción inmediata")
		if has_link and (link_url.contains("bit.ly") or link_url.contains("tinyurl") or not link_url.begins_with("https://")):
			flags.append("Enlace sospechoso")
	
	return flags
