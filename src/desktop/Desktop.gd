extends Control
@onready var app_desktop_container: GridContainer = $DesktopMargin/AppContainer
@onready var taskbar_container: Container = %TaskBar
@export var apps_panel_scene : PackedScene
@onready var game_over_visuals: ColorRect = $CanvasLayer/EndingScreen

func _ready():
	add_to_group("desktop_manager")
	# Conectamos dinámicamente TODOS los iconos del contenedor
	for icon in app_desktop_container.get_children():
		if icon.has_signal("open_app"):
			var icon_cb := Callable(self, "_on_icon_opened").bind(icon)
			if icon_cb != null:
				icon.connect("open_app", icon_cb)
	EventBus.game_over.connect(_on_game_over)

func open_app_from_stats(app_stats: AppStats) -> Dictionary:
	if app_stats == null:
		return {}
	if app_stats.scene == null:
		push_warning("AppStats %s no tiene escena asociada." % app_stats.app_name)
		return {}
	var session := _spawn_app_session(app_stats.scene, app_stats, null)
	if session.is_empty():
		return session
	if not session.get("is_existing", false):
		_animate_new_panel(session.get("panel"))
	return session

func _on_icon_opened(app_ref: PackedScene, appStats : AppStats, source_icon: Node):
	var session := _spawn_app_session(app_ref, appStats, source_icon)
	if session.is_empty():
		return
	if not session.get("is_existing", false):
		_animate_new_panel(session.get("panel"))

func _spawn_app_session(app_ref: PackedScene, app_stats: AppStats, source_icon: Node) -> Dictionary:
	
	if app_ref == null:
		return {}
	var app_id := _get_app_id(app_stats, app_ref)
	var existing_panel := _find_open_app_panel(app_id)
	if existing_panel:
		_animate_new_panel(existing_panel)
		print("App '%s' ya está abierta; reutilizando instancia." % app_stats.app_name)
		return {
			"panel": existing_panel,
			"app": _extract_app_from_panel(existing_panel),
			"app_id": app_id,
			"is_existing": true
		}
	
	var app_panel := apps_panel_scene.instantiate()
	var app_inside := app_ref.instantiate()	
	
	app_panel.set_meta("app_id", app_id)
	app_panel._setAppStat(app_stats)
	var viewport := app_panel.find_child("SubViewport")
	if viewport != null:
		viewport.add_child(app_inside)
	add_child(app_panel)
	if source_icon != null:
		_ensure_taskbar_icon(app_id, source_icon)

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

func _animate_new_panel(panel: Node) -> void:
	if panel == null:
		return
	panel.visible = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel.panel, "scale", Vector2(1, 1), 0.6).from(Vector2(0,0))

func _get_app_id(appStats: AppStats, app_ref: PackedScene) -> String:
	if appStats and appStats.app_name != "":
		return appStats.app_name
	if app_ref:
		return app_ref.resource_path
	return "unknown_app"

func _find_open_app_panel(app_id: String) -> Control:
	for child in get_children():
		if child.has_meta("app_id") and child.get_meta("app_id") == app_id:
			return child
	return null

func _ensure_taskbar_icon(app_id: String, source_icon: Node) -> void:
	if not _is_taskbar_ready(source_icon):
		return

	_remove_existing_taskbar_icon(app_id)
	var task_icon: Node = _create_taskbar_icon(source_icon)
	if task_icon == null:
		return

	_prepare_taskbar_icon(task_icon, app_id)
	taskbar_container.add_child(task_icon)
	_configure_taskbar_icon_connections(task_icon)

func _find_taskbar_icon(app_id: String) -> Node:
	if taskbar_container == null:
		return null
	for child in taskbar_container.get_children():
		if child.has_meta("app_id") and child.get_meta("app_id") == app_id:
			return child
	return null

func _is_taskbar_ready(source_icon: Node) -> bool:
	return taskbar_container != null and source_icon != null

func _remove_existing_taskbar_icon(app_id: String) -> void:
	var existing_icon := _find_taskbar_icon(app_id)
	if existing_icon:
		existing_icon.queue_free()

func _create_taskbar_icon(source_icon: Node) -> Node:
	var instance := _instantiate_icon_copy(source_icon)
	if instance != null:
		return instance
	var duplicate_flags: int = Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS
	return source_icon.duplicate(duplicate_flags)

func _prepare_taskbar_icon(task_icon: Node, app_id: String) -> void:
	task_icon.name = "%s_TaskIcon" % app_id
	task_icon.set_meta("app_id", app_id)
	if task_icon is Control:
		_configure_taskbar_icon_layout(task_icon)
		_configure_taskbar_texture(task_icon)

func _configure_taskbar_icon_layout(task_icon: Control) -> void:
	task_icon.custom_minimum_size = Vector2(64, 64)
	task_icon.size = Vector2(64, 64)
	task_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	task_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	task_icon.pivot_offset = Vector2(32, 32)
	task_icon.set_anchors_preset(Control.PRESET_CENTER)
	task_icon.offset_left = -32.0
	task_icon.offset_top = -32.0
	task_icon.offset_right = 32.0
	task_icon.offset_bottom = 32.0

func _configure_taskbar_texture(task_icon: Node) -> void:
	var texture_rect := task_icon.find_child("AppTexture") as TextureRect
	if texture_rect == null:
		return
	texture_rect.expand = true
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.set_anchors_preset(Control.PRESET_CENTER)
	texture_rect.offset_left = -32.0
	texture_rect.offset_top = -32.0
	texture_rect.offset_right = 32.0
	texture_rect.offset_bottom = 32.0
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.pivot_offset = Vector2(32, 32)

func _instantiate_icon_copy(source_icon: Node) -> Node:
	if source_icon == null:
		return null
	if source_icon.scene_file_path == "":
		return null
	var icon_scene := load(source_icon.scene_file_path)
	if icon_scene is PackedScene:
		var instance := (icon_scene as PackedScene).instantiate()
		if instance is AppButton and source_icon is AppButton:
			instance.appStats = source_icon.appStats
			instance.position = Vector2.ZERO
		return instance
	return null

func _configure_taskbar_icon_connections(task_icon: Node) -> void:
	if task_icon == null:
		return
	if task_icon.has_signal("open_app"):
		var task_cb := Callable(self, "_on_icon_opened").bind(task_icon)
		if task_cb != null and not task_icon.is_connected("open_app", task_cb):
			task_icon.connect("open_app", task_cb)
var tween_game_over: Tween
func _on_game_over(_won : bool):
	_kill_tween_if_running(tween_game_over)
	tween_game_over = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	# Preparar color inicial (transparente) y destino (actual)
	var target_color: Color = game_over_visuals.color
	var start_color: Color = target_color
	start_color.a = 0.0
	target_color.a = 0.8

	# Aplicar estado inicial
	game_over_visuals.color = start_color
	game_over_visuals.visible = true
	
	# Tweenear la propiedad color para un fade-in
	tween_game_over.tween_property(game_over_visuals, "color", target_color, 1)

func _kill_tween_if_running(tween_ref: Tween) -> void:
	if tween_ref and tween_ref.is_running():
		tween_ref.kill()
