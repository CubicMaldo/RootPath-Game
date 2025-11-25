class_name GameLauncher
extends Node

const DESKTOP_GROUP := "desktop_manager"
const COMPLETION_SIGNALS := [
	"challenge_completed",
	"minigame_completed",
	"mini_game_completed",
	"game_completed",
	"session_completed"
]

var _desktop: Node = null
var tree_controller: TreeAppController
var _active_session: Dictionary = {}

func setup(controller: TreeAppController) -> void:
	tree_controller = controller
	print("[GameLauncher] Configurado con TreeAppController")

func set_desktop(desktop: Node) -> void:
	_desktop = desktop
	print("[GameLauncher] Desktop asignado: %s" % [desktop])

func has_active_session() -> bool:
	return not _active_session.is_empty()

func launch_node_app(node: TreeNode) -> bool:
	print("[GameLauncher] Solicitud de lanzamiento para nodo %s" % [node])
	if node == null or not node.has_app_resource():
		return false
	if has_active_session():
		print("[GameLauncher] Ya existe una sesión activa; se cancela el lanzamiento.")
		push_warning("Ya hay un minijuego activo; espera a que termine antes de iniciar otro.")
		return false
	var app_stats := node.app_resource
	if app_stats == null or app_stats.scene == null:
		print("[GameLauncher] AppStats inválido para el nodo; se cancela.")
		push_warning("El nodo no tiene AppStats válido para lanzar.")
		return false
	var desktop := _get_desktop()
	if desktop == null:
		print("[GameLauncher] No se encontró Desktop para lanzar app %s" % app_stats.app_name)
		push_warning("No se encontró un Desktop para lanzar %s." % app_stats.app_name)
		return false
	if not desktop.has_method("open_app_from_stats"):
		print("[GameLauncher] Desktop no implementa open_app_from_stats; se cancela.")
		push_warning("El Desktop no expone open_app_from_stats; no se puede lanzar %s." % app_stats.app_name)
		return false
	var session_data = desktop.open_app_from_stats(app_stats)
	if typeof(session_data) != TYPE_DICTIONARY or session_data.is_empty():
		print("[GameLauncher] El Desktop no devolvió datos de sesión válidos.")
		return false
	if session_data.get("is_existing", false):
		print("[GameLauncher] La app %s ya estaba abierta; se requiere cerrar antes de reiniciar reto." % app_stats.app_name)
		push_warning("La app %s ya está abierta; ciérrala antes de iniciar el reto." % app_stats.app_name)
		return false
	
	var app_instance: Node = session_data.get("app", null)
	var panel_instance: Node = session_data.get("panel", null)
	if app_instance == null:
		return false

	# Asegurar que la app quede también en el taskbar aunque se lanzó desde el árbol
	if desktop != null and desktop.has_method("_ensure_taskbar_icon"):
		# Construir app_id igual que hace Desktop._get_app_id
		var _app_id: String = "unknown_app"
		if app_stats != null and app_stats.app_name != "":
			_app_id = app_stats.app_name
		elif app_stats != null and app_stats.scene != null:
			_app_id = app_stats.scene.resource_path
		# Instanciar preset de icono del proyecto y asignar appStats si aplica
		var icon_preset_path := "res://src/desktop/apps/appDesktopIcon.tscn"
		var preset: PackedScene = null
		var icon_instance: Node = null
		if ResourceLoader.exists(icon_preset_path):
			preset = load(icon_preset_path)
			if preset is PackedScene:
				icon_instance = preset.instantiate()
		# Si pudimos instanciar, asignar appStats si el nodo es AppButton (o usar meta como fallback)
		if icon_instance != null and app_stats != null:
			# AppButton (apps/AppsDesktop.gd) expone `appStats` como propiedad
			if icon_instance is AppButton:
				(icon_instance as AppButton).appStats = app_stats
			else:
				# fallback: attach as meta so Desktop/_instantiate_icon_copy can pick it up if needed
				icon_instance.set_meta("appStats", app_stats)
		# Pasar la instancia (o el nodo original si no hay instancia) al Desktop
		var source_for_taskbar: Node = null
		if icon_instance != null:
			source_for_taskbar = icon_instance
		elif panel_instance != null:
			source_for_taskbar = panel_instance
		else:
			source_for_taskbar = app_instance
		desktop._ensure_taskbar_icon(_app_id, source_for_taskbar)
	var node_id: int = node.get_instance_id()
	_active_session = {
		"node_id": node_id,
		"node": node,
		"app": app_instance,
		"panel": panel_instance,
		"completed": false
	}
	print("[GameLauncher] Sesión activa creada para nodo %d" % node_id)
	_prepare_app_interface(app_instance)
	_connect_lifecycle_signals(node_id, app_instance, panel_instance)
	return true

func notify_result_from_app(win: bool) -> void:
	print("[GameLauncher] Resultado recibido desde app: %s" % [win])
	if _active_session.is_empty() or _active_session.get("completed", false):
		return
	if tree_controller == null:
		return
	tree_controller.report_challenge_result(win)

func on_challenge_resolved(_node: TreeNode, win: bool) -> void:
	print("[GameLauncher] Challenge resuelto; win=%s" % [win])
	if _active_session.is_empty():
		return
	_active_session["completed"] = true
	var panel_instance: Node = _active_session.get("panel", null)
	if panel_instance != null and is_instance_valid(panel_instance):
		print("[GameLauncher] Cerrando panel tras resultado")
		panel_instance.queue_free()
	_cleanup_session_metadata()
	_active_session.clear()

func close_active_panel() -> void:
	print("[GameLauncher] Cerrando panel activo")
	if _active_session.is_empty():
		return
	var panel_instance: Node = _active_session.get("panel", null)
	if panel_instance != null and is_instance_valid(panel_instance):
		panel_instance.queue_free()
	_cleanup_session_metadata()
	_active_session.clear()

func _prepare_app_interface(app_instance: Node) -> void:
	if app_instance == null:
		return
	print("[GameLauncher] Preparando interfaz para app %s" % [app_instance])
	app_instance.set_meta("tree_challenge_notifier", Callable(self, "notify_result_from_app"))
	if tree_controller != null:
		app_instance.set_meta("tree_challenge_controller", tree_controller)
	if not _active_session.is_empty():
		app_instance.set_meta("tree_challenge_node_id", _active_session.get("node_id", -1))
	if app_instance.has_method("set_challenge_callback"):
		app_instance.call("set_challenge_callback", Callable(self, "notify_result_from_app"))
	elif app_instance.has_method("set_tree_challenge_reporter"):
		app_instance.call("set_tree_challenge_reporter", Callable(self, "notify_result_from_app"))

func _connect_lifecycle_signals(node_id: int, app_instance: Node, panel_instance: Node) -> void:
	print("[GameLauncher] Conectando señales de ciclo de vida para nodo %d" % node_id)
	if app_instance != null:
		for signal_name in COMPLETION_SIGNALS:
			if app_instance.has_signal(signal_name):
				var completion_callable := Callable(self, "_on_app_signal_completed").bind(node_id)
				_app_active_store("completion_signal", signal_name)
				_app_active_store("completion_callable", completion_callable)
				if not app_instance.is_connected(signal_name, completion_callable):
					app_instance.connect(signal_name, completion_callable)
				break
		var app_exit_callable := Callable(self, "_on_app_tree_exiting").bind(node_id)
		_app_active_store("app_exit_callable", app_exit_callable)
		if not app_instance.is_connected("tree_exiting", app_exit_callable):
			app_instance.tree_exiting.connect(app_exit_callable)
	if panel_instance != null:
		var panel_exit_callable := Callable(self, "_on_panel_tree_exiting").bind(node_id)
		_app_active_store("panel_exit_callable", panel_exit_callable)
		if not panel_instance.is_connected("tree_exiting", panel_exit_callable):
			panel_instance.tree_exiting.connect(panel_exit_callable)

func _on_app_signal_completed(node_id: int, win = true) -> void:
	print("[GameLauncher] Señal de finalización capturada; node_id=%d win=%s" % [node_id, win])
	if _should_ignore(node_id):
		return
	notify_result_from_app(bool(win))

func _on_app_tree_exiting(node_id: int) -> void:
	print("[GameLauncher] App salió del árbol; node_id=%d" % node_id)
	if _should_ignore(node_id):
		return
	notify_result_from_app(false)

func _on_panel_tree_exiting(node_id: int) -> void:
	print("[GameLauncher] Panel salió del árbol; node_id=%d" % node_id)
	if _should_ignore(node_id):
		return
	notify_result_from_app(false)

func _should_ignore(node_id: int) -> bool:
	if _active_session.is_empty():
		return true
	if _active_session.get("completed", false):
		return true
	return _active_session.get("node_id", -1) != node_id

func _cleanup_session_metadata() -> void:
	print("[GameLauncher] Limpiando metadata de sesión activa")
	if _active_session.is_empty():
		return
	var app_instance: Node = _active_session.get("app", null)
	var panel_instance: Node = _active_session.get("panel", null)
	if app_instance != null:
		if app_instance.has_meta("tree_challenge_notifier"):
			app_instance.remove_meta("tree_challenge_notifier")
		if app_instance.has_meta("tree_challenge_controller"):
			app_instance.remove_meta("tree_challenge_controller")
		if app_instance.has_meta("tree_challenge_node_id"):
			app_instance.remove_meta("tree_challenge_node_id")
		var completion_signal = _active_session.get("completion_signal", "")
		var completion_callable = _active_session.get("completion_callable", null)
		if completion_signal != "" and completion_callable != null and app_instance.has_signal(completion_signal) and app_instance.is_connected(completion_signal, completion_callable):
			app_instance.disconnect(completion_signal, completion_callable)
		var app_exit_callable = _active_session.get("app_exit_callable", null)
		if app_exit_callable != null and app_instance.is_connected("tree_exiting", app_exit_callable):
			app_instance.tree_exiting.disconnect(app_exit_callable)
	if panel_instance != null:
		var panel_exit_callable = _active_session.get("panel_exit_callable", null)
		if panel_exit_callable != null and panel_instance.is_connected("tree_exiting", panel_exit_callable):
			panel_instance.tree_exiting.disconnect(panel_exit_callable)

func _app_active_store(key: String, value) -> void:
	_active_session[key] = value

func _get_desktop() -> Node:
	if _desktop != null and is_instance_valid(_desktop):
		return _desktop
	var tree := get_tree()
	if tree == null:
		return null
	var candidates := tree.get_nodes_in_group(DESKTOP_GROUP)
	if not candidates.is_empty():
		_desktop = candidates[0]
		return _desktop
	var root := tree.get_root()
	if root == null:
		return null
	_desktop = root.find_child("Desktop", true, false)
	return _desktop
