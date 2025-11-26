class_name PanelManager
extends RefCounted

var _container: Control
var _panel_scene: PackedScene

func _init(container: Control, panel_scene: PackedScene):
	_container = container
	_panel_scene = panel_scene

func spawn_app_session(app_ref: PackedScene, app_stats: AppStats) -> Dictionary:
	if app_ref == null:
		return {}
		
	var app_id := _get_app_id(app_stats, app_ref)
	var existing_panel := _find_open_app_panel(app_id)
	
	if existing_panel:
		animate_panel(existing_panel)
		print("App '%s' ya está abierta; reutilizando instancia." % app_stats.app_name)
		return {
			"panel": existing_panel,
			"app": _extract_app_from_panel(existing_panel),
			"app_id": app_id,
			"is_existing": true
		}
	
	var app_panel := _panel_scene.instantiate()
	var app_inside := app_ref.instantiate()
	
	app_panel.set_meta("app_id", app_id)
	if app_panel.has_method("_setAppStat"):
		app_panel._setAppStat(app_stats)
		
	var viewport := app_panel.find_child("SubViewport")
	if viewport != null:
		viewport.add_child(app_inside)
		
	_container.add_child(app_panel)
	
	return {
		"panel": app_panel,
		"app": app_inside,
		"app_id": app_id,
		"is_existing": false
	}

func _extract_app_from_panel(panel: Node) -> Node:
	if panel == null:
		return null
	var viewport := panel.find_child("SubViewport")
	if viewport == null:
		return null
	if viewport.get_child_count() == 0:
		return null
	return viewport.get_child(0)

func animate_panel(panel: Node) -> void:
	if panel == null:
		return
	panel.visible = true
	var tween := panel.create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.6).from(Vector2(0, 0))

func _get_app_id(appStats: AppStats, app_ref: PackedScene) -> String:
	if appStats and appStats.app_name != "":
		return appStats.app_name
	if app_ref:
		return app_ref.resource_path
	return "unknown_app"

func _find_open_app_panel(app_id: String) -> Control:
	for child in _container.get_children():
		if child.has_meta("app_id") and child.get_meta("app_id") == app_id:
			return child
	return null
