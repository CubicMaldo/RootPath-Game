extends Node

## VirusController - Sistema de gestión de infecciones
## Escucha eventos de fallo en desafíos y despliega virus

# Constantes
const OVERLAY_SCENE_PATH = "res://src/virus/VirusOverlay.tscn"
const DEFAULT_OVERLAY_ACCENT = Color(0.94, 0.35, 0.2, 1)

# Catálogo de definiciones de virus
var fullscreen_definitions: Array = [
	ResourceLoader.load("res://src/virus/resources/GlitchVirusDefinition.tres"),
	ResourceLoader.load("res://src/virus/resources/AdwareVirusDefinition.tres"),
	ResourceLoader.load("res://src/virus/resources/PhishingVirusDefinition.tres"),
	ResourceLoader.load("res://src/virus/resources/PopupVirusDefinition.tres")
]

var app_definitions: Array = [
	ResourceLoader.load("res://src/virus/resources/FakeUpdateVirusDefinition.tres"),
	ResourceLoader.load("res://src/virus/resources/CaptchaVirusDefinition.tres"),
	ResourceLoader.load("res://src/virus/resources/SurveyVirusDefinition.tres")
]

# Preferencia de tipo de virus (40% app, 60% fullscreen)
var use_app_virus_chance: float = 0.4
@export var infection_cooldown: float = 2.0
@export var global_difficulty_level: int = 1

# Sistema de penalización por fallos
var failed_virus_count: int = 0
var max_failed_viruses: int = 3 # Game over al tercer fallo

# Variables de estado
var overlay_instance: VirusOverlay
var desktop_manager: Node
var clippy: ClippyController = null # Reference to Clippy assistant
var is_infected: bool = false
var current_virus_type: String = "" # "fullscreen" o "app"
var current_definition: VirusDefinition = null
var pending_infections: Array = []
var cooldown_timer: Timer
var _is_initialized: bool = false
var _definition_lookup: Dictionary = {}

func _ready() -> void:
	_register_definitions(fullscreen_definitions)
	_register_definitions(app_definitions)
	# Conectar al bus de eventos
	EventBus.challenge_completed.connect(_on_challenge_completed)
	# Preparar overlay (oculto)
	_setup_overlay()
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)
	
	# Conectar SystemMonitor
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").system_overload.connect(_on_system_overload)
	
	# Get Clippy reference
	if has_node("/root/Clippy"):
		clippy = get_node("/root/Clippy")
		print("✅ Clippy conectado al VirusController")
	else:
		push_warning("VirusController: Clippy autoload no encontrado")
	
	# Esperar a que el Desktop esté listo y configurarlo
	await get_tree().create_timer(0.5).timeout
	_setup_desktop_connection()
	_is_initialized = true
	_process_infection_queue()

# ---------------------------------------------------------------------------
# Overlay (fullscreen) handling
# ---------------------------------------------------------------------------
func _setup_overlay() -> void:
	if overlay_instance:
		return
	var scene = load(OVERLAY_SCENE_PATH)
	if scene:
		overlay_instance = scene.instantiate()
		add_child(overlay_instance)
		overlay_instance.hide_overlay()
	else:
		push_error("VirusController: No se pudo cargar VirusOverlay.tscn")

# ---------------------------------------------------------------------------
# Scheduler and infection lifecycle helpers
# ---------------------------------------------------------------------------
func _enqueue_infection(request: Dictionary) -> void:
	pending_infections.append(request)
	_process_infection_queue()

func _process_infection_queue() -> void:
	if not _is_initialized:
		return
	if pending_infections.is_empty():
		return
	if is_infected:
		return
	if cooldown_timer and not cooldown_timer.is_stopped():
		return
	var request = pending_infections[0]
	pending_infections.remove_at(0)
	var definition = _resolve_definition(request)
	if definition == null:
		_process_infection_queue()
		return
	if definition.get_category_name() == "app":
		_start_app_infection(definition)
	else:
		_start_fullscreen_infection(definition)

func _start_cooldown() -> void:
	if cooldown_timer == null:
		return
	if infection_cooldown <= 0.0:
		cooldown_timer.stop()
		_process_infection_queue()
		return
	cooldown_timer.start(infection_cooldown)

func _on_cooldown_finished() -> void:
	_process_infection_queue()

func _handle_infection_started(status_message: String, definition: VirusDefinition = null) -> void:
	_on_virus_started_monitor()
	EventBus.navigation_blocked.emit(status_message)
	_report_monitor_spike(definition)

func _handle_infection_finished(start_cooldown: bool = true) -> void:
	is_infected = false
	current_virus_type = ""
	current_definition = null
	_on_virus_ended_monitor()
	EventBus.navigation_ready.emit()
	if start_cooldown:
		_start_cooldown()
	else:
		if cooldown_timer:
			cooldown_timer.stop()

func _start_fullscreen_infection(definition: VirusDefinition) -> void:
	if not overlay_instance:
		push_error("VirusController: overlay_instance no disponible")
		_process_infection_queue()
		return
	if definition == null or definition.virus_scene == null:
		push_error("VirusController: La definición de virus fullscreen no es válida")
		_process_infection_queue()
		return
	print("⚠️ SISTEMA INFECTADO (FULLSCREEN) ⚠️")
	var alert_title: String = _definition_display_name(definition)
	var alert_message: String = _definition_alert_message(definition)
	var accent_color: Color = definition.accent_color if definition else DEFAULT_OVERLAY_ACCENT
	overlay_instance.show_overlay(alert_title, alert_message, accent_color)
	var virus = overlay_instance.add_virus(definition.virus_scene)
	if virus == null:
		push_error("VirusController: La escena instanciada no es un virus válido")
		overlay_instance.hide_overlay()
		_process_infection_queue()
		return
	is_infected = true
	current_definition = definition
	current_virus_type = definition.get_category_name()
	virus.configure_from_definition(definition, global_difficulty_level)
	virus.virus_cleared.connect(_on_virus_cleared)
	virus.virus_failed.connect(_on_virus_failed)
	virus.start_infection()
	_handle_infection_started("SISTEMA INFECTADO - LIMPIEZA REQUERIDA", definition)
	_send_clippy_virus_help(definition)

func _start_app_infection(definition: VirusDefinition) -> void:
	if definition == null or definition.app_stats == null:
		push_error("VirusController: La definición de virus app no es válida")
		_process_infection_queue()
		return
	print("⚠️ SISTEMA INFECTADO (APP VIRUS) ⚠️")
	if desktop_manager == null:
		push_error("VirusController: desktop_manager no está configurado")
		_process_infection_queue()
		return
	var session = desktop_manager.open_app_from_stats(definition.app_stats)
	if session.is_empty():
		push_error("VirusController: Error al abrir app virus")
		_process_infection_queue()
		return
	var virus_instance = session.get("app")
	var panel = session.get("panel")
	if virus_instance == null or not (virus_instance is BaseVirus):
		push_error("VirusController: No se obtuvo instancia de virus válida desde la app")
		_process_infection_queue()
		return
	is_infected = true
	current_definition = definition
	current_virus_type = definition.get_category_name()
	virus_instance.configure_from_definition(definition, global_difficulty_level)
	virus_instance.virus_cleared.connect(_on_app_virus_cleared.bind(panel))
	virus_instance.virus_failed.connect(_on_app_virus_failed.bind(panel))
	virus_instance.start_infection()
	_handle_infection_started("⚠️ APLICACIÓN SOSPECHOSA DETECTADA", definition)
	_send_clippy_virus_help(definition)
	if panel and panel.has_method("hide_buttons"):
		panel.hide_buttons()

func trigger_infection(type: String = "") -> void:
	_enqueue_infection({
		"mode": "fullscreen",
		"type": type
	})

func _on_virus_cleared() -> void:
	print("✅ SISTEMA LIMPIO")
	if overlay_instance:
		overlay_instance.hide_overlay()
	_handle_infection_finished()

func _on_virus_failed() -> void:
	print("❌ FALLO EN LIMPIEZA")
	failed_virus_count += 1
	print("⚠️ Fallos acumulados: %d/%d" % [failed_virus_count, max_failed_viruses])
	
	# Send Clippy failure notification
	_send_clippy_failure_update()
	if overlay_instance and overlay_instance.visible:
		overlay_instance.hide_overlay()
	_handle_infection_finished()
	if failed_virus_count >= max_failed_viruses:
		_trigger_game_over()
# ---------------------------------------------------------------------------
# App‑based virus handling (usando Desktop's app system)
# ---------------------------------------------------------------------------
func _setup_desktop_connection() -> void:
	# Buscar el nodo Desktop que pertenece al grupo "desktop_manager"
	var desktop = get_tree().get_first_node_in_group("desktop_manager")
	if desktop:
		desktop_manager = desktop
		print("✅ Desktop manager encontrado")
	# Note: Desktop manager is not required for fullscreen viruses
	# It's only needed for app-based viruses

func trigger_app_infection(type: String = "") -> void:
	_enqueue_infection({
		"mode": "app",
		"type": type
	})

func _on_app_virus_cleared(app_panel: Node) -> void:
	print("✅ APP VIRUS LIMPIADO")
	
	# Cerrar la app del virus
	if app_panel:
		app_panel.queue_free()
	_handle_infection_finished()

func _on_app_virus_failed(_app_panel: Node) -> void:
	print("❌ APP VIRUS FALLÓ")
	failed_virus_count += 1
	print("⚠️ Fallos acumulados: %d/%d" % [failed_virus_count, max_failed_viruses])
	
	# Send Clippy failure notification
	_send_clippy_failure_update()
	
	if _app_panel:
		_app_panel.queue_free()
	_handle_infection_finished()
	if failed_virus_count >= max_failed_viruses:
		_trigger_game_over()

# ---------------------------------------------------------------------------
# Helper selection functions
# ---------------------------------------------------------------------------
func _resolve_definition(request: Dictionary) -> VirusDefinition:
	var specific_type: String = str(request.get("type", ""))
	if specific_type != "" and _definition_lookup.has(specific_type):
		return _definition_lookup[specific_type]
	var mode: String = request.get("mode", "fullscreen")
	return _select_definition_for_category(mode)

func _select_definition_for_category(category: String) -> VirusDefinition:
	var source: Array = app_definitions if category == "app" else fullscreen_definitions
	var eligible: Array = []
	var fallback: Array = []
	for definition in source:
		if definition == null or not (definition is VirusDefinition):
			continue
		fallback.append(definition)
		if definition.matches_failure_window(failed_virus_count):
			eligible.append(definition)
	if eligible.is_empty():
		eligible = fallback
	if eligible.is_empty():
		return null
	var total_weight := 0.0
	for definition in eligible:
		total_weight += max(definition.spawn_weight, 0.01)
	var selection := randf() * total_weight
	for definition in eligible:
		selection -= max(definition.spawn_weight, 0.01)
		if selection <= 0.0:
			return definition
	return eligible.back()

func _definition_display_name(definition: VirusDefinition) -> String:
	if definition == null:
		return "Virus"
	var custom_name := definition.display_name.strip_edges()
	return custom_name if custom_name != "" else str(definition.identifier)

func _definition_alert_message(definition: VirusDefinition) -> String:
	if definition and definition.alert_message.strip_edges() != "":
		return definition.alert_message.strip_edges()
	return "SISTEMA INFECTADO - LIMPIEZA REQUERIDA"

func _register_definitions(definitions: Array) -> void:
	for definition in definitions:
		if definition == null or not (definition is VirusDefinition):
			continue
		var key := str(definition.identifier)
		if key == "":
			continue
		_definition_lookup[key] = definition

# ---------------------------------------------------------------------------
# Challenge completion handling
# ---------------------------------------------------------------------------
func _on_challenge_completed(_node: TreeNode, win: bool) -> void:
	if not win:
		# Decidir aleatoriamente entre app o fullscreen
		if randf() < use_app_virus_chance:
			trigger_app_infection()
		else:
			trigger_infection()

# ---------------------------------------------------------------------------
# Game Over Management
# ---------------------------------------------------------------------------
func _trigger_game_over() -> void:
	print("💀 GAME OVER - Demasiados virus sin eliminar")
	if is_infected:
		_handle_infection_finished(false)
	is_infected = false
	
	# Cerrar overlay si está activo
	if overlay_instance and overlay_instance.visible:
		overlay_instance.hide_overlay()
	pending_infections.clear()
	if cooldown_timer:
		cooldown_timer.stop()
	
	# Emitir señal de game over (false = perdió)
	EventBus.game_over.emit(false)
	
	# Resetear contador para siguiente partida
	failed_virus_count = 0

# ---------------------------------------------------------------------------
# Clippy Integration
# ---------------------------------------------------------------------------
func _send_clippy_virus_help(definition: VirusDefinition = null, fallback_name: String = "Virus", fallback_type: String = "") -> void:
	if not clippy:
		return
	var virus_name: String = fallback_name
	var virus_type: String = fallback_type
	if definition:
		virus_name = _definition_display_name(definition)
		virus_type = str(definition.identifier)
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.VIRUS_INFECTED
	event.context_id = virus_type if virus_type != "" else "unknown"
	event.payload = {
		"virus_name": virus_name,
		"virus_type": virus_type,
		"current_failures": failed_virus_count,
		"max_failures": max_failed_viruses
	}
	if definition and definition.clippy_hint.strip_edges() != "":
		event.payload["hint"] = definition.clippy_hint.strip_edges()
	event.priority = ClippyEvent.Priority.HIGH
	
	clippy.handle_event(event)

func _send_clippy_failure_update() -> void:
	if not clippy:
		return
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.VIRUS_FAILED
	event.payload = {
		"failed_count": failed_virus_count,
		"max_failures": max_failed_viruses,
		"remaining": max_failed_viruses - failed_virus_count
	}
	event.priority = ClippyEvent.Priority.CRITICAL
	
	clippy.handle_event(event)

# ---------------------------------------------------------------------------
# System Monitor Integration
# ---------------------------------------------------------------------------
func _report_monitor_spike(definition: VirusDefinition) -> void:
	if definition == null:
		return
	if not has_node("/root/SystemMonitor"):
		return
	var spike_amount: float = definition.monitor_spike if definition.monitor_spike > 0.0 else 10.0
	var difficulty_bonus: float = max(0, global_difficulty_level - 1) * 1.5
	get_node("/root/SystemMonitor").add_spike(spike_amount + difficulty_bonus)

func _on_virus_started_monitor() -> void:
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").register_virus_start()

func _on_virus_ended_monitor() -> void:
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").register_virus_end()

func _on_system_overload() -> void:
	print("🔥 SISTEMA SOBRECARGADO - CRASH INMINENTE")
	_trigger_game_over()
