extends Control

## Minijuego de ciberseguridad: SQL Injection Defender
## El jugador debe identificar intentos de inyección SQL antes de que lleguen a la base de datos

@export var query_database: SQLQueryDatabase
var queries: Array[SQLQueryResource] = []

@onready var query_display = $Panel/VBoxContainer/QueryContainer/QueryDisplay
@onready var input_display = $Panel/VBoxContainer/InputContainer/InputDisplay
@onready var sql_preview = $Panel/VBoxContainer/SQLPreviewContainer/SQLPreview
@onready var resultado_label = $Panel/VBoxContainer/ResultadoLabel
@onready var hint_label = $Panel/VBoxContainer/HintContainer/HintLabel
@onready var vidas_label = $Panel/VBoxContainer/TopBar/VidasLabel
@onready var puntos_label = $Panel/VBoxContainer/TopBar/PuntosLabel
@onready var consultas_label = $Panel/VBoxContainer/TopBar/ConsultasLabel
@onready var tiempo_label = $Panel/VBoxContainer/TopBar/TiempoLabel
@onready var btn_seguro = $Panel/VBoxContainer/ButtonsContainer/BtnSeguro
@onready var btn_malicioso = $Panel/VBoxContainer/ButtonsContainer/BtnMalicioso
@onready var btn_pista = $Panel/VBoxContainer/ButtonsContainer/BtnPista
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonsContainer/BtnSiguiente
@onready var progress_bar = $Panel/VBoxContainer/ProgressContainer/ProgressBar
@onready var timer_juego = $TimerJuego
@onready var timer_resultado = $TimerResultado

var consulta_actual_index: int = 0
var vidas_restantes: int = 3
var vidas_maximas: int = 3
var puntos: int = 0
var tiempo_transcurrido: float = 0.0
var game_over: bool = false
var pistas_usadas: int = 0
var ataques_bloqueados: int = 0
var consultas_seguras_permitidas: int = 0
var aciertos: int = 0

func _ready():
	resultado_label.text = ""
	hint_label.text = ""
	btn_siguiente.visible = false
	
	queries = query_database.get_all_queries()
	
	if queries.is_empty():
		push_error("No hay consultas cargadas en la base de datos")
		return
	
	_cargar_consulta()
	_actualizar_estadisticas()
	timer_juego.start()
	_mostrar_bienvenida()

func _mostrar_bienvenida():
	resultado_label.text = "🛡️ ¡Protege la base de datos!"
	resultado_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	await get_tree().create_timer(2.0).timeout
	if not game_over:
		resultado_label.text = ""

func _process(delta):
	if not game_over and timer_juego.time_left > 0:
		tiempo_transcurrido += delta
		_actualizar_tiempo()

func _cargar_consulta():
	if consulta_actual_index >= queries.size():
		_victoria_total()
		return
	
	var consulta: SQLQueryResource = queries[consulta_actual_index]
	
	# Mostrar la consulta SQL base
	query_display.text = consulta.query_text
	
	# Mostrar el input del usuario
	input_display.text = consulta.get_display_text()
	
	# Mostrar la consulta SQL resultante
	sql_preview.text = "SQL Resultante:\n" + consulta.get_full_query()
	
	hint_label.text = ""
	resultado_label.text = ""
	
	btn_seguro.disabled = false
	btn_malicioso.disabled = false
	btn_pista.disabled = false
	
	# Actualizar barra de progreso
	progress_bar.max_value = queries.size()
	progress_bar.value = consulta_actual_index + 1
	
	consultas_label.text = "📊 Consulta: %d/%d" % [consulta_actual_index + 1, queries.size()]

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

func _on_btn_seguro_pressed() -> void:
	if game_over:
		return
	_verificar_decision(false)  # false = consulta segura
	consultas_seguras_permitidas += 1

func _on_btn_malicioso_pressed() -> void:
	if game_over:
		return
	_verificar_decision(true)  # true = ataque SQL injection
	ataques_bloqueados += 1

func _verificar_decision(decidio_es_malicioso: bool):
	var consulta: SQLQueryResource = queries[consulta_actual_index]
	var es_correcta = decidio_es_malicioso == consulta.is_malicious
	
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	btn_pista.disabled = true
	
	if es_correcta:
		aciertos += 1
		var puntos_ganados = 150
		if pistas_usadas == 0:
			puntos_ganados += 75  # Bonus por no usar pistas
		puntos += puntos_ganados
		
		resultado_label.text = "✅ ¡Correcto! +" + str(puntos_ganados) + " puntos"
		resultado_label.add_theme_color_override("font_color", Color(0, 1, 0))
		
		if consulta.is_malicious:
			hint_label.text = "🚨 Tipo de ataque: " + consulta.attack_type + "\n" + consulta.explanation
		else:
			hint_label.text = "✓ Consulta legítima permitida correctamente\n" + consulta.explanation
		hint_label.add_theme_color_override("font_color", Color(0, 0.8, 1))
	else:
		vidas_restantes -= 1
		resultado_label.text = "❌ ¡Error! Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
		
		hint_label.text = "💡 " + consulta.explanation
		if consulta.is_malicious:
			hint_label.text += "\n🚨 Era un ataque: " + consulta.attack_type
		hint_label.add_theme_color_override("font_color", Color(1, 0.5, 0))
		
		_actualizar_estadisticas()
		
		if vidas_restantes <= 0:
			_game_over()
			return
	
	_actualizar_estadisticas()
	pistas_usadas = 0  # Resetear pistas para la siguiente consulta
	
	btn_siguiente.visible = true
	timer_resultado.start()

func _on_btn_pista_pressed() -> void:
	if game_over:
		return
	
	var consulta: SQLQueryResource = queries[consulta_actual_index]
	hint_label.text = "💡 Pista: " + consulta.hint
	hint_label.add_theme_color_override("font_color", Color(1, 1, 0))
	pistas_usadas += 1
	btn_pista.disabled = true

func _on_btn_siguiente_pressed() -> void:
	consulta_actual_index += 1
	btn_siguiente.visible = false
	_cargar_consulta()

func _on_timer_resultado_timeout() -> void:
	if not game_over and btn_siguiente.visible:
		_on_btn_siguiente_pressed()

func _victoria_total():
	game_over = true
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	btn_pista.disabled = true
	btn_siguiente.visible = false
	timer_juego.stop()
	
	var precision = float(aciertos) / float(queries.size()) * 100
	
	resultado_label.text = "🏆 ¡BASE DE DATOS PROTEGIDA!"
	resultado_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	
	hint_label.text = "Precisión: %.1f%% | Puntos: %d | Ataques bloqueados: %d" % [
		precision, 
		puntos,
		ataques_bloqueados
	]
	hint_label.add_theme_color_override("font_color", Color(0, 1, 0))
	
	query_display.text = "¡Felicitaciones!"
	input_display.text = "Has demostrado ser un excelente defensor contra SQL Injection"
	sql_preview.text = "🎉 La base de datos está segura gracias a ti"
	
	# Reportar victoria al sistema global
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(true)

func _game_over():
	game_over = true
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	btn_pista.disabled = true
	btn_siguiente.visible = false
	timer_juego.stop()
	
	resultado_label.text = "💀 GAME OVER"
	resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
	
	var precision = float(aciertos) / float(consulta_actual_index) * 100
	hint_label.text = "Consultas analizadas: %d | Precisión: %.1f%% | Ataques bloqueados: %d" % [
		consulta_actual_index, 
		precision,
		ataques_bloqueados
	]
	
	query_display.text = "⚠️ La base de datos fue comprometida"
	input_display.text = "Los atacantes lograron ejecutar código SQL malicioso"
	sql_preview.text = "💔 Necesitas más práctica en seguridad SQL"
	
	# Reportar derrota al sistema global
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(false)
