extends BaseVirus

## Glitch Virus: Ordenar fragmentos
## El jugador debe ordenar los bloques numéricos/de color

@onready var slots_container = $CenterContainer/VBoxContainer/SlotsContainer
@onready var timer_bar = $CenterContainer/VBoxContainer/TimerBar
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

var total_fragments: int = 5
var time_limit: float = 15.0
var current_time: float = 0.0
var is_active: bool = false

func _ready():
	# No llamar start_infection() aquí
	# El VirusController lo llamará después de añadir el virus al árbol
	pass

func start_infection() -> void:
	time_limit = get_config_value("time_limit", time_limit)
	total_fragments = int(get_config_value("total_fragments", total_fragments))
	is_active = true
	current_time = 0.0
	_setup_puzzle()
	set_process(true)

func _process(delta):
	if not is_active:
		return
		
	current_time += delta
	timer_bar.value = (current_time / time_limit) * 100.0
	
	if current_time >= time_limit:
		_fail_virus()

func _setup_puzzle():
	# Limpiar slots existentes
	for child in slots_container.get_children():
		child.queue_free()
	
	# Crear slots
	var fragments = []
	for i in range(total_fragments):
		var slot = VirusSlot.new()
		slot.custom_minimum_size = Vector2(64, 64)
		slot.item_dropped.connect(_check_solution)
		slots_container.add_child(slot)
		
		# Crear fragmento
		var fragment = VirusDraggable.new()
		fragment.id = i
		fragment.custom_minimum_size = Vector2(60, 60)
		fragment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Usar un color o textura placeholder
		var placeholder = GradientTexture2D.new()
		placeholder.width = 60
		placeholder.height = 60
		placeholder.fill = GradientTexture2D.FILL_SQUARE
		placeholder.fill_from = Vector2(0, 0)
		placeholder.fill_to = Vector2(1, 1)
		# Color basado en ID para que sea ordenable visualmente (Gradiente de rojo a verde)
		var color_val = float(i) / float(total_fragments - 1)
		var gradient = Gradient.new()
		gradient.set_color(0, Color(color_val, 0.2, 1.0 - color_val)) # Azul a Rojo
		gradient.set_color(1, Color(color_val + 0.2, 0.4, 1.0 - color_val))
		placeholder.gradient = gradient
		
		fragment.texture = placeholder
		
		# Añadir etiqueta de número para claridad
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		fragment.add_child(label)
		
		fragments.append(fragment)
	
	# Barajar fragmentos y asignarlos a slots
	fragments.shuffle()
	for i in range(total_fragments):
		slots_container.get_child(i).add_child(fragments[i])

func _check_solution():
	var correct_count = 0
	for i in range(total_fragments):
		var slot = slots_container.get_child(i)
		if slot.get_child_count() > 0:
			var fragment = slot.get_child(0)
			if fragment is VirusDraggable and fragment.id == i:
				correct_count += 1
	
	if correct_count == total_fragments:
		_complete_virus()

func _complete_virus():
	is_active = false
	status_label.text = "DESFRAGMENTACIÓN COMPLETADA"
	status_label.modulate = Color(0, 1, 0)
	await get_tree().create_timer(1.0).timeout
	_on_virus_cleared()

func _fail_virus():
	is_active = false
	status_label.text = "ERROR CRÍTICO - REINICIANDO"
	status_label.modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	_on_virus_failed()
	# Reiniciar puzzle
	start_infection()
