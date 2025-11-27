extends BaseVirus

class_name CaptchaVirus

## Virus que presenta CAPTCHAs imposibles o engañosos

@onready var image_container = $VBoxContainer/ImageContainer
@onready var instruction_label = $VBoxContainer/InstructionLabel
@onready var grid = $VBoxContainer/GridContainer
@onready var verify_button = $VBoxContainer/VerifyButton
@onready var attempt_label = $VBoxContainer/AttemptLabel

var correct_indices: Array[int] = []
var selected_indices: Array[int] = []
var max_attempts: int = 3
var current_attempts: int = 0

const CAPTCHA_CHALLENGES = [
	{
		"instruction": "Selecciona todas las imágenes con [b]semáforos[/b]",
		"correct": [1, 4, 7],
		"decoy_text": "(Incluye señales de stop)"
	},
	{
		"instruction": "Selecciona todas las imágenes con [b]bicicletas[/b]",
		"correct": [0, 3, 8],
		"decoy_text": "(Salta si no hay)"
	},
	{
		"instruction": "Selecciona todas las imágenes con [b]autobuses[/b]",
		"correct": [2, 5],
		"decoy_text": "(El reflejo del autobús cuenta)"
	}
]

func _ready():
	verify_button.pressed.connect(_on_verify_pressed)

func start_infection() -> void:
	max_attempts = int(get_config_value("max_attempts", max_attempts))
	current_attempts = 0
	_setup_new_challenge()

func _setup_new_challenge():
	selected_indices.clear()
	
	# Limpiar grid anterior
	for child in grid.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Seleccionar desafío aleatorio
	var challenge = CAPTCHA_CHALLENGES.pick_random()
	correct_indices.assign(challenge.correct)
	instruction_label.text = challenge.instruction + "\n[color=#888888]%s[/color]" % challenge.decoy_text
	
	# Crear 9 casillas
	for i in range(9):
		var button = Button.new()
		button.custom_minimum_size = Vector2(80, 80)
		button.text = str(i + 1)
		button.toggle_mode = true
		button.pressed.connect(_on_tile_toggled.bind(i, button))
		grid.add_child(button)
	
	_update_attempt_label()

func _on_tile_toggled(index: int, button: Button):
	if button.button_pressed:
		if not selected_indices.has(index):
			selected_indices.append(index)
	else:
		selected_indices.erase(index)

func _on_verify_pressed():
	current_attempts += 1
	
	# Verificar si es correcto
	var is_correct = _check_answer()
	
	if is_correct:
		instruction_label.text = "✅ CAPTCHA RESUELTO"
		instruction_label.modulate = Color(0, 1, 0)
		await get_tree().create_timer(1.0).timeout
		_on_virus_cleared()
	else:
		if current_attempts >= max_attempts:
			instruction_label.text = "❌ DEMASIADOS INTENTOS FALLIDOS"
			instruction_label.modulate = Color(1, 0, 0)
			await get_tree().create_timer(1.0).timeout
			_on_virus_failed()
		else:
			instruction_label.text = "❌ Incorrecto. Intenta de nuevo."
			instruction_label.modulate = Color(1, 0.5, 0)
			await get_tree().create_timer(1.5).timeout
			_setup_new_challenge()

func _check_answer() -> bool:
	if selected_indices.size() != correct_indices.size():
		return false
	
	for idx in correct_indices:
		if not selected_indices.has(idx):
			return false
	
	return true

func _update_attempt_label():
	attempt_label.text = "Intentos: %d / %d" % [current_attempts, max_attempts]
