extends Node

## VirusController - Sistema de gestión de infecciones
## Escucha eventos de fallo en desafíos y despliega virus

# Constantes
const OVERLAY_SCENE_PATH = "res://src/virus/VirusOverlay.tscn"
# AppVirusSpawner es una clase global, no necesitamos preload

# Catálogo de virus fullscreen
var virus_types = {
	"glitch": preload("res://src/virus/types/GlitchVirus.tscn") if ResourceLoader.exists("res://src/virus/types/GlitchVirus.tscn") else null,
	"adware": preload("res://src/virus/types/AdwareVirus.tscn") if ResourceLoader.exists("res://src/virus/types/AdwareVirus.tscn") else null,
	"phishing": preload("res://src/virus/types/PhishingVirus.tscn") if ResourceLoader.exists("res://src/virus/types/PhishingVirus.tscn") else null
}

# Catálogo de virus basados en apps (paneles de escritorio)
var app_virus_types = {
	"fake_update": {
		"scene": preload("res://src/virus/app_viruses/FakeUpdateVirus.tscn") if ResourceLoader.exists("res://src/virus/app_viruses/FakeUpdateVirus.tscn") else null,
		"app_name": "⚠️ Windows Update",
		"icon": null
	},
	"captcha": {
		"scene": preload("res://src/virus/app_viruses/CaptchaVirus.tscn") if ResourceLoader.exists("res://src/virus/app_viruses/CaptchaVirus.tscn") else null,
		"app_name": "🤖 Verificación de Seguridad",
		"icon": null
	},
	"survey": {
		"scene": preload("res://src/virus/app_viruses/SurveyVirus.tscn") if ResourceLoader.exists("res://src/virus/app_viruses/SurveyVirus.tscn") else null,
		"app_name": "📋 Encuesta Premium",
		"icon": null
	}
}

# Preferencia de tipo de virus (40% app, 60% fullscreen)
var use_app_virus_chance: float = 0.4

# Variables de estado
var overlay_instance: VirusOverlay
var app_virus_spawner: AppVirusSpawner
var desktop_manager: Node
var is_infected: bool = false
var current_virus_type: String = "" # "fullscreen" o "app"

func _ready() -> void:
	# Conectar al bus de eventos
	EventBus.challenge_completed.connect(_on_challenge_completed)
	# Preparar overlay (oculto)
	_setup_overlay()
	# Instanciar spawner de virus app
	app_virus_spawner = AppVirusSpawner.new()
	add_child(app_virus_spawner)
	# Esperar a que el Desktop esté listo y configurarlo
	await get_tree().create_timer(0.5).timeout
	_setup_app_spawner()

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
		EventBus.navigation_blocked.emit("SISTEMA INFECTADO - LIMPIEZA REQUERIDA")

func _on_virus_cleared() -> void:
	print("✅ SISTEMA LIMPIO")
	is_infected = false
	current_virus_type = ""
	overlay_instance.hide_overlay()
	EventBus.navigation_ready.emit()

func _on_virus_failed() -> void:
	print("❌ FALLO EN LIMPIEZA - REINICIANDO VIRUS")
	# Aquí podrías aplicar penalizaciones o reiniciar el virus. Por ahora, dejamos el estado infectado.

# ---------------------------------------------------------------------------
# App‑based virus handling (paneles en el escritorio)
# ---------------------------------------------------------------------------
func _setup_app_spawner() -> void:
	# Buscar el nodo Desktop que pertenece al grupo "desktop_manager"
	var desktop = get_tree().get_first_node_in_group("desktop_manager")
	if desktop:
		desktop_manager = desktop
		app_virus_spawner.setup(desktop)
		print("✅ AppVirusSpawner configurado con Desktop manager")
	else:
		push_warning("VirusController: No se encontró Desktop manager en la escena")

func trigger_app_infection(type: String = "") -> void:
	if is_infected:
		return
	is_infected = true
	current_virus_type = "app"
	print("⚠️ SISTEMA INFECTADO (APP VIRUS) ⚠️")
	
	# Seleccionar virus de app
	var virus_data = _select_app_virus(type)
	if not virus_data or not virus_data.scene:
		push_warning("VirusController: No hay app virus disponibles")
		is_infected = false
		return
	
	# Crear AppStats temporal para la app virus
	var virus_app_stats = AppStats.new()
	virus_app_stats.app_name = virus_data.app_name
	virus_app_stats.scene = virus_data.scene
	virus_app_stats.size = Vector2(500, 400) # Tamaño por defecto para virus
	virus_app_stats.icon = virus_data.icon
	
	# Usar el PanelManager del Desktop para abrir la app
	if desktop_manager == null:
		push_error("VirusController: desktop_manager no está configurado")
		is_infected = false
		return
		
	# Acceder al panel_manager del desktop si existe, o usar open_app_from_stats como fallback
	var session = {}
	if "panel_manager" in desktop_manager and desktop_manager.panel_manager != null:
		session = desktop_manager.panel_manager.spawn_app_session(virus_app_stats.scene, virus_app_stats)
		if not session.is_empty() and not session.get("is_existing", false):
			desktop_manager.panel_manager.animate_panel(session.get("panel"))
	else:
		session = desktop_manager.open_app_from_stats(virus_app_stats)
	
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
		EventBus.navigation_blocked.emit("⚠️ APLICACIÓN SOSPECHOSA DETECTADA")
	else:
		push_error("VirusController: No se obtuvo instancia de virus desde la app")
		is_infected = false

func _on_app_virus_cleared(app_panel: Node) -> void:
	print("✅ APP VIRUS LIMPIADO")
	is_infected = false
	current_virus_type = ""
	# Cerrar la app del virus mediante el spawner
	if app_panel:
		app_virus_spawner.remove_virus_app(app_panel)
	EventBus.navigation_ready.emit()

func _on_app_virus_failed(_app_panel: Node) -> void:
	print("❌ APP VIRUS FALLÓ")
	# Mantener la app abierta como penalización (no cerramos la app)

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

func _select_app_virus(specific_type: String) -> Dictionary:
	if specific_type != "" and app_virus_types.has(specific_type):
		return app_virus_types[specific_type]
	var available_keys = []
	for key in app_virus_types:
		if app_virus_types[key].scene != null:
			available_keys.append(key)
	if available_keys.is_empty():
		return {}
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
