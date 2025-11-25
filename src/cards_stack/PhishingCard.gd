extends Resource
class_name PhishingCard

## Representa una carta de email que puede ser phishing o legítima

@export_group("Visual")
@export var icon: Texture2D  # Opcional: icono del remitente
@export var card_color: Color = Color.WHITE
@export var card_title: String = "Email Sin Título"
@export_multiline var subject: String = ""



@export_group("Email Content")
@export var sender_name: String = ""
@export var sender_email: String = ""
@export_multiline var email_body: String = ""
@export var has_attachments: bool = false
@export var attachment_names: Array[String] = []

@export_group("Game Logic")
@export var is_phishing: bool = false
@export_enum("Fácil:1", "Normal:2", "Difícil:3", "Experto:4") var difficulty: int = 1
@export var points_correct: int = 100
@export var points_incorrect: int = -50

@export_group("Educational")
@export var phishing_indicators: Array[String] = []  # Señales de phishing
@export_multiline var explanation: String = ""  # Explicación después de responder
@export var tips: Array[String] = []  # Tips educativos

@export_group("Metadata")
@export var card_id: String = ""  # ID único para tracking
@export var category: String = "general"  # banking, social_media, work, etc.

func get_formatted_email() -> String:
	var formatted = ""
	formatted += "De: %s <%s>\n" % [sender_name, sender_email]
	formatted += "Asunto: %s\n\n" % subject
	formatted += email_body
	if has_attachments and not attachment_names.is_empty():
		formatted += "\n\n📎 Adjuntos: " + ", ".join(attachment_names)
	return formatted
