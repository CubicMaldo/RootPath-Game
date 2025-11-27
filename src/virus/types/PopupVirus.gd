extends BaseVirus

# Configuración
@export var popup_count: int = 5
@export var time_limit: float = 15.0
@export var spawn_area: Rect2 = Rect2(100, 100, 800, 500)

# Estado
var active_popups: int = 0
var time_left: float = 0.0
var is_active: bool = false

# Referencias
@onready var timer: Timer = $Timer
@onready var popups_container: Control = $PopupsContainer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Recursos
var popup_texture = preload("res://icon.svg") # Placeholder, debería ser una textura de alerta

func _ready() -> void:
	hide()
	timer.wait_time = time_limit
	timer.timeout.connect(_on_timer_timeout)

func start_infection() -> void:
	time_limit = get_config_value("time_limit", time_limit)
	popup_count = int(get_config_value("popup_count", popup_count))
	timer.wait_time = time_limit
	show()
	is_active = true
	active_popups = 0
	time_left = time_limit
	timer.start()
	
	# Limpiar contenedores previos
	for child in popups_container.get_children():
		child.queue_free()
	
	# Spawnear popups iniciales
	for i in range(popup_count):
		_spawn_popup()
	
	# Reproducir sonido de alerta
	if audio_player.stream:
		audio_player.play()

func _spawn_popup() -> void:
	var popup = Button.new()
	popup.text = "ERROR CRÍTICO\nHAZ CLICK PARA CERRAR"
	popup.icon = popup_texture
	popup.custom_minimum_size = Vector2(200, 100)
	
	# Posición aleatoria
	var x = randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x)
	var y = randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	popup.position = Vector2(x, y)
	
	# Conectar señal de cierre
	popup.pressed.connect(_on_popup_closed.bind(popup))
	
	popups_container.add_child(popup)
	active_popups += 1
	
	# Animación de entrada (Tween)
	popup.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(popup, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_popup_closed(popup: Button) -> void:
	popup.queue_free()
	active_popups -= 1
	
	# Efecto de sonido al cerrar (opcional)
	
	if active_popups <= 0:
		_complete_infection()
	else:
		# Posibilidad de spawnear uno nuevo al cerrar (para más caos)
		if randf() < 0.2:
			_spawn_popup()

func _complete_infection() -> void:
	is_active = false
	timer.stop()
	_on_virus_cleared()

func _on_timer_timeout() -> void:
	if is_active:
		_on_virus_failed()
		# No cerramos automáticamente, dejamos que el VirusController decida
