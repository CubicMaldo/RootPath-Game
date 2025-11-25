extends Control

## Minijuego de ciberseguridad: Password Cracker - Versión Mejorada
## El jugador debe descifrar contraseñas de diferentes niveles usando pistas y análisis

@export var level_database : PasswordLevelDatabase
@export_range(0, 100, 1) var max_easy_levels: int = 3
@export_range(0, 100, 1) var max_medium_levels: int = 3
@export_range(0, 100, 1) var max_hard_levels: int = 3

const DIFFICULTY_ORDER: Array[String] = ["easy", "medium", "hard"]
const DIFFICULTY_LABELS := {
	"easy": "Fácil",
	"medium": "Medio",
	"hard": "Difícil",
}

static var _persistent_level_index: int = 0

var niveles: Array[PasswordLevelResource] = []
var active_difficulties: Array[String] = []
var current_level_index: int = 0
var current_difficulty: String = "easy"
var total_levels: int = 0
var _rng := RandomNumberGenerator.new()

@onready var input_password = $Panel/MarginContainer/VBoxContainer/InputContainer/LineEdit
@onready var label_resultado = $Panel/MarginContainer/VBoxContainer/ResultadoLabel
@onready var pistas_container = $Panel/MarginContainer/VBoxContainer/PistasContainer
@onready var intentos_label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/IntentosLabel
@onready var nivel_label = $Panel/MarginContainer/VBoxContainer/TopBar/NivelLabel
@onready var puntos_label = $Panel/MarginContainer/VBoxContainer/TopBar/PuntosLabel
@onready var tiempo_label = $Panel/MarginContainer/VBoxContainer/TopBar/TiempoLabel
@onready var similitud_label = $Panel/MarginContainer/VBoxContainer/SimilitudContainer/SimilitudLabel
@onready var progreso_bar = $Panel/MarginContainer/VBoxContainer/SimilitudContainer/ProgresoBar
@onready var timer_resultado = $Timer
@onready var timer_juego = $TimerJuego
@onready var timer_parpadeo = $TimerParpadeo
@onready var btn_pista = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BtnPista
@onready var btn_enviar = $Panel/MarginContainer/VBoxContainer/InputContainer/BtnEnviar
@onready var btn_analizar = $Panel/MarginContainer/VBoxContainer/InputContainer/BtnAnalizar
@onready var btn_reiniciar = $Panel/MarginContainer/VBoxContainer/HBoxContainer/BtnReiniciar
#WIP AUDIO
#@onready var audio_correct = $AudioCorrect
#@onready var audio_wrong = $AudioWrong
#@onready var audio_hint = $AudioHint

var nivel_actual: int = 0
var intentos_restantes: int = 6
var intentos_maximos: int = 6
var pistas_reveladas: int = 0
var game_over: bool = false
var puntos: int = 0
var tiempo_transcurrido: float = 0.0
var analisis_disponibles: int = 2
var password_actual: String = ""
var pistas_actuales: PackedStringArray = PackedStringArray()
var combo_racha: int = 0
var mejor_puntuacion: int = 0
var intentos_totales: int = 0
var analisis_usados: int = 0

func _ready():
	_rng.randomize()
	label_resultado.text = ""
	btn_reiniciar.visible = false
	if not _initialize_session():
		return
	_actualizar_intentos()
	_actualizar_estadisticas()
	timer_juego.start()
	_mostrar_bienvenida()
	
	# Conectar Enter key para enviar
	input_password.text_submitted.connect(_on_enter_pressed)

func _mostrar_bienvenida():
	label_resultado.text = "🎯 ¡Descifra las contraseñas!"
	label_resultado.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	await get_tree().create_timer(2.0).timeout
	if not game_over:
		label_resultado.text = ""

func _on_enter_pressed(_text: String):
	if not game_over and btn_enviar.disabled == false:
		_on_btn_enviar_pressed()

func _process(delta):
	if not game_over and timer_juego.time_left > 0:
		tiempo_transcurrido += delta
		_actualizar_tiempo()

func _cargar_nivel(indice: int):
	if indice >= niveles.size():
		_victoria_total()
		return
	
	var nivel: PasswordLevelResource = niveles[indice]
	password_actual = nivel.password
	pistas_actuales = nivel.pistas
	var dificultad_legible: String = nivel.dificultad
	if dificultad_legible.is_empty():
		dificultad_legible = DIFFICULTY_LABELS.get(current_difficulty, current_difficulty.capitalize())
	nivel_label.text = "Nivel %d/%d · %s" % [indice + 1, niveles.size(), dificultad_legible]
	
	# Reiniciar valores
	intentos_restantes = intentos_maximos
	pistas_reveladas = 0
	analisis_disponibles = 2
	game_over = false
	input_password.text = ""
	input_password.editable = true
	btn_enviar.disabled = false
	btn_pista.disabled = false
	btn_analizar.disabled = false
	btn_analizar.text = "🔍 Analizar (" + str(analisis_disponibles) + ")"
	similitud_label.text = "Similitud: --"
	progreso_bar.value = 0.0
	
	# Limpiar pistas anteriores
	for child in pistas_container.get_children():
		child.queue_free()
	
	# Esperar un frame para que se eliminen los nodos
	await get_tree().process_frame
	_inicializar_pistas()
	
func _inicializar_pistas():
	# Crear labels para cada pista (ocultas inicialmente)
	for i in range(pistas_actuales.size()):
		var pista_label = Label.new()
		pista_label.text = "🔒 Pista bloqueada"
		pista_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		pista_label.add_theme_font_size_override("font_size", 32)
		pista_label.name = "Pista" + str(i)
		pistas_container.add_child(pista_label)

func _actualizar_intentos():
	intentos_label.text = "❤️ Vidas: " + str(intentos_restantes) + "/" + str(intentos_maximos)
	if intentos_restantes <= 2:
		intentos_label.add_theme_color_override("font_color", Color(1, 0, 0))
	elif intentos_restantes <= 3:
		intentos_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		intentos_label.add_theme_color_override("font_color", Color(1, 1, 1))

func _actualizar_estadisticas():
	puntos_label.text = "⭐ Puntos: " + str(puntos)
	
func _actualizar_tiempo():
	var minutos = int(tiempo_transcurrido / 60)
	var segundos = int(tiempo_transcurrido) % 60
	tiempo_label.text = "⏱️ %02d:%02d" % [minutos, segundos]

func _on_btn_enviar_pressed() -> void:
	if game_over:
		return
		
	var password_intento = input_password.text.strip_edges()
	
	if password_intento.is_empty():
		_mostrar_mensaje("❌ Debes escribir una contraseña", Color(1, 0.5, 0))
		return
	
	intentos_totales += 1
	
	if password_intento == password_actual:
		_password_correcta()
	else:
		_password_incorrecta()
		
	# Limpiar input después de intentar
	input_password.text = ""

func _on_btn_analizar_pressed() -> void:
	if game_over or analisis_disponibles <= 0:
		return
		
	var password_intento = input_password.text.strip_edges()
	
	if password_intento.is_empty():
		_mostrar_mensaje("❌ Escribe algo para analizar", Color(1, 0.5, 0))
		return
	
	analisis_disponibles -= 1
	analisis_usados += 1
	btn_analizar.text = "🔍 Analizar (" + str(analisis_disponibles) + ")"
	
	if analisis_disponibles <= 0:
		btn_analizar.disabled = true
	
	var similitud = _calcular_similitud(password_intento, password_actual)
	var caracteres_correctos = _contar_caracteres_correctos(password_intento, password_actual)
	_mostrar_similitud(similitud, caracteres_correctos)
	
	# Bonus de puntos por usar análisis inteligentemente
	if similitud > 50:
		puntos += 10
		_actualizar_estadisticas()
		_mostrar_efecto_puntos("+10", Color(0, 1, 0.5))

func _calcular_similitud(intento: String, correcta: String) -> float:
	var coincidencias: int = 0
	var longitud_min = min(intento.length(), correcta.length())
	
	# Contar caracteres correctos en posición correcta
	for i in range(longitud_min):
		if intento[i] == correcta[i]:
			coincidencias += 1
	
	# Calcular porcentaje
	var porcentaje = (float(coincidencias) / float(correcta.length())) * 100.0
	return porcentaje

func _contar_caracteres_correctos(intento: String, correcta: String) -> int:
	var coincidencias: int = 0
	var longitud_min = min(intento.length(), correcta.length())
	
	for i in range(longitud_min):
		if intento[i] == correcta[i]:
			coincidencias += 1
	
	return coincidencias

func _mostrar_similitud(porcentaje: float, caracteres_correctos: int = 0):
	similitud_label.text = "Similitud: %.1f%% (%d caracteres correctos)" % [porcentaje, caracteres_correctos]
	progreso_bar.value = porcentaje
	
	# Color según el porcentaje
	if porcentaje >= 75:
		similitud_label.add_theme_color_override("font_color", Color(0, 1, 0))
	elif porcentaje >= 50:
		similitud_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	elif porcentaje >= 25:
		similitud_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
	else:
		similitud_label.add_theme_color_override("font_color", Color(1, 0, 0))
	
	# Animación del progreso
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	var original_scale = progreso_bar.scale
	tween.tween_property(progreso_bar, "scale", Vector2(1.05, 1.1), 0.2)
	tween.tween_property(progreso_bar, "scale", original_scale, 0.2)

func _password_correcta():
	# Incrementar combo
	combo_racha += 1
	
	# Calcular puntos por el nivel
	var bonus_intentos = intentos_restantes * 50
	var bonus_tiempo = max(0, 300 - int(tiempo_transcurrido)) * 2
	var bonus_pistas = (pistas_actuales.size() - pistas_reveladas) * 30
	var bonus_combo = combo_racha * 20
	var puntos_nivel = 500 + bonus_intentos + bonus_tiempo + bonus_pistas + bonus_combo
	
	puntos += puntos_nivel
	_actualizar_estadisticas()
	
	var mensaje_combo = ""
	if combo_racha > 1:
		mensaje_combo = "\n🔥 COMBO x%d! (+%d)" % [combo_racha, bonus_combo]
	
	label_resultado.text = "✅ ¡ACCESO CONCEDIDO! 🎉\n+%d puntos%s" % [puntos_nivel, mensaje_combo]
	label_resultado.add_theme_color_override("font_color", Color(0, 1, 0))
	
	# Efecto de partículas/estrellas
	_crear_efecto_victoria()
	
	# Animación de éxito
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(label_resultado, "scale", Vector2(1.2, 1.2), 0.5)
	
	# Pasar al siguiente nivel después de 2.5 segundos
	await get_tree().create_timer(2.5).timeout
	nivel_actual += 1
	_cargar_nivel(nivel_actual)

func _crear_efecto_victoria():
	# Efecto visual de victoria
	for i in range(3):
		var tween = create_tween()
		tween.tween_property($Panel, "modulate", Color(1, 1.2, 1), 0.15)
		tween.tween_property($Panel, "modulate", Color(1, 1, 1), 0.15)
		await tween.finished

func _mostrar_efecto_puntos(texto: String, color: Color):
	var label_temp = Label.new()
	label_temp.text = texto
	label_temp.add_theme_font_size_override("font_size", 24)
	label_temp.add_theme_color_override("font_color", color)
	label_temp.position = puntos_label.position + Vector2(80, -20)
	add_child(label_temp)
	
	var tween = create_tween()
	tween.tween_property(label_temp, "position:y", label_temp.position.y - 40, 1.0)
	tween.parallel().tween_property(label_temp, "modulate:a", 0.0, 1.0)
	await tween.finished
	label_temp.queue_free()

func _password_incorrecta():
	combo_racha = 0  # Resetear combo al fallar
	intentos_restantes -= 1
	_actualizar_intentos()
	
	if intentos_restantes <= 0:
		_game_over()
	else:
		var mensaje_extra = ""
		if intentos_restantes <= 2:
			mensaje_extra = " ⚠️ ¡Cuidado!"
		_mostrar_mensaje("❌ Contraseña incorrecta. Vidas: " + str(intentos_restantes) + mensaje_extra, Color(1, 0, 0))
		
		# Efecto de sacudida en el input
		var tween = create_tween()
		var original_pos = input_password.position
		tween.tween_property(input_password, "position:x", original_pos.x + 10, 0.05)
		tween.tween_property(input_password, "position:x", original_pos.x - 10, 0.05)
		tween.tween_property(input_password, "position:x", original_pos.x + 5, 0.05)
		tween.tween_property(input_password, "position:x", original_pos.x, 0.05)
		
		# Efecto de parpadeo rojo en el panel
		_efecto_error_panel()

func _game_over():
	_finalize_game(false)
	
	var estadisticas = "\n\n📊 Estadísticas:\n"
	estadisticas += "Intentos totales: %d\n" % intentos_totales
	estadisticas += "Análisis usados: %d\n" % analisis_usados
	estadisticas += "Pistas usadas: %d" % pistas_reveladas
	
	label_resultado.text = "🔒 BLOQUEADO - Sin vidas\nLa contraseña era: " + password_actual + estadisticas
	label_resultado.add_theme_color_override("font_color", Color(1, 0, 0))
	
	# Efecto de pantalla roja
	var tween = create_tween()
	tween.tween_property($Panel, "modulate", Color(1, 0.5, 0.5), 0.3)
	tween.tween_property($Panel, "modulate", Color(1, 1, 1), 0.3)

func _efecto_error_panel():
	var tween = create_tween()
	tween.tween_property($Panel, "modulate", Color(1, 0.7, 0.7), 0.1)
	tween.tween_property($Panel, "modulate", Color(1, 1, 1), 0.1)

func _victoria_total():
	_finalize_game(true)
	
	if puntos > mejor_puntuacion:
		mejor_puntuacion = puntos
	
	var calificacion = ""
	if puntos >= 2500:
		calificacion = "🏆 PERFECTO"
	elif puntos >= 2000:
		calificacion = "🥇 EXCELENTE"
	elif puntos >= 1500:
		calificacion = "🥈 MUY BIEN"
	else:
		calificacion = "🥉 COMPLETADO"
	
	var estadisticas = "\n\n📊 Estadísticas Finales:\n"
	estadisticas += "Intentos totales: %d\n" % intentos_totales
	estadisticas += "Análisis usados: %d\n" % analisis_usados
	var precision = 0.0
	if intentos_totales > 0:
		precision = (float(niveles.size()) / float(intentos_totales)) * 100.0
	estadisticas += "Precisión: %.1f%%\n" % precision
	estadisticas += "Calificación: %s" % calificacion
	
	label_resultado.text = "🏆 ¡TODOS LOS NIVELES COMPLETADOS! 🏆\nPuntuación Final: %d\nTiempo: %02d:%02d%s" % [puntos, int(tiempo_transcurrido / 60), int(tiempo_transcurrido) % 60, estadisticas]
	label_resultado.add_theme_color_override("font_color", Color(1, 0.84, 0))
	
	# Animación de victoria
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(label_resultado, "modulate", Color(1, 1, 0), 0.3)
	tween.tween_property(label_resultado, "modulate", Color(1, 1, 1), 0.3)

func _mostrar_mensaje(mensaje: String, color: Color):
	label_resultado.text = mensaje
	label_resultado.add_theme_color_override("font_color", color)
	timer_resultado.start()

func _on_btn_pista_pressed() -> void:
	if game_over or pistas_reveladas >= pistas_actuales.size():
		return
	
	# Revelar la siguiente pista
	var pista_label = pistas_container.get_child(pistas_reveladas)
	pista_label.text = "💡 " + pistas_actuales[pistas_reveladas]
	pista_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	
	# Animación de revelación
	var tween = create_tween()
	pista_label.modulate.a = 0
	tween.tween_property(pista_label, "modulate:a", 1.0, 0.5)
	
	pistas_reveladas += 1
	
	# Penalización: reducir puntos por usar pista
	puntos -= 25
	_actualizar_estadisticas()
	_mostrar_mensaje("⚠️ Pista revelada (-25 puntos)", Color(1, 0.8, 0))
	
	if pistas_reveladas >= pistas_actuales.size():
		btn_pista.disabled = true
		btn_pista.text = "Sin pistas"

func _on_btn_reiniciar_pressed() -> void:
	# Reiniciar todo el juego
	puntos = 0
	tiempo_transcurrido = 0.0
	game_over = false
	combo_racha = 0
	intentos_totales = 0
	analisis_usados = 0
	btn_reiniciar.visible = false
	$Panel.modulate = Color(1, 1, 1)
	label_resultado.scale = Vector2(1, 1)
	if not _initialize_session():
		return
	_actualizar_intentos()
	_actualizar_estadisticas()
	timer_juego.start()
	_mostrar_bienvenida()

func _on_timer_timeout() -> void:
	if not game_over:
		label_resultado.text = ""
		label_resultado.remove_theme_color_override("font_color")


func _initialize_session() -> bool:
	if level_database == null:
		push_error("Password Cracker: No se asignó una base de niveles")
		return false
	active_difficulties = _collect_active_difficulties()
	total_levels = active_difficulties.size()
	if total_levels == 0:
		push_error("Password Cracker: No hay niveles disponibles con las configuraciones actuales")
		return false
	if _persistent_level_index >= total_levels:
		_persistent_level_index = 0
	current_level_index = _persistent_level_index
	current_difficulty = active_difficulties[current_level_index]
	niveles = _build_levels_for_current_difficulty()
	if niveles.is_empty():
		push_error("Password Cracker: No se encontraron niveles para la dificultad actual: %s" % current_difficulty)
		return false
	nivel_actual = 0
	intentos_totales = 0
	analisis_usados = 0
	combo_racha = 0
	game_over = false
	_cargar_nivel(nivel_actual)
	return true


func _collect_active_difficulties() -> Array[String]:
	var available: Array[String] = []
	for difficulty in DIFFICULTY_ORDER:
		var source := _get_levels_source(difficulty)
		var max_levels := _get_max_levels_for_difficulty(difficulty)
		if not source.is_empty() and max_levels > 0:
			available.append(difficulty)
	return available


func _build_levels_for_current_difficulty() -> Array[PasswordLevelResource]:
	var result: Array[PasswordLevelResource] = []
	var source: Array[PasswordLevelResource] = _get_levels_source(current_difficulty)
	var max_levels: int = _get_max_levels_for_difficulty(current_difficulty)
	if source.is_empty() or max_levels <= 0:
		return result
	var shuffled: Array[PasswordLevelResource] = source.duplicate()
	_shuffle_array_in_place(shuffled)
	var count: int = min(max_levels, shuffled.size())
	for i in range(count):
		result.append(shuffled[i])
	return result


func _shuffle_array_in_place(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


func _get_levels_source(difficulty: String) -> Array[PasswordLevelResource]:
	match difficulty:
		"easy":
			return level_database.easy_levels
		"medium":
			return level_database.medium_levels
		"hard":
			return level_database.hard_levels
		_:
			return []


func _get_max_levels_for_difficulty(difficulty: String) -> int:
	match difficulty:
		"easy":
			return max_easy_levels
		"medium":
			return max_medium_levels
		"hard":
			return max_hard_levels
		_:
			return 0


func _finalize_game(win: bool) -> void:
	if game_over:
		return
	game_over = true
	timer_juego.stop()
	btn_enviar.disabled = true
	btn_pista.disabled = true
	btn_analizar.disabled = true
	input_password.editable = false
	btn_reiniciar.visible = true
	if total_levels > 0:
		_advance_level(total_levels)
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(win)


static func _advance_level(total_levels_param: int) -> void:
	if total_levels_param <= 0:
		_persistent_level_index = 0
		return
	_persistent_level_index = (_persistent_level_index + 1) % total_levels_param
