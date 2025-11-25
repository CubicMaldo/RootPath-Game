extends Control

## Minijuego de ciberseguridad: Network Defender
## El jugador debe identificar y bloquear conexiones de red sospechosas

@export var level_database: NetworkLevelDatabase
@export_range(0, 100, 1) var max_easy_connections: int = 5
@export_range(0, 100, 1) var max_medium_connections: int = 5
@export_range(0, 100, 1) var max_hard_connections: int = 5

const DIFFICULTY_ORDER: Array[String] = ["easy", "medium", "hard"]
const DIFFICULTY_LABELS := {
	"easy": "Fácil",
	"medium": "Medio",
	"hard": "Difícil",
}

static var _persistent_level_index: int = 0

var connections: Array[ConnectionResource] = []
var active_difficulties: Array[String] = []
var _rng := RandomNumberGenerator.new()

var current_level_index: int = 0
var current_difficulty: String = "easy"
var total_levels: int = 0

@onready var connection_info_label = $Panel/VBoxContainer/ConnectionInfoContainer/ConnectionInfoLabel
@onready var hint_label = $Panel/VBoxContainer/HintContainer/HintLabel
@onready var resultado_label = $Panel/VBoxContainer/ResultadoLabel
@onready var vidas_label = $Panel/VBoxContainer/TopBar/VidasLabel
@onready var puntos_label = $Panel/VBoxContainer/TopBar/PuntosLabel
@onready var nivel_label = $Panel/VBoxContainer/TopBar/NivelLabel
@onready var tiempo_label = $Panel/VBoxContainer/TopBar/TiempoLabel
@onready var btn_permitir = $Panel/VBoxContainer/ButtonsContainer/BtnPermitir
@onready var btn_bloquear = $Panel/VBoxContainer/ButtonsContainer/BtnBloquear
@onready var btn_pista = $Panel/VBoxContainer/ButtonsContainer/BtnPista
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonsContainer/BtnSiguiente
@onready var progress_bar = $Panel/VBoxContainer/ProgressContainer/ProgressBar
@onready var timer_juego = $TimerJuego
@onready var timer_resultado = $TimerResultado

var conexion_actual_index: int = 0
@export var vidas_maximas: int = 5
var vidas_restantes: int
var puntos: int = 0
@export var nivel_actual: int = 1
var tiempo_transcurrido: float = 0.0
var game_over: bool = false
var pistas_usadas: int = 0
var conexiones_bloqueadas: int = 0
var conexiones_permitidas: int = 0
var aciertos: int = 0

func _ready():
	_rng.randomize()
	
	vidas_restantes = vidas_maximas
	resultado_label.text = ""
	hint_label.text = ""
	btn_siguiente.visible = false
	
	if level_database == null:
		push_error("No se asignó una base de niveles para Network Defender")
		return
	
	active_difficulties = _collect_active_difficulties()
	total_levels = active_difficulties.size()
	if total_levels == 0:
		push_error("No hay niveles configurados con conexiones disponibles")
		return
	if _persistent_level_index >= total_levels:
		_persistent_level_index = 0
	
	current_level_index = _persistent_level_index
	current_difficulty = active_difficulties[current_level_index]
	connections = _build_connections_for_current_level()
	
	if connections.is_empty():
		push_error("No hay conexiones disponibles para la dificultad actual: %s" % current_difficulty)
		return

	conexion_actual_index = 0
	progress_bar.max_value = max(1, connections.size())
	progress_bar.value = 0
	
	_cargar_conexion()
	_actualizar_estadisticas()
	timer_juego.start()
	_mostrar_bienvenida()

func _mostrar_bienvenida():
	resultado_label.text = "🛡️ ¡Defiende la red de amenazas!"
	resultado_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	await get_tree().create_timer(2.0).timeout
	if not game_over:
		resultado_label.text = ""

func _process(delta):
	if not game_over and timer_juego.time_left > 0:
		tiempo_transcurrido += delta
		_actualizar_tiempo()

func _cargar_conexion():
	if conexion_actual_index >= connections.size():
		_victoria_total()
		return
	
	var conexion: ConnectionResource = connections[conexion_actual_index]
	connection_info_label.text = conexion.get_connection_info()
	hint_label.text = ""
	resultado_label.text = ""
	
	btn_permitir.disabled = false
	btn_bloquear.disabled = false
	btn_pista.disabled = false
	
	# Actualizar barra de progreso usando los intentos completados
	progress_bar.max_value = max(1, connections.size())
	progress_bar.value = conexion_actual_index
	
	# Determinar nivel actual según la dificultad en curso
	nivel_actual = current_level_index + 1
	var dificultad_legible: String = DIFFICULTY_LABELS.get(current_difficulty, current_difficulty.capitalize())
	nivel_label.text = "🎯 Nivel %d · %s" % [nivel_actual, dificultad_legible]

func _actualizar_estadisticas():
	vidas_label.text = "❤️ Vidas: " + str(vidas_restantes) + "/" + str(vidas_maximas)
	puntos_label.text = "⭐ Puntos: " + str(puntos)
	
	if vidas_restantes <= 1:
		vidas_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif vidas_restantes <= 2:
		vidas_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		vidas_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _actualizar_tiempo():
	var minutos = int(tiempo_transcurrido / 60)
	var segundos = int(tiempo_transcurrido) % 60
	tiempo_label.text = "⏱️ %02d:%02d" % [minutos, segundos]

func _on_btn_permitir_pressed() -> void:
	if game_over:
		return
	_verificar_decision(false)  # false = permitir (no es sospechosa)
	conexiones_permitidas += 1

func _on_btn_bloquear_pressed() -> void:
	if game_over:
		return
	_verificar_decision(true)  # true = bloquear (es sospechosa)
	conexiones_bloqueadas += 1

func _verificar_decision(decidio_bloquear: bool):
	var conexion: ConnectionResource = connections[conexion_actual_index]
	var es_correcta = decidio_bloquear == conexion.is_suspicious
	
	btn_permitir.disabled = true
	btn_bloquear.disabled = true
	btn_pista.disabled = true
	
	if es_correcta:
		aciertos += 1
		var puntos_ganados = 100
		if pistas_usadas == 0:
			puntos_ganados += 50  # Bonus por no usar pistas
		puntos += puntos_ganados
		
		resultado_label.text = "✅ ¡Correcto! +" + str(puntos_ganados) + " puntos"
		resultado_label.add_theme_color_override("font_color", Color(0, 1, 0))
		
		if conexion.is_suspicious:
			hint_label.text = "🚨 Razón: " + conexion.reason
		else:
			hint_label.text = "✓ Conexión legítima permitida"
		hint_label.add_theme_color_override("font_color", Color(0, 0.8, 1))
	else:
		vidas_restantes -= 1
		resultado_label.text = "❌ ¡Error! Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
		
		hint_label.text = "💡 " + conexion.reason
		hint_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
		
		_actualizar_estadisticas()
		
		if vidas_restantes <= 0:
			_game_over()
			return
	
	_actualizar_estadisticas()
	pistas_usadas = 0  # Resetear pistas para la siguiente conexión
	
	btn_siguiente.visible = true
	timer_resultado.start()

func _on_btn_pista_pressed() -> void:
	if game_over:
		return
	
	var conexion: ConnectionResource = connections[conexion_actual_index]
	hint_label.text = "💡 Pista: " + conexion.hint
	hint_label.add_theme_color_override("font_color", Color(1, 1, 0))
	pistas_usadas += 1
	btn_pista.disabled = true

func _on_btn_siguiente_pressed() -> void:
	conexion_actual_index += 1
	btn_siguiente.visible = false
	if conexion_actual_index >= connections.size():
		progress_bar.value = connections.size()
	_cargar_conexion()

func _on_timer_resultado_timeout() -> void:
	if not game_over and btn_siguiente.visible:
		_on_btn_siguiente_pressed()

func _victoria_total():
	_finalize_game(true)
	var precision := 0.0
	if connections.size() > 0:
		precision = (float(aciertos) / float(connections.size())) * 100.0
	resultado_label.text = "🏆 ¡VICTORIA TOTAL!"
	resultado_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	hint_label.text = "Precisión: %.1f%% | Puntos: %d | Tiempo: %s" % [
		precision,
		puntos,
		tiempo_label.text.replace("⏱️ ", "")
	]
	hint_label.add_theme_color_override("font_color", Color(0, 1, 0))
	connection_info_label.text = "🎉 ¡Has protegido la red exitosamente!"

func _game_over():
	_finalize_game(false)
	resultado_label.text = "💀 GAME OVER"
	resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
	var analizadas: int = min(conexion_actual_index + 1, connections.size())
	analizadas = max(1, analizadas)
	var precision := (float(aciertos) / float(analizadas)) * 100.0
	hint_label.text = "Conexiones analizadas: %d | Precisión: %.1f%%" % [analizadas, precision]
	connection_info_label.text = "⚠️ La red fue comprometida..."


func _build_connections_for_current_level() -> Array[ConnectionResource]:
	var result: Array[ConnectionResource] = []
	var source: Array[ConnectionResource] = _get_connections_source(current_difficulty)
	var max_items: int = _get_max_connections_for_difficulty(current_difficulty)
	if source.is_empty() or max_items <= 0:
		return result
	var shuffled: Array[ConnectionResource] = source.duplicate()
	_shuffle_array_in_place(shuffled)
	var count: int = min(max_items, shuffled.size())
	for i in range(count):
		result.append(shuffled[i])
	return result


func _shuffle_array_in_place(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


func _collect_active_difficulties() -> Array[String]:
	var available: Array[String] = []
	for difficulty in DIFFICULTY_ORDER:
		var source := _get_connections_source(difficulty)
		var max_items: int = _get_max_connections_for_difficulty(difficulty)
		if not source.is_empty() and max_items > 0:
			available.append(difficulty)
	return available


func _get_connections_source(difficulty: String) -> Array[ConnectionResource]:
	match difficulty:
		"easy":
			return level_database.easy_levels
		"medium":
			return level_database.medium_levels
		"hard":
			return level_database.hard_levels
		_:
			return []


func _get_max_connections_for_difficulty(difficulty: String) -> int:
	match difficulty:
		"easy":
			return max_easy_connections
		"medium":
			return max_medium_connections
		"hard":
			return max_hard_connections
		_:
			return 0


func _finalize_game(win: bool) -> void:
	if game_over:
		return
	game_over = true
	btn_permitir.disabled = true
	btn_bloquear.disabled = true
	btn_pista.disabled = true
	btn_siguiente.visible = false
	timer_juego.stop()
	progress_bar.value = connections.size()
	if total_levels > 0:
		_advance_level(total_levels)
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(win)


static func _advance_level(total_levels_param: int) -> void:
	if total_levels_param <= 0:
		_persistent_level_index = 0
		return
	_persistent_level_index = (_persistent_level_index + 1) % total_levels_param
