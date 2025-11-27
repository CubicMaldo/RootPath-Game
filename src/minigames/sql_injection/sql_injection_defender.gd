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
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonsContainer/BtnSiguiente
@onready var progress_bar = $Panel/VBoxContainer/ProgressContainer/ProgressBar
@onready var timer_juego = $TimerJuego
@onready var timer_resultado = $TimerResultado
@onready var panel = $Panel

var consulta_actual_index: int = 0
var vidas_restantes: int = 3
var vidas_maximas: int = 3
var puntos: int = 0
var tiempo_transcurrido: float = 0.0
var game_over: bool = false
var ataques_bloqueados: int = 0
var consultas_seguras_permitidas: int = 0
var aciertos: int = 0
var clippy_hint_active: bool = false
var fail_streak: int = 0
const IDLE_HINT_TIME := 18.0
var idle_timer: Timer

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
	
	idle_timer = Timer.new()
	idle_timer.wait_time = IDLE_HINT_TIME
	idle_timer.one_shot = true
	idle_timer.timeout.connect(_on_idle_timeout)
	add_child(idle_timer)
	_reset_idle_timer()
	_notify_clippy("Bienvenido a la consola de base de datos. Clasifica cada input y evita inyecciones.", "tutorial")

func _notify_clippy(message: String, tone: String = "info") -> void:
	if Global.has_singleton("ClippyBridge"):
		Global.ClippyBridge.notify_clippy(message, tone)

func _reset_idle_timer() -> void:
	if idle_timer == null:
		return
	idle_timer.stop()
	idle_timer.start()

func _on_idle_timeout() -> void:
	if clippy_hint_active or game_over:
		return
	if consulta_actual_index >= queries.size():
		return
	var consulta: SQLQueryResource = queries[consulta_actual_index]
	var mensaje = "Revisa la consulta base y compárala con el input '%s'." % consulta.get_display_text()
	_deliver_hint(mensaje, false)

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
	
	_clear_hint_feed()
	resultado_label.text = ""
	
	btn_seguro.disabled = false
	btn_malicioso.disabled = false
	clippy_hint_active = false
	fail_streak = 0
	_reset_idle_timer()
	_announce_query(consulta)
	
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
	_reset_idle_timer()
	_verificar_decision(false)  # false = consulta segura
	consultas_seguras_permitidas += 1

func _on_btn_malicioso_pressed() -> void:
	if game_over:
		return
	_reset_idle_timer()
	_verificar_decision(true)  # true = ataque SQL injection
	ataques_bloqueados += 1

func _verificar_decision(decidio_es_malicioso: bool):
	var consulta: SQLQueryResource = queries[consulta_actual_index]
	var es_correcta = decidio_es_malicioso == consulta.is_malicious
	
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	
	if es_correcta:
		aciertos += 1
		var puntos_ganados = 150
		if not clippy_hint_active:
			puntos_ganados += 75  # Bonus por no pedir ayuda
		puntos += puntos_ganados
		
		resultado_label.text = "✅ ¡Correcto! +" + str(puntos_ganados) + " puntos"
		resultado_label.add_theme_color_override("font_color", Color(0, 1, 0))
		_flash_panel(Color(0.2, 0.9, 0.5))
		fail_streak = 0
		clippy_hint_active = false
		
		var success_text = ""
		var success_color = Color(0.3, 1.0, 0.9)
		if consulta.is_malicious:
			success_text = "🚨 Ataque bloqueado: %s\n%s" % [consulta.attack_type, consulta.explanation]
			success_color = Color(1, 0.75, 0.3)
		else:
			success_text = "🟢 Consulta permitida correctamente\n%s" % consulta.explanation
		_set_hint_feed(success_text, success_color)
		var success_tone = "success" if consulta.is_malicious else "info"
		_notify_clippy(success_text, success_tone)
	else:
		vidas_restantes -= 1
		resultado_label.text = "❌ ¡Error! Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
		
		var fail_text = "💡 " + consulta.explanation
		if consulta.is_malicious:
			fail_text += "\n🚨 Era un ataque: " + consulta.attack_type
		_set_hint_feed(fail_text, Color(1, 0.6, 0.2))
		fail_streak += 1
		_flash_panel(Color(0.9, 0.25, 0.25))
		_shake_interface()
		_notify_clippy(fail_text, "warning")
		if fail_streak == 2:
			_deliver_hint("Pista: " + consulta.hint, true)
		
		_actualizar_estadisticas()
		
		if vidas_restantes <= 0:
			_game_over()
			return
	
	_actualizar_estadisticas()
	
	btn_siguiente.visible = true
	timer_resultado.start()

func _on_btn_siguiente_pressed() -> void:
	_reset_idle_timer()
	consulta_actual_index += 1
	btn_siguiente.visible = false
	_cargar_consulta()

func _on_timer_resultado_timeout() -> void:
	if not game_over and btn_siguiente.visible:
		_on_btn_siguiente_pressed()

func _announce_query(consulta: SQLQueryResource) -> void:
	var resumen = "Consulta %d/%d | Input '%s'" % [
		consulta_actual_index + 1,
		queries.size(),
		consulta.get_display_text()
	]
	_notify_clippy(resumen + ". Evalúa si el input altera la lógica SQL.", "info")
	_set_hint_feed("Terminal activo: %s" % consulta.query_text)

func _deliver_hint(texto: String, urgent: bool) -> void:
	var contenido = texto.strip_edges()
	if contenido == "":
		contenido = "Busca operadores como '--', 'OR 1=1' o UNION no autorizados."
	var tone = "warning" if urgent else "info"
	var feed_color = Color(1, 0.6, 0.3) if urgent else Color(0.3, 1.0, 0.9)
	_notify_clippy(contenido, tone)
	_set_hint_feed("🤖 Clippy: " + contenido, feed_color)
	clippy_hint_active = true

func _set_hint_feed(text: String, color: Color = Color(0.2, 0.9, 1.0)) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)
	hint_label.show()

func _clear_hint_feed() -> void:
	hint_label.text = ""
	hint_label.hide()

func _flash_panel(color: Color, duration := 0.35) -> void:
	if panel == null:
		return
	var tween = create_tween()
	tween.tween_property(panel, "modulate", color, duration * 0.4)
	tween.tween_property(panel, "modulate", Color(1, 1, 1), duration * 0.6)

func _shake_interface(intensity := 10.0, duration := 0.25) -> void:
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(intensity, 0), duration * 0.33)
	tween.tween_property(self, "position", original_position - Vector2(intensity, 0), duration * 0.33)
	tween.tween_property(self, "position", original_position, duration * 0.34)
	tween.finished.connect(func(): position = original_position)

func _victoria_total():
	game_over = true
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	btn_siguiente.visible = false
	timer_juego.stop()
	if idle_timer:
		idle_timer.stop()
	_flash_panel(Color(0.3, 1.0, 0.8), 0.6)
	
	var precision = float(aciertos) / float(queries.size()) * 100
	
	resultado_label.text = "🏆 ¡BASE DE DATOS PROTEGIDA!"
	resultado_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	
	_set_hint_feed("Precisión: %.1f%% | Puntos: %d | Ataques bloqueados: %d" % [
		precision,
		puntos,
		ataques_bloqueados
	], Color(0.4, 1.0, 0.6))
	
	query_display.text = "¡Felicitaciones!"
	input_display.text = "Has demostrado ser un excelente defensor contra SQL Injection"
	sql_preview.text = "🎉 La base de datos está segura gracias a ti"
	
	# Reportar victoria al sistema global
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(true)
	_notify_clippy("¡Base blindada! Tus decisiones bloquearon todas las inyecciones.", "success")

func _game_over():
	game_over = true
	btn_seguro.disabled = true
	btn_malicioso.disabled = true
	btn_siguiente.visible = false
	timer_juego.stop()
	if idle_timer:
		idle_timer.stop()
	_flash_panel(Color(1.0, 0.35, 0.35), 0.5)
	_shake_interface(14.0, 0.35)
	
	resultado_label.text = "💀 GAME OVER"
	resultado_label.add_theme_color_override("font_color", Color(1, 0, 0))
	
	var total_analizadas = max(consulta_actual_index, 1)
	var precision = float(aciertos) / float(total_analizadas) * 100
	_set_hint_feed("Consultas analizadas: %d | Precisión: %.1f%% | Ataques bloqueados: %d" % [
		total_analizadas,
		precision,
		ataques_bloqueados
	], Color(1, 0.6, 0.3))
	
	query_display.text = "⚠️ La base de datos fue comprometida"
	input_display.text = "Los atacantes lograron ejecutar código SQL malicioso"
	sql_preview.text = "💔 Necesitas más práctica en seguridad SQL"
	
	# Reportar derrota al sistema global
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(false)
	_notify_clippy("El servidor cayó. Analiza los operadores sospechosos antes del próximo intento.", "warning")
