extends BaseVirus

class_name SurveyVirus

## Virus que presenta encuestas engañosas para recopilar información

@onready var question_label = $VBoxContainer/QuestionLabel
@onready var options_container = $VBoxContainer/OptionsContainer
@onready var submit_button = $VBoxContainer/SubmitButton
@onready var progress_label = $VBoxContainer/ProgressLabel

var current_question_index: int = 0
var selected_answer: int = -1

const SURVEY_QUESTIONS = [
	{
		"question": "¿Cuál es tu red social favorita?",
		"options": ["Facebook", "Instagram", "Twitter", "Prefiero no responder"],
		"safe_answer": 3
	},
	{
		"question": "¿Cuál es el nombre de tu primera mascota?",
		"options": ["Rex", "Michi", "Luna", "No tengo/No lo recuerdo"],
		"safe_answer": 3
	},
	{
		"question": "¿En qué ciudad naciste?",
		"options": ["Madrid", "Buenos Aires", "México", "Prefiero no decirlo"],
		"safe_answer": 3
	},
	{
		"question": "¿Cuál es tu número de teléfono?",
		"options": ["555-1234", "555-5678", "555-9999", "No quiero compartirlo"],
		"safe_answer": 3
	}
]

func _ready():
	submit_button.pressed.connect(_on_submit_pressed)

func start_infection() -> void:
	current_question_index = 0
	_show_question()

func _show_question():
	if current_question_index >= SURVEY_QUESTIONS.size():
		_complete_survey()
		return
	
	var question_data = SURVEY_QUESTIONS[current_question_index]
	question_label.text = question_data.question
	progress_label.text = "Pregunta %d / %d" % [current_question_index + 1, SURVEY_QUESTIONS.size()]
	
	# Limpiar opciones anteriores
	for child in options_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear opciones
	selected_answer = -1
	submit_button.disabled = true
	
	for i in range(question_data.options.size()):
		var radio_button = CheckButton.new()
		radio_button.text = question_data.options[i]
		radio_button.button_group = ButtonGroup.new() if i == 0 else options_container.get_child(0).button_group
		radio_button.toggled.connect(_on_option_toggled.bind(i))
		options_container.add_child(radio_button)

func _on_option_toggled(toggled_on: bool, option_index: int):
	if toggled_on:
		selected_answer = option_index
		submit_button.disabled = false

func _on_submit_pressed():
	var question_data = SURVEY_QUESTIONS[current_question_index]
	
	if selected_answer == question_data.safe_answer:
		# Respuesta segura
		current_question_index += 1
		_show_question()
	else:
		# Respuesta insegura - compartió información personal
		question_label.text = "❌ ¡DATOS PERSONALES COMPROMETIDOS!"
		question_label.modulate = Color(1, 0, 0)
		progress_label.text = "Nunca compartas información personal en encuestas sospechosas"
		await get_tree().create_timer(2.0).timeout
		_on_virus_failed()

func _complete_survey():
	question_label.text = "✅ ENCUESTA RECHAZADA CORRECTAMENTE"
	question_label.modulate = Color(0, 1, 0)
	progress_label.text = "¡Bien hecho! Protegiste tu información personal"
	submit_button.visible = false
	await get_tree().create_timer(2.0).timeout
	_on_virus_cleared()
