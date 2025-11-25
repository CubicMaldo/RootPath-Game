extends Resource
class_name PhishingCard

## Representa una carta de notificación que puede ser phishing o legítima

@export_group("Visual")
@export var icon: Texture2D # Opcional: icono de la aplicación
@export var card_color: Color = Color.WHITE
@export var card_title: String = "Notificación Sin Título"
@export_multiline var notification_title: String = ""


@export_group("Notification Content")
@export var app_name: String = ""
@export var app_identifier: String = "" # com.example.app o nombre técnico
@export_multiline var notification_message: String = ""
@export var has_action_buttons: bool = false
@export var action_button_labels: Array[String] = []

@export_group("Game Logic")
@export var is_phishing: bool = false
@export_enum("Fácil:1", "Normal:2", "Difícil:3", "Experto:4") var difficulty: int = 1
@export var points_correct: int = 100
@export var points_incorrect: int = -50

@export_group("Educational")
@export var phishing_indicators: Array[String] = [] # Señales de phishing
@export_multiline var explanation: String = "" # Explicación después de responder
@export var tips: Array[String] = [] # Tips educativos

@export_group("Metadata")
@export var card_id: String = "" # ID único para tracking
@export var category: String = "general" # banking, social_media, work, system, etc.

func get_formatted_notification() -> String:
	var formatted = ""
	formatted += "📱 %s\n" % app_name
	if not app_identifier.is_empty():
		formatted += "   (%s)\n" % app_identifier
	formatted += "\n%s\n\n" % notification_title
	formatted += notification_message
	if has_action_buttons and not action_button_labels.is_empty():
		formatted += "\n\n� Acciones: " + ", ".join(action_button_labels)
	return formatted
