extends Node

## VirusController - Sistema de gestión de infecciones
## Escucha eventos de fallo en desafíos y despliega virus

# Constantes
const OVERLAY_SCENE_PATH = "res://src/virus/VirusOverlay.tscn"

# Catálogo de virus fullscreen
var virus_types = {
	"glitch": preload("res://src/virus/types/GlitchVirus.tscn") if ResourceLoader.exists("res://src/virus/types/GlitchVirus.tscn") else null,
	"adware": preload("res://src/virus/types/AdwareVirus.tscn") if ResourceLoader.exists("res://src/virus/types/AdwareVirus.tscn") else null,
	"phishing": preload("res://src/virus/types/PhishingVirus.tscn") if ResourceLoader.exists("res://src/virus/types/PhishingVirus.tscn") else null,
	"popup": preload("res://src/virus/types/PopupVirus.tscn")
}

# Catálogo de virus basados en apps (usando AppStats resources)
var app_virus_types = {
	"fake_update": preload("res://src/desktop/resources/FakeUpdateVirus.tres"),
	"captcha": preload("res://src/desktop/resources/CaptchaVirus.tres"),
	"survey": preload("res://src/desktop/resources/SurveyVirus.tres")
}

# Preferencia de tipo de virus (40% app, 60% fullscreen)
var use_app_virus_chance: float = 0.4

# Sistema de penalización por fallos
var failed_virus_count: int = 0
var max_failed_viruses: int = 3 # Game over al tercer fallo

# Variables de estado
var overlay_instance: VirusOverlay
var desktop_manager: Node
var clippy: ClippyController = null # Reference to Clippy assistant
var is_infected: bool = false
var current_virus_type: String = "" # "fullscreen" o "app"

func _ready() -> void:
	# Conectar al bus de eventos
	EventBus.challenge_completed.connect(_on_challenge_completed)
	# Preparar overlay (oculto)
	_setup_overlay()
	
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

func trigger_infection(type: String = "") -> void:
	if is_infected:
		return
	is_infected = true
	current_virus_type = "fullscreen"
	print("⚠️ SISTEMA INFECTADO (FULLSCREEN) ⚠️")
	# Seleccionar virus
	var virus_scene = _select_virus(type)
	if not virus_scene:
		push_warning("VirusController: No hay virus disponibles para infectar")
		is_infected = false
		return
	# Mostrar overlay y añadir virus
	overlay_instance.show_overlay()
	var virus = overlay_instance.add_virus(virus_scene)
	if virus:
		virus.virus_cleared.connect(_on_virus_cleared)
		virus.virus_failed.connect(_on_virus_failed)
		virus.start_infection()
		_on_virus_started_monitor() # Monitor update
		EventBus.navigation_blocked.emit("SISTEMA INFECTADO - LIMPIEZA REQUERIDA")
		
		# Send Clippy help for fullscreen virus
		_send_clippy_virus_help("Virus", type)

func _on_virus_cleared() -> void:
	print("✅ SISTEMA LIMPIO")
	is_infected = false
	current_virus_type = ""
	_on_virus_ended_monitor() # Monitor update
	overlay_instance.hide_overlay()
	EventBus.navigation_ready.emit()

func _on_virus_failed() -> void:
	print("❌ FALLO EN LIMPIEZA")
	failed_virus_count += 1
	print("⚠️ Fallos acumulados: %d/%d" % [failed_virus_count, max_failed_viruses])
	
	# Send Clippy failure notification
	_send_clippy_failure_update()
	
	if failed_virus_count >= max_failed_viruses:
		_trigger_game_over()
	else:
		# El virus sigue activo como penalización
		pass
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
	if is_infected:
		return
	
	# Check if desktop manager is available
	if desktop_manager == null:
		print("ℹ️ Desktop manager no disponible, usando virus fullscreen en su lugar")
		trigger_infection(type)
		return
	
	is_infected = true
	current_virus_type = "app"
	print("⚠️ SISTEMA INFECTADO (APP VIRUS) ⚠️")
	
	# Seleccionar virus app stats
	var virus_app_stats = _select_app_virus(type)
	if not virus_app_stats:
		push_warning("VirusController: No hay app virus disponibles")
		is_infected = false
		return
	
	# Usar el sistema de apps del Desktop (igual que cualquier otra app)
	var session = desktop_manager.open_app_from_stats(virus_app_stats)
	
	if session.is_empty():
		push_error("VirusController: Error al abrir app virus")
		is_infected = false
		return
		
	var virus_instance = session.get("app")
	var panel = session.get("panel")
	
	if virus_instance:
		virus_instance.virus_cleared.connect(_on_app_virus_cleared.bind(panel))
		virus_instance.virus_failed.connect(_on_app_virus_failed.bind(panel))
		virus_instance.start_infection()
		_on_virus_started_monitor() # Monitor update
		EventBus.navigation_blocked.emit("⚠️ APLICACIÓN SOSPECHOSA DETECTADA")
		
		# Send Clippy help for app virus
		var virus_type = _get_virus_type_from_stats(virus_app_stats)
		_send_clippy_virus_help(virus_app_stats.app_name, virus_type)
		
		# Ocultar botones de panel para virus
		if panel and panel.has_method("hide_buttons"):
			panel.hide_buttons()
	else:
		push_error("VirusController: No se obtuvo instancia de virus desde la app")
		is_infected = false

func _on_app_virus_cleared(app_panel: Node) -> void:
	print("✅ APP VIRUS LIMPIADO")
	is_infected = false
	current_virus_type = ""
	_on_virus_ended_monitor() # Monitor update
	
	# Cerrar la app del virus
	if app_panel:
		app_panel.queue_free()
		
	EventBus.navigation_ready.emit()

func _on_app_virus_failed(_app_panel: Node) -> void:
	print("❌ APP VIRUS FALLÓ")
	failed_virus_count += 1
	print("⚠️ Fallos acumulados: %d/%d" % [failed_virus_count, max_failed_viruses])
	
	# Send Clippy failure notification
	_send_clippy_failure_update()
	
	if failed_virus_count >= max_failed_viruses:
		_trigger_game_over()
	# Si no es game over, mantener la app abierta como penalización

# ---------------------------------------------------------------------------
# Helper selection functions
# ---------------------------------------------------------------------------
func _select_virus(specific_type: String) -> PackedScene:
	if specific_type != "" and virus_types.has(specific_type) and virus_types[specific_type] != null:
		return virus_types[specific_type]
	var available = []
	for key in virus_types:
		if virus_types[key] != null:
			available.append(virus_types[key])
	if available.is_empty():
		return null
	return available.pick_random()

func _select_app_virus(specific_type: String) -> AppStats:
	if specific_type != "" and app_virus_types.has(specific_type):
		return app_virus_types[specific_type]
	var available_keys = []
	for key in app_virus_types:
		if app_virus_types[key] != null:
			available_keys.append(key)
	if available_keys.is_empty():
		return null
	var random_key = available_keys.pick_random()
	return app_virus_types[random_key]

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
	is_infected = false
	
	# Cerrar overlay si está activo
	if overlay_instance and overlay_instance.visible:
		overlay_instance.hide_overlay()
	
	# Emitir señal de game over (false = perdió)
	EventBus.game_over.emit(false)
	
	# Resetear contador para siguiente partida
	failed_virus_count = 0

# ---------------------------------------------------------------------------
# Clippy Integration
# ---------------------------------------------------------------------------
func _send_clippy_virus_help(virus_name: String, virus_type: String) -> void:
	if not clippy:
		return
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.VIRUS_INFECTED
	event.context_id = virus_type if virus_type != "" else "unknown"
	event.payload = {
		"virus_name": virus_name,
		"virus_type": virus_type,
		"current_failures": failed_virus_count,
		"max_failures": max_failed_viruses
	}
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

func _get_virus_type_from_stats(stats: AppStats) -> String:
	# Extract virus type from AppStats resource path
	for key in app_virus_types:
		if app_virus_types[key] == stats:
			return key
	return "unknown"

# ---------------------------------------------------------------------------
# System Monitor Integration
# ---------------------------------------------------------------------------
func _on_virus_started_monitor() -> void:
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").register_virus_start()

func _on_virus_ended_monitor() -> void:
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").register_virus_end()

func _on_system_overload() -> void:
	print("🔥 SISTEMA SOBRECARGADO - CRASH INMINENTE")
	_trigger_game_over()
