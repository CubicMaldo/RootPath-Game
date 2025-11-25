extends Resource
class_name EmailDatabase

## Base de datos de correos electrónicos para el minijuego Email Phishing Detector

@export var emails: Array[EmailResource] = []

func get_all_emails() -> Array[EmailResource]:
	return emails

func get_shuffled_emails() -> Array[EmailResource]:
	var shuffled = emails.duplicate()
	shuffled.shuffle()
	return shuffled
