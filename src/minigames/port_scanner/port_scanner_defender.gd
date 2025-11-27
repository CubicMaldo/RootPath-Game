extends Control

## Minijuego de ciberseguridad: Port Scanner Defender
## El jugador actúa como IDS (Sistema de Detección de Intrusiones), identificando escaneos de puertos maliciosos

@export var scan_database: PortScanDatabase
var scans: Array[PortScanResource] = []

@onready var ip_label = $Panel/VBoxContainer/ScanInfo/IPLabel
@onready var port_label = $Panel/VBoxContainer/ScanInfo/PortLabel
@onready var protocol_label = $Panel/VBoxContainer/ScanInfo/ProtocolLabel
@onready var scan_type_label = $Panel/VBoxContainer/ScanInfo/ScanTypeLabel
@onready var packet_label = $Panel/VBoxContainer/ScanInfo/PacketLabel
@onready var time_label = $Panel/VBoxContainer/ScanInfo/TimeLabel
@onready var description_label = $Panel/VBoxContainer/DescriptionContainer/DescriptionLabel
@onready var resultado_label = $Panel/VBoxContainer/ResultadoLabel
@onready var hint_label = $Panel/VBoxContainer/HintContainer/HintLabel
@onready var vidas_label = $Panel/VBoxContainer/TopBar/VidasLabel
@onready var puntos_label = $Panel/VBoxContainer/TopBar/PuntosLabel
@onready var progreso_label = $Panel/VBoxContainer/TopBar/ProgresoLabel
@onready var timer_label = $Panel/VBoxContainer/TopBar/TimerLabel

@onready var btn_legitimo = $Panel/VBoxContainer/ButtonContainer/BtnLegitimo
@onready var btn_malicioso = $Panel/VBoxContainer/ButtonContainer/BtnMalicioso
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonContainer/BtnSiguiente
@onready var panel = $Panel

var scan_actual_index: int = 0
var puntos: int = 0
var vidas: int = 3
var scans_completados: int = 0
var total_scans: int = 18
var tiempo_restante: float = 540.0 # 9 minutos
var clippy_hint_active: bool = false
var fail_streak: int = 0
const IDLE_HINT_TIME := 20.0
var idle_timer: Timer

func _ready():
	if scan_database:
		scans = scan_database.get_shuffled_scans()
		total_scans = min(scans.size(), 18)
	
	resultado_label.hide()
	hint_label.hide()
	btn_siguiente.hide()
	
	actualizar_ui()
	mostrar_scan_actual()
	
	btn_legitimo.pressed.connect(_on_legitimo_pressed)
	btn_malicioso.pressed.connect(_on_malicioso_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	
	idle_timer = Timer.new()
	idle_timer.wait_time = IDLE_HINT_TIME
	idle_timer.one_shot = true
	idle_timer.timeout.connect(_on_idle_timeout)
	add_child(idle_timer)
	_reset_idle_timer()
	
	_notify_clippy("Bienvenido al Analizador de Tráfico. Decide qué escaneos son legítimos y cuáles son ataques.", "tutorial")

func _notify_clippy(message: String, tone: String = "info") -> void:
	if Global.has_singleton("ClippyBridge"):
		Global.ClippyBridge.notify_clippy(message, tone)

func _reset_idle_timer() -> void:
	if idle_timer == null:
		return
	idle_timer.stop()
	idle_timer.start()

func _on_idle_timeout() -> void:
	if clippy_hint_active:
		return
	if scan_actual_index >= scans.size():
		return
	var scan := scans[scan_actual_index]
	var mensaje = "Observa el puerto %d (%s) y su %s. %s" % [
		scan.target_port,
		scan.get_port_name(),
		scan.protocol,
		scan.hint
	]
	_deliver_hint(mensaje, false)

func _process(delta):
	tiempo_restante -= delta
	if tiempo_restante <= 0:
		tiempo_restante = 0
		game_over()
	actualizar_timer()

func actualizar_timer():
	var minutos = floori(tiempo_restante / 60.0)
	var segundos = floori(tiempo_restante) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutos, segundos]
	
	if tiempo_restante < 60:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func actualizar_ui():
	vidas_label.text = "❤️ Vidas: %d" % vidas
	puntos_label.text = "⭐ Puntos: %d" % puntos
	progreso_label.text = "🔍 Scan: %d/%d" % [scans_completados + 1, total_scans]

func mostrar_scan_actual():
	if scan_actual_index >= scans.size() or scan_actual_index >= total_scans:
		victoria()
		return
	
	var scan: PortScanResource = scans[scan_actual_index]
	
	ip_label.text = "IP Origen: " + scan.source_ip
	port_label.text = "Puerto: %d (%s)" % [scan.target_port, scan.get_port_name()]
	protocol_label.text = "Protocolo: " + scan.protocol
	scan_type_label.text = "Tipo: " + scan.scan_type
	packet_label.text = "Paquetes: %d" % scan.packet_count
	time_label.text = "Tiempo: " + scan.time_span
	description_label.text = scan.description
	
	resultado_label.hide()
	_clear_hint_feed()
	btn_siguiente.hide()
	clippy_hint_active = false
	
	btn_legitimo.disabled = false
	btn_malicioso.disabled = false
	_reset_idle_timer()
	_announce_scan(scan)

func _announce_scan(scan: PortScanResource) -> void:
	var resumen = "Analiza el puerto %d (%s) usando %s. Tipo: %s." % [
		scan.target_port,
		scan.get_port_name(),
		scan.protocol,
		scan.scan_type
	]
	_notify_clippy(resumen, "info")
	_set_hint_feed("Terminal listo: Observando %s → puerto %d" % [scan.source_ip, scan.target_port])

func _set_hint_feed(text: String, color: Color = Color(0.2, 0.9, 1.0)) -> void:
	hint_label.text = text
	hint_label.add_theme_color_override("font_color", color)
	hint_label.show()

func _clear_hint_feed() -> void:
	hint_label.text = ""
	hint_label.hide()

func _deliver_hint(text: String, urgent: bool) -> void:
	var contenido = text.strip_edges()
	if contenido == "":
		contenido = "Observa los puertos críticos y el número de paquetes para encontrar anomalías."
	var tone = "warning" if urgent else "info"
	var feed_color = Color(1, 0.6, 0.3) if urgent else Color(0.3, 1.0, 0.9)
	_notify_clippy(contenido, tone)
	_set_hint_feed("🤖 Clippy: " + contenido, feed_color)
	clippy_hint_active = true

func _flash_panel(color: Color, duration := 0.35) -> void:
	if panel == null:
		return
	var tween = create_tween()
	tween.tween_property(panel, "modulate", color, duration * 0.4)
	tween.tween_property(panel, "modulate", Color(1, 1, 1), duration * 0.6)

func _shake_interface(intensity := 12.0, duration := 0.3) -> void:
	var original_position = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_position + Vector2(intensity, -intensity), duration * 0.33)
	tween.tween_property(self, "position", original_position - Vector2(intensity, intensity), duration * 0.33)
	tween.tween_property(self, "position", original_position, duration * 0.34)
	tween.finished.connect(func(): position = original_position)

func _on_legitimo_pressed():
	_reset_idle_timer()
	verificar_respuesta(false)

func _on_malicioso_pressed():
	_reset_idle_timer()
	verificar_respuesta(true)

func verificar_respuesta(es_malicioso: bool):
	var scan: PortScanResource = scans[scan_actual_index]
	var respuesta_correcta = (scan.is_malicious == es_malicioso)
	
	btn_legitimo.disabled = true
	btn_malicioso.disabled = true
	
	if respuesta_correcta:
		var puntos_ganados = 120
		if not clippy_hint_active:
			puntos_ganados += 60
			resultado_label.text = "✅ ¡CORRECTO! +180 puntos (bonus sin asistencia)"
		else:
			resultado_label.text = "✅ ¡CORRECTO! +120 puntos (con asistencia)"
		
		puntos += puntos_ganados
		resultado_label.add_theme_color_override("font_color", Color.GREEN)
		_flash_panel(Color(0.2, 0.9, 0.5))
		_notify_clippy("Buen análisis. Clasificaste correctamente este tráfico.", "success")
		fail_streak = 0
		clippy_hint_active = false
	else:
		vidas -= 1
		resultado_label.text = "❌ INCORRECTO - Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color.RED)
		_flash_panel(Color(0.9, 0.25, 0.25))
		_shake_interface()
		fail_streak += 1
		_notify_clippy("Respuesta incorrecta. Observa el puerto y el tipo de escaneo para detectar patrones sospechosos.", "warning")
		
		if vidas <= 0:
			game_over()
			return
		elif fail_streak == 2:
			_deliver_hint("Pista rápida: " + scan.hint, true)
	
	resultado_label.show()
	mostrar_explicacion(scan)
	
	actualizar_ui()
	btn_siguiente.show()

func mostrar_explicacion(scan: PortScanResource):
	var explicacion = "\n\n" + scan.explanation
	
	if scan.is_malicious:
		var indicators = scan.get_risk_indicators()
		if indicators.size() > 0:
			explicacion += "\n\n🚨 Indicadores de riesgo:\n"
			for indicator in indicators:
				explicacion += "• " + indicator + "\n"
	
	resultado_label.text += explicacion


func _on_siguiente_pressed():
	_reset_idle_timer()
	scans_completados += 1
	scan_actual_index += 1
	
	if scan_actual_index >= total_scans:
		victoria()
	else:
		mostrar_scan_actual()

func victoria():
	if idle_timer:
		idle_timer.stop()
	_flash_panel(Color(0.3, 1.0, 0.8), 0.6)
	resultado_label.text = "🟢 RED ASEGURADA 🟢\n\n"
	resultado_label.text += "Completaste el entrenamiento IDS\n"
	resultado_label.text += "Scans analizados: %d/%d\n" % [scans_completados, total_scans]
	resultado_label.text += "Puntos totales: %d\n" % puntos
	resultado_label.text += "Vidas restantes: %d\n" % vidas
	resultado_label.add_theme_color_override("font_color", Color.GOLD)
	resultado_label.show()
	
	ocultar_controles()
	
	await get_tree().create_timer(3.0).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(true)
	else:
		print("Victoria en Port Scanner Defender - Puntos: ", puntos)
	
	_notify_clippy("Excelente trabajo. El escaneo quedó bajo control.", "success")
	get_tree().change_scene_to_file("res://src/desktop/Desktop.tscn")

func game_over():
	if idle_timer:
		idle_timer.stop()
	resultado_label.text = "💀 GAME OVER 💀\n\n"
	if tiempo_restante <= 0:
		resultado_label.text += "Se acabó el tiempo\n"
	else:
		resultado_label.text += "Te quedaste sin vidas\n"
	resultado_label.text += "Scans completados: %d/%d\n" % [scans_completados, total_scans]
	resultado_label.text += "Puntos obtenidos: %d\n" % puntos
	resultado_label.add_theme_color_override("font_color", Color.RED)
	resultado_label.show()
	_flash_panel(Color(1.0, 0.3, 0.3), 0.5)
	_shake_interface(14.0, 0.4)
	
	ocultar_controles()
	
	await get_tree().create_timer(3.0).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(false)
	else:
		print("Derrota en Port Scanner Defender")
	
	_notify_clippy("El IDS fue superado. Repasa los patrones para la próxima.", "warning")
	get_tree().change_scene_to_file("res://src/desktop/Desktop.tscn")

func ocultar_controles():
	btn_legitimo.hide()
	btn_malicioso.hide()
	btn_siguiente.hide()
	_clear_hint_feed()
