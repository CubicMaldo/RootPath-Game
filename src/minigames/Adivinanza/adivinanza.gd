extends Control

signal adivinanza_completada

@onready var input_respuesta = $Panel/LineEdit
@onready var label_pregunta = $Panel/VBoxContainer/PreguntaLabel
@onready var label_resultado = $Panel/VBoxContainer/ResultadoLabel
@onready var error_timer = $Panel/Timer

var current_riddle: Dictionary = {}
var riddle_database = RiddleDatabase.new()

func _ready():
	label_resultado.text = ""
	_load_new_riddle()
	
	# Integración inicial con Clippy
	if Global.has_singleton("ClippyBridge"):
		# Esperar un poco para que la UI cargue
		await get_tree().create_timer(0.5).timeout
		Global.ClippyBridge.notify_clippy("¡Hola! Resuelve este acertijo de seguridad para continuar. Escribe tu respuesta en la caja.", "tutorial")

func _load_new_riddle():
	current_riddle = riddle_database.get_random_riddle()
	if label_pregunta:
		label_pregunta.text = current_riddle["question"]
	input_respuesta.text = ""

func _on_button_pressed() -> void:
	var respuesta_usuario = input_respuesta.text.strip_edges().to_lower()
	# Normalizar respuesta (quitar acentos si es necesario, aunque simple por ahora)
	
	if respuesta_usuario == current_riddle["answer"]:
		_handle_correct_answer()
	else:
		_handle_incorrect_answer()

func _handle_correct_answer():
	label_resultado.text = "¡Correcto! 🎉"
	label_resultado.add_theme_color_override("font_color", Color(0, 1, 0)) # verde
	
	if Global.has_singleton("ClippyBridge"):
		Global.ClippyBridge.notify_clippy("¡Excelente! Has descifrado el código.", "success")
	
	emit_signal("adivinanza_completada")

func _handle_incorrect_answer():
	label_resultado.text = "Incorrecto 😅"
	label_resultado.add_theme_color_override("font_color", Color(1, 0, 0)) # rojo
	error_timer.start()
	
	if Global.has_singleton("ClippyBridge"):
		Global.ClippyBridge.notify_clippy("Mmm, no es eso. " + current_riddle["hint"], "hint")

func _on_timer_timeout() -> void:
	label_resultado.text = ""
	label_resultado.remove_theme_color_override("font_color")
