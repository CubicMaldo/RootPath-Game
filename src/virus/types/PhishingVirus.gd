extends BaseVirus

## Phishing Virus: Ingeniería Social
## El jugador debe identificar el botón correcto entre imitaciones

@onready var buttons_container = $CenterContainer/VBoxContainer/ButtonsContainer
@onready var timer_bar = $CenterContainer/VBoxContainer/TimerBar
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

var time_limit: float = 8.0
var current_time: float = 0.0
var is_active: bool = false

const CORRECT_TEXT = "Restaurar Sistema"
const FAKE_TEXTS = [
	"Restaura Sistema",
	"Restaurar Sístema",
	"Restaurar Systema",
	"Restaurar  Sistema",
	"Restaur4r Sistema",
	"Restaurar Sistem4",
	"Restaurar_Sistema",
	"Restaurar.Sistema"
]

func start_infection() -> void:
	time_limit = get_config_value("time_limit", time_limit)
	is_active = true
	current_time = 0.0
	_setup_buttons()
	set_process(true)

func _process(delta):
	if not is_active:
		return
		
	current_time += delta
	timer_bar.value = ((time_limit - current_time) / time_limit) * 100.0
	
	if current_time >= time_limit:
		_fail_virus()

func _setup_buttons():
	for child in buttons_container.get_children():
		child.queue_free()
	
	var options = []
	
	# Añadir opción correcta
	var correct_btn = _create_button(CORRECT_TEXT, true)
	options.append(correct_btn)
	
	# Añadir opciones falsas (3 a 5)
	var num_fakes = randi_range(3, 5)
	var fakes_shuffled = FAKE_TEXTS.duplicate()
	fakes_shuffled.shuffle()
	
	for i in range(num_fakes):
		var fake_text = fakes_shuffled[i]
		var fake_btn = _create_button(fake_text, false)
		options.append(fake_btn)
	
	# Barajar botones en el contenedor
	options.shuffle()
	for btn in options:
		buttons_container.add_child(btn)

func _create_button(text: String, is_correct: bool) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 50)
	btn.add_theme_font_size_override("font_size", 18)
	
	# Conectar señal con variable extra usando bind
	btn.pressed.connect(_on_button_pressed.bind(is_correct, btn))
	
	return btn

func _on_button_pressed(is_correct: bool, btn: Button):
	if not is_active:
		return
		
	is_active = false
	
	if is_correct:
		btn.modulate = Color(0, 1, 0)
		_complete_virus()
	else:
		btn.modulate = Color(1, 0, 0)
		_fail_virus()

func _complete_virus():
	status_label.text = "AUTENTICACIÓN EXITOSA"
	status_label.modulate = Color(0, 1, 0)
	await get_tree().create_timer(1.0).timeout
	_on_virus_cleared()

func _fail_virus():
	status_label.text = "CREDENCIALES INVÁLIDAS"
	status_label.modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	_on_virus_failed()
	start_infection() # Reiniciar
