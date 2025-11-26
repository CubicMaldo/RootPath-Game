extends Node

## DebugLogger - Sistema centralizado de logging con categorías
## Permite activar/desactivar logs por categoría para facilitar el debugging

# Categorías de debug disponibles
enum Category {
	CLIPPY, # Sistema Clippy
	VIRUS, # Sistema de virus
	TREE, # Árbol de navegación
	DESKTOP, # Desktop y apps
	SYSTEM_MONITOR, # Monitor de sistema (CPU/RAM)
	CHALLENGE, # Estado de desafíos
	NAVIGATION, # Navegación del jugador
	GAME_LAUNCHER, # Lanzamiento de apps
	GENERAL # Mensajes generales
}

# Configuración de categorías activas (puedes modificar esto en el Inspector)
@export var enabled_categories: Array[bool] = [
	true, # CLIPPY
	false, # VIRUS
	true, # TREE
	false, # DESKTOP
	false, # SYSTEM_MONITOR
	true, # CHALLENGE
	true, # NAVIGATION
	true, # GAME_LAUNCHER
	true # GENERAL
]

# Activar/desactivar todo el sistema de debug
@export var debug_enabled: bool = true

# Colores para cada categoría (opcional)
var category_colors := {
	Category.CLIPPY: Color(0.4, 0.8, 1.0),
	Category.VIRUS: Color(1.0, 0.3, 0.3),
	Category.TREE: Color(0.3, 1.0, 0.3),
	Category.DESKTOP: Color(1.0, 0.8, 0.3),
	Category.SYSTEM_MONITOR: Color(1.0, 0.5, 1.0),
	Category.CHALLENGE: Color(1.0, 0.6, 0.2),
	Category.NAVIGATION: Color(0.5, 0.5, 1.0),
	Category.GAME_LAUNCHER: Color(0.2, 0.9, 0.9),
	Category.GENERAL: Color(0.8, 0.8, 0.8)
}

# Prefijos para cada categoría
var category_prefixes := {
	Category.CLIPPY: "[CLIPPY]",
	Category.VIRUS: "[VIRUS]",
	Category.TREE: "[TREE]",
	Category.DESKTOP: "[DESKTOP]",
	Category.SYSTEM_MONITOR: "[SYSMON]",
	Category.CHALLENGE: "[CHALLENGE]",
	Category.NAVIGATION: "[NAV]",
	Category.GAME_LAUNCHER: "[LAUNCHER]",
	Category.GENERAL: "[DEBUG]"
}

func _ready() -> void:
	if debug_enabled:
		debug_log(Category.GENERAL, "DebugLogger initialized")

## Log principal con categoría
func debug_log(category: Category, message: String, args: Array = []) -> void:
	if not debug_enabled:
		return
	
	if category >= enabled_categories.size() or not enabled_categories[category]:
		return
	
	var prefix = category_prefixes.get(category, "[UNKNOWN]")
	var formatted_message = message
	
	# Si hay argumentos, formatear el mensaje
	if args.size() > 0:
		formatted_message = message % args
	
	# Imprimir con prefijo
	print("%s %s" % [prefix, formatted_message])

## Atajos para cada categoría
func clippy(message: String, args: Array = []) -> void:
	debug_log(Category.CLIPPY, message, args)

func virus(message: String, args: Array = []) -> void:
	debug_log(Category.VIRUS, message, args)

func tree(message: String, args: Array = []) -> void:
	debug_log(Category.TREE, message, args)

func desktop(message: String, args: Array = []) -> void:
	debug_log(Category.DESKTOP, message, args)

func system_monitor(message: String, args: Array = []) -> void:
	debug_log(Category.SYSTEM_MONITOR, message, args)

func challenge(message: String, args: Array = []) -> void:
	debug_log(Category.CHALLENGE, message, args)

func navigation(message: String, args: Array = []) -> void:
	debug_log(Category.NAVIGATION, message, args)

func launcher(message: String, args: Array = []) -> void:
	debug_log(Category.GAME_LAUNCHER, message, args)

func general(message: String, args: Array = []) -> void:
	debug_log(Category.GENERAL, message, args)

## Activar/desactivar categoría en runtime
func set_category_enabled(category: Category, enabled: bool) -> void:
	if category < enabled_categories.size():
		enabled_categories[category] = enabled
		debug_log(Category.GENERAL, "Category %s %s" % [category_prefixes[category], "enabled" if enabled else "disabled"])

## Activar/desactivar todas las categorías
func enable_all() -> void:
	for i in range(enabled_categories.size()):
		enabled_categories[i] = true
	debug_log(Category.GENERAL, "All categories enabled")

func disable_all() -> void:
	for i in range(enabled_categories.size()):
		enabled_categories[i] = false
	print("[DEBUG] All categories disabled")

## Debug helper: imprimir el estado de todas las categorías
func print_status() -> void:
	print("\n=== DebugLogger Status ===")
	print("System enabled: %s" % debug_enabled)
	for cat in Category.values():
		if cat < enabled_categories.size():
			var status = "✓" if enabled_categories[cat] else "✗"
			print("%s %s: %s" % [status, category_prefixes.get(cat, "UNKNOWN"), \
				"enabled" if enabled_categories[cat] else "disabled"])
	print("========================\n")
