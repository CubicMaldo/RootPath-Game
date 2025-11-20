extends Node

## VirusController - Sistema de gestión de infecciones
## Escucha eventos de fallo en desafíos y despliega virus

const OVERLAY_SCENE_PATH = "res://src/virus/VirusOverlay.tscn"

# Catálogo de virus (se llenará con las escenas reales)
var virus_types = {
	"glitch": preload("res://src/virus/types/GlitchVirus.tscn") if ResourceLoader.exists("res://src/virus/types/GlitchVirus.tscn") else null,
	"adware": preload("res://src/virus/types/AdwareVirus.tscn") if ResourceLoader.exists("res://src/virus/types/AdwareVirus.tscn") else null,
	"phishing": preload("res://src/virus/types/PhishingVirus.tscn") if ResourceLoader.exists("res://src/virus/types/PhishingVirus.tscn") else null
}

var overlay_instance: VirusOverlay
var is_infected: bool = false

func _ready():
	# Conectarse al bus de eventos
	EventBus.challenge_completed.connect(_on_challenge_completed)
	
	# Instanciar el overlay pero mantenerlo oculto
	_setup_overlay()

func _setup_overlay():
	if overlay_instance:
		return
		
	var scene = load(OVERLAY_SCENE_PATH)
	if scene:
		overlay_instance = scene.instantiate()
		# Añadir al árbol principal (root) para que persista entre cambios de escena si es necesario
		# O añadirlo como hijo de este nodo si es un Autoload
		add_child(overlay_instance)
		overlay_instance.hide_overlay()
	else:
		push_error("VirusController: No se pudo cargar VirusOverlay.tscn")

func _on_challenge_completed(_node: TreeNode, win: bool):
	if not win:
		trigger_infection()

func trigger_infection(type: String = ""):
	if is_infected:
		return
		
	is_infected = true
	print("⚠️ SISTEMA INFECTADO ⚠️")
	
	# Seleccionar virus
	var virus_scene = _select_virus(type)
	if not virus_scene:
		push_warning("VirusController: No hay virus disponibles para infectar")
		is_infected = false
		return
		
	overlay_instance.show_overlay()
	var virus = overlay_instance.add_virus(virus_scene)
	
	if virus:
		virus.virus_cleared.connect(_on_virus_cleared)
		virus.virus_failed.connect(_on_virus_failed)
		virus.start_infection()
		
		# Emitir señal de bloqueo de navegación
		EventBus.navigation_blocked.emit("SISTEMA INFECTADO - LIMPIEZA REQUERIDA")

func _select_virus(specific_type: String) -> PackedScene:
	# Si se especifica un tipo y existe, usarlo
	if specific_type != "" and virus_types.has(specific_type) and virus_types[specific_type] != null:
		return virus_types[specific_type]
	
	# Si no, seleccionar uno aleatorio de los disponibles
	var available = []
	for key in virus_types:
		if virus_types[key] != null:
			available.append(virus_types[key])
	
	if available.is_empty():
		return null
		
	return available.pick_random()

func _on_virus_cleared():
	print("✅ SISTEMA LIMPIO")
	is_infected = false
	overlay_instance.hide_overlay()
	EventBus.navigation_ready.emit()

func _on_virus_failed():
	print("❌ FALLO EN LIMPIEZA - REINICIANDO VIRUS")
	# Por ahora, simplemente reiniciamos el virus o mantenemos la infección
	# Diseño futuro: Penalización de tiempo global
