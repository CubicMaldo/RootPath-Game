extends Control

const RESPUESTA_CORRECTA = "phishing"

@onready var input_respuesta = $Panel/LineEdit
@onready var label_resultado = $Panel/VBoxContainer/ResultadoLabel
@onready var error_timer = $Panel/Timer

func _ready():
	label_resultado.text = ""


func _on_button_pressed() -> void:
	var respuesta = input_respuesta.text.strip_edges().to_lower()
	
	if respuesta == RESPUESTA_CORRECTA:
		label_resultado.text = "¡Correcto! 🎉"
		label_resultado.add_theme_color_override("font_color", Color(0, 1, 0)) # verde
		emit_signal("adivinanza_completada") # usar para avanzar en el árbol
	else:
		label_resultado.text = "Incorrecto 😅, inténtalo de nuevo."
		label_resultado.add_theme_color_override("font_color", Color(1, 0, 0)) # rojo
		error_timer.start()

	   


func _on_timer_timeout() -> void:
		label_resultado.text = "" 
		label_resultado.remove_theme_color_override("font_color") 
