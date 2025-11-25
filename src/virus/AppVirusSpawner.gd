extends Node

class_name AppVirusSpawner

## Spawner de virus que aparecen como aplicaciones en el desktop

var desktop_manager: Node = null
var active_virus_apps: Array[Dictionary] = []

func setup(desktop: Node) -> void:
	desktop_manager = desktop

func spawn_virus_app(virus_scene: PackedScene, app_stats: AppStats) -> Dictionary:
	if not desktop_manager:
		push_error("AppVirusSpawner: desktop_manager no configurado")
		return {}
	
	# Usar el sistema de app del desktop para abrir el virus como una app
	var session = desktop_manager.open_app_from_stats(app_stats)
	
	if session.is_empty():
		push_error("AppVirusSpawner: No se pudo abrir la app de virus")
		return {}
	
	# Reemplazar el contenido de la app con el virus
	var app_panel = session.get("panel")
	var viewport = app_panel.find_child("SubViewport")
	
	if viewport:
		# Limpiar contenido existente
		for child in viewport.get_children():
			child.queue_free()
		
		await desktop_manager.get_tree().process_frame
		
		# Instanciar virus
		var virus_instance = virus_scene.instantiate()
		viewport.add_child(virus_instance)
		
		# Marcar como virus para tracking
		app_panel.set_meta("is_virus", true)
		app_panel.set_meta("virus_instance", virus_instance)
		
		active_virus_apps.append({
			"panel": app_panel,
			"virus": virus_instance,
			"app_id": session.get("app_id")
		})
		
		return {
			"panel": app_panel,
			"virus": virus_instance,
			"success": true
		}
	
	return {}

func remove_virus_app(app_panel: Node) -> void:
	if app_panel and app_panel.get_parent():
		app_panel.queue_free()
	
	# Remover del tracking
	for i in range(active_virus_apps.size() - 1, -1, -1):
		if active_virus_apps[i].panel == app_panel:
			active_virus_apps.remove_at(i)

func get_active_virus_count() -> int:
	return active_virus_apps.size()

func clear_all_virus_apps() -> void:
	for virus_app in active_virus_apps:
		if virus_app.panel and virus_app.panel.get_parent():
			virus_app.panel.queue_free()
	active_virus_apps.clear()
