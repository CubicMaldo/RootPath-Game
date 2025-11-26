extends BaseVirus

## Adware Virus: Cerrar ventanas
## El jugador debe cerrar todas las ventanas antes de que se multipliquen

const POPUP_SCENE = preload("res://src/virus/components/PopUpWindow.tscn")

@onready var windows_container = $WindowsContainer
@onready var count_label = $UI/CountLabel

var active_windows: int = 0
var max_windows: int = 15
var initial_windows: int = 5

func _ready():
	return
	#start_infection()

func start_infection() -> void:
	# Limpiar
	for child in windows_container.get_children():
		child.queue_free()
	
	active_windows = 0
	
	# Spawn inicial
	for i in range(initial_windows):
		_spawn_popup()
		
	_update_ui()

func _spawn_popup():
	if active_windows >= max_windows:
		_fail_virus()
		return
		
	var popup = POPUP_SCENE.instantiate()
	windows_container.add_child(popup)
	
	# Posición aleatoria dentro del área visible (asumiendo 1280x720 base, ajustar según viewport)
	var viewport_size = get_viewport_rect().size
	var x = randf_range(50, viewport_size.x - 250)
	var y = randf_range(50, viewport_size.y - 200)
	popup.position = Vector2(x, y)
	
	# Conectar señales
	popup.closed.connect(_on_popup_closed)
	popup.duplicate_requested.connect(_on_popup_duplicate)
	
	active_windows += 1
	_update_ui()

func _on_popup_closed():
	active_windows -= 1
	_update_ui()
	
	if active_windows <= 0:
		_complete_virus()

func _on_popup_duplicate():
	# Probabilidad de duplicarse (100% por ahora para ser molesto)
	_spawn_popup()

func _update_ui():
	count_label.text = "Amenazas activas: %d / %d" % [active_windows, max_windows]
	if active_windows > max_windows * 0.8:
		count_label.modulate = Color(1, 0, 0)
	else:
		count_label.modulate = Color(1, 1, 1)

func _complete_virus():
	count_label.text = "SISTEMA LIMPIO"
	count_label.modulate = Color(0, 1, 0)
	await get_tree().create_timer(1.0).timeout
	_on_virus_cleared()

func _fail_virus():
	count_label.text = "DESBORDAMIENTO DE MEMORIA"
	_on_virus_failed()
	queue_free()
