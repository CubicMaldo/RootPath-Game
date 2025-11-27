extends Control

const ClippyEventResource := preload("res://src/clippy/events/ClippyEvent.gd")

@onready var app_desktop_container: GridContainer = $DesktopMargin/AppContainer
@onready var taskbar_container: Container = %TaskBar
@export var apps_panel_scene: PackedScene
@onready var game_over_visuals: ColorRect = $CanvasLayer/EndingScreen
@onready var desktop_banner: PanelContainer = $CanvasLayer/DesktopBanner
@onready var banner_label: RichTextLabel = $CanvasLayer/DesktopBanner/BannerLabel

var panel_manager: PanelManager
var _banner_tween: Tween

func _ready():
	add_to_group("desktop_manager")
	
	# Initialize PanelManager
	# Note: We assume %AppPanelContainer exists in the scene tree as it was used in the original script
	panel_manager = PanelManager.new(%AppPanelContainer, apps_panel_scene)
	
	# Conectamos dinámicamente TODOS los iconos del contenedor
	for icon in app_desktop_container.get_children():
		if icon.has_signal("open_app"):
			var icon_cb := Callable(self, "_on_icon_opened").bind(icon)
			if icon_cb != null:
				icon.connect("open_app", icon_cb)
	EventBus.game_over.connect(_on_game_over)
	EventBus.challenge_completed.connect(_on_challenge_banner)
	
	# Create simple System Monitor UI
	_create_system_monitor_ui()
	
	# Show Clippy intro if flag is set
	_check_clippy_intro()

func _create_system_monitor_ui() -> void:
	var monitor_panel = PanelContainer.new()
	monitor_panel.name = "SystemMonitorUI"
	monitor_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	monitor_panel.position = Vector2(-220, 40) # Offset from top right
	monitor_panel.custom_minimum_size = Vector2(200, 80)
	
	var vbox = VBoxContainer.new()
	monitor_panel.add_child(vbox)
	
	var cpu_label = Label.new()
	cpu_label.name = "CPULabel"
	cpu_label.text = "CPU: 0%"
	vbox.add_child(cpu_label)
	
	var ram_label = Label.new()
	ram_label.name = "RAMLabel"
	ram_label.text = "RAM: 0%"
	vbox.add_child(ram_label)
	
	add_child(monitor_panel)
	
	# Connect update
	if has_node("/root/SystemMonitor"):
		get_node("/root/SystemMonitor").usage_updated.connect(func(cpu, ram):
			cpu_label.text = "CPU: %.1f%%" % cpu
			ram_label.text = "RAM: %.1f%%" % ram
			
			# Color warning
			if cpu > 90: cpu_label.modulate = Color.RED
			else: cpu_label.modulate = Color.WHITE
			
			if ram > 90: ram_label.modulate = Color.RED
			else: ram_label.modulate = Color.WHITE
		)

func open_app_from_stats(app_stats: AppStats) -> Dictionary:
	if app_stats == null:
		return {}
	if app_stats.scene == null:
		push_warning("AppStats %s no tiene escena asociada." % app_stats.app_name)
		return {}
		
	var session := panel_manager.spawn_app_session(app_stats.scene, app_stats)
	if session.is_empty():
		return session
		
	if not session.get("is_existing", false):
		panel_manager.animate_panel(session.get("panel"))
		if has_node("/root/SystemMonitor"):
			get_node("/root/SystemMonitor").register_app_opened()
			# Connect close signal to monitor
			var panel = session.get("panel")
			if panel.has_signal("tree_exiting"):
				panel.tree_exiting.connect(func():
					if has_node("/root/SystemMonitor"):
						get_node("/root/SystemMonitor").register_app_closed()
				)
		
	return session

func _on_icon_opened(app_ref: PackedScene, appStats: AppStats, source_icon: Node):
	var session := panel_manager.spawn_app_session(app_ref, appStats)
	
	if session.is_empty():
		return
		
	if not session.get("is_existing", false):
		panel_manager.animate_panel(session.get("panel"))
		if has_node("/root/SystemMonitor"):
			get_node("/root/SystemMonitor").register_app_opened()
			# Connect close signal to monitor
			var panel = session.get("panel")
			if panel.has_signal("tree_exiting"):
				panel.tree_exiting.connect(func():
					if has_node("/root/SystemMonitor"):
						get_node("/root/SystemMonitor").register_app_closed()
				)
		
	# Taskbar logic remains here as it interacts with taskbar_container which is specific to Desktop
	var app_id = session.get("app_id")
	if source_icon != null and app_id != null:
		_ensure_taskbar_icon(app_id, source_icon)

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
func _on_game_over(_won: bool):
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

func _check_clippy_intro() -> void:
	# Wait for scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame
	
	if Global.should_show_clippy_intro:
		Global.should_show_clippy_intro = false
		
		if Global.ClippyBridge != null:
			_show_tutorial_sequence()

func _show_tutorial_sequence() -> void:
	var tutorial_messages = [
		"Bienvenido a Safe TreeNet. Soy tu asistente del sistema. Te guiaré por los controles básicos.",
		"En la esquina superior derecha ves tu capacidad del sistema. Cada app consume recursos. Si se satura, habrá consecuencias.",
		"Abre el Mapa del Árbol para sincronizarte con las ramas de la red. Ahí eliges nodos y desbloqueas nuevas funciones.",
		"Algunos nodos contienen protocolos de seguridad (minijuegos). Completa estos desafíos para avanzar y proteger la red."
	]
	
	# Send tutorial sequence
	await Global.ClippyBridge.notify_clippy_sequence(tutorial_messages, "tutorial", 11.0)
	
	# Final warning message (separate for different priority)
	Global.ClippyBridge.notify_clippy("ADVERTENCIA: Los virus pueden infiltrarse en Safe TreeNet. Si detectas actividad sospechosa, elimínalos de inmediato o el sistema colapsará.", "warning")

func _kill_tween_if_running(tween_ref: Tween) -> void:
	if tween_ref and tween_ref.is_running():
		tween_ref.kill()

func _broadcast_desktop_intro() -> void:
	var instruction := "[b]Inicio del Operativo RootPath[/b]\nHaz clic en el icono del árbol para desplegar el mapa y comenzar la secuencia de recuperación."
	var lore := "[color=#9ef7ff]Crónica de Superficie[/color]\nLos sensores detectan un enjambre de intrusiones silenciosas. Cada aplicación es una raíz viva; protégela antes de que la red quede en sombras."
	_send_clippy_custom_text("desktop_instruction", instruction, ClippyEvent.Priority.HIGH, 0.05)
	_send_clippy_custom_text("desktop_lore", lore, ClippyEvent.Priority.NORMAL, 0.08)
	_show_banner("%s\n\n%s" % [instruction, lore], 8.0, Color(0.6, 0.85, 1.0))

func _send_clippy_custom_text(context_id: String, text: String, priority: ClippyEvent.Priority, completion: float) -> void:
	if text.is_empty():
		return
	if not has_node("/root/Clippy"):
		return
	var event := ClippyEventResource.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.context_id = context_id
	event.priority = priority
	var safe_completion := clampf(completion, 0.0, 1.0)
	event.payload = {
		"completion": safe_completion,
		"custom_text": text
	}
	get_node("/root/Clippy").handle_event(event)

func _on_challenge_banner(node: TreeNode, win: bool) -> void:
	var label := _resolve_node_label(node)
	var message := ""
	var accent := Color(1, 0.7, 0.4)
	if win:
		message = "[b]%s protegido[/b]\nEl malware retrocedió dejando un registro cifrado para tus archivos." % label
		accent = Color(0.55, 0.95, 0.65)
	else:
		message = "[b]%s comprometido[/b]\nRefuerza defensas y reintenta antes de que la infección se propague." % label
	_show_banner(message, 6.0, accent)

func _show_banner(text: String, duration: float, accent_color: Color = Color.WHITE) -> void:
	if desktop_banner == null or banner_label == null:
		return
	banner_label.bbcode_text = text
	banner_label.add_theme_color_override("default_color", accent_color)
	desktop_banner.visible = true
	desktop_banner.modulate.a = 0.0
	_kill_banner_tween()
	_banner_tween = create_tween()
	_banner_tween.tween_property(desktop_banner, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_interval(max(duration, 0.5))
	_banner_tween.tween_property(desktop_banner, "modulate:a", 0.45, 0.15)
	_banner_tween.tween_property(desktop_banner, "modulate:a", 0.0, 0.45)
	_banner_tween.tween_callback(func(): desktop_banner.visible = false)

func _kill_banner_tween() -> void:
	if _banner_tween and _banner_tween.is_running():
		_banner_tween.kill()

func _resolve_node_label(node: TreeNode) -> String:
	if node == null:
		return "Nodo desconocido"
	if node.app_resource != null and node.app_resource.app_name != "":
		return node.app_resource.app_name
	return "Nodo %s" % _node_type_name_for_value(node)

func _node_type_name_for_value(node: TreeNode) -> String:
	if node == null:
		return "desconocido"
	var tipo := node.tipo if "tipo" in node else -1
	match tipo:
		0:
			return "Inicio"
		1:
			return "Desafío"
		2:
			return "Pista"
		3:
			return "Final"
		_:
			return "Desconocido"
