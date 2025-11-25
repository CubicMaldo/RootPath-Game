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
@onready var btn_pista = $Panel/VBoxContainer/ButtonContainer/BtnPista
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonContainer/BtnSiguiente

var scan_actual_index: int = 0
var puntos: int = 0
var vidas: int = 3
var scans_completados: int = 0
var total_scans: int = 18
var tiempo_restante: float = 540.0 # 9 minutos
var uso_pista: bool = false

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
	btn_pista.pressed.connect(_on_pista_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)

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
	hint_label.hide()
	btn_siguiente.hide()
	uso_pista = false
	
	btn_legitimo.disabled = false
	btn_malicioso.disabled = false
	btn_pista.disabled = false

func _on_legitimo_pressed():
	verificar_respuesta(false)

func _on_malicioso_pressed():
	verificar_respuesta(true)

func verificar_respuesta(es_malicioso: bool):
	var scan: PortScanResource = scans[scan_actual_index]
	var respuesta_correcta = (scan.is_malicious == es_malicioso)
	
	btn_legitimo.disabled = true
	btn_malicioso.disabled = true
	btn_pista.disabled = true
	
	if respuesta_correcta:
		var puntos_ganados = 120
		if not uso_pista:
			puntos_ganados += 60
			resultado_label.text = "✅ ¡CORRECTO! +180 puntos (120 + 60 bonus sin pista)"
		else:
			resultado_label.text = "✅ ¡CORRECTO! +120 puntos"
		
		puntos += puntos_ganados
		resultado_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		vidas -= 1
		resultado_label.text = "❌ INCORRECTO - Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color.RED)
		
		if vidas <= 0:
			game_over()
			return
	
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

func _on_pista_pressed():
	var scan: PortScanResource = scans[scan_actual_index]
	hint_label.text = "💡 Pista: " + scan.hint
	hint_label.show()
	uso_pista = true
	btn_pista.disabled = true

func _on_siguiente_pressed():
	scans_completados += 1
	scan_actual_index += 1
	
	if scan_actual_index >= total_scans:
		victoria()
	else:
		mostrar_scan_actual()

func victoria():
	resultado_label.text = "🎉 ¡VICTORIA! 🎉\n\n"
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
	
	get_tree().change_scene_to_file("res://src/desktop/Desktop.tscn")

func game_over():
	resultado_label.text = "💀 GAME OVER 💀\n\n"
	if tiempo_restante <= 0:
		resultado_label.text += "Se acabó el tiempo\n"
	else:
		resultado_label.text += "Te quedaste sin vidas\n"
	resultado_label.text += "Scans completados: %d/%d\n" % [scans_completados, total_scans]
	resultado_label.text += "Puntos obtenidos: %d\n" % puntos
	resultado_label.add_theme_color_override("font_color", Color.RED)
	resultado_label.show()
	
	ocultar_controles()
	
	await get_tree().create_timer(3.0).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(false)
	else:
		print("Derrota en Port Scanner Defender")
	
	get_tree().change_scene_to_file("res://src/desktop/Desktop.tscn")

func ocultar_controles():
	btn_legitimo.hide()
	btn_malicioso.hide()
	btn_pista.hide()
	btn_siguiente.hide()
	hint_label.hide()
