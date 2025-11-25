class_name TreeAppController
extends Node

## Orchestrates the different systems without coupling them together
## This is the ONLY place where systems interact

# DEPRECATED: Usar EventBus en su lugar
signal player_moved(node: TreeNode)
signal game_over(win: bool)
signal challenge_started(node: TreeNode)
signal challenge_finished(node: TreeNode, win: bool)

var tree: Arbol
var navigator: PlayerNavigator
var visibility: VisibilityTracker
var game_launcher: GameLauncher

# Nuevos sistemas
var challenge_state: ChallengeStateMachine
var resource_service: ResourceService

var score: int = 0
var _last_completed_node: TreeNode = null # Nueva variable para tracking

func _init():
	navigator = PlayerNavigator.new()
	visibility = VisibilityTracker.new()
	challenge_state = ChallengeStateMachine.new()
	resource_service = ResourceService.new()
	# Connect signals
	navigator.node_changed.connect(_on_player_moved)
	visibility.node_visited.connect(_on_node_visited)
	# Connect EventBus signals
	EventBus.challenge_completed.connect(_on_challenge_completed)
	EventBus.score_changed.connect(_on_score_changed)

func _ready():
	game_launcher = GameLauncher.new()
	add_child(game_launcher)
	add_child(visibility)
	game_launcher.setup(self)
	#print("[TreeAppController] Ready - launcher inicializado")

func setup_game(seed_value: int = -1, app_resources: Array[AppStats] = [], app_db: AppDatabase = null) -> void:
	#print("[TreeAppController] setup_game llamado seed=%d" % seed_value)
	if game_launcher == null:
		game_launcher = GameLauncher.new()
		add_child(game_launcher)
		if game_launcher.has_method("setup"):
			game_launcher.setup(self)
	
	tree = Arbol.new()
	challenge_state.clear_results()
	score = 0
	var database_to_use: AppDatabase = app_db if app_db != null else resource_service.load_app_database()
	if database_to_use != null:
		#print("[TreeAppController] Usando AppDatabase con %d desafios/%d pistas/%d meta" % [
		#	database_to_use.desafio_apps.size(),
		#	database_to_use.pista_apps.size(),
		#	database_to_use.meta_apps.size()
		#])
		tree.set_app_database(database_to_use)
		if not app_resources.is_empty():
			push_warning("Se proporcionaron app_resources manualmente, pero AppDatabase tiene prioridad; se ignorarán.")
	else:
		print("[TreeAppController] Cargando recursos por defecto")
		var resources_to_use := app_resources if not app_resources.is_empty() else resource_service.load_default_app_resources()
		tree.set_available_app_resources(resources_to_use)
	tree.generar_arbol_controlado(seed_value)
	# Initialize player position
	navigator.set_current_node(tree.raiz)
	# Set up initial visibility
	visibility.visit_node(tree.raiz)
	visibility.reveal_children(tree.raiz)
	#print("[TreeAppController] Juego inicializado; nodo raíz visible")

func navigate_left() -> bool:
	if not challenge_state.can_navigate():
		EventBus.navigation_blocked.emit("Challenge in progress")
		print("[TreeAppController] Movimiento bloqueado - desafío activo")
		return false
	if navigator.move_left():
		_handle_navigation()
		return true
	return false

func navigate_right() -> bool:
	if not challenge_state.can_navigate():
		EventBus.navigation_blocked.emit("Challenge in progress")
		print("[TreeAppController] Movimiento bloqueado - desafío activo")
		return false
	if navigator.move_right():
		_handle_navigation()
		return true
	return false

func navigate_up() -> bool:
	if not challenge_state.can_navigate():
		EventBus.navigation_blocked.emit("Challenge in progress")
		print("[TreeAppController] Movimiento bloqueado - desafío activo")
		return false
	if navigator.move_to_parent():
		_handle_navigation()
		return true
	return false

func navigate_down() -> bool:
	if not challenge_state.can_navigate():
		EventBus.navigation_blocked.emit("Challenge in progress")
		print("[TreeAppController] Movimiento bloqueado - desafío activo")
		return false
	if can_navigate_right():
		navigate_right()
		return true
	elif can_navigate_left():
		navigate_left()
		return true
	else:
		return false

func _handle_navigation() -> void:
	var current = navigator.current_node
	print("[TreeAppController] Manejo de navegación: nodo actual %s" % [_node_type_name(current)])
	# Mark as visited
	visibility.visit_node(current)
	# Reveal children
	visibility.reveal_children(current)
	# Check for game end
	if current.tipo == Arbol.NodosJuego.FINAL:
		EventBus.game_over.emit(true)
		game_over.emit(true)
		print("[TreeAppController] Nodo FINAL alcanzado, juego terminado.")
		return
	# Emit player moved events (handled elsewhere for challenges)
	EventBus.player_moved.emit(current)
	player_moved.emit(current)

func _on_player_moved(_old_node: TreeNode, new_node: TreeNode) -> void:
	print("[TreeAppController] Player moved to a %s" % [_node_type_name(new_node)])
	visibility.move_to_node(new_node)
	# If the node is a puzzle (PISTA), just reveal deepest leaf and do not launch an app
	if new_node.tipo == Arbol.NodosJuego.PISTA:
		visibility.forced_discovery(tree.obtener_hoja_mas_profunda())
		print("[TreeAppController] Nodo tipo PISTA, no se lanza app.")
		return
	# Only DESAFIO nodes launch apps; other types never spawn challenges
	if new_node.tipo != Arbol.NodosJuego.DESAFIO:
		print("[TreeAppController] Nodo %s no requiere app interactiva." % [_node_type_name(new_node)])
		return
	# Validate AppStats presence
	if not new_node.has_app_resource():
		push_warning("[TreeAppController] Nodo sin AppStats, no se lanza app.")
		return
	if new_node.app_resource.scene == null:
		push_warning("[TreeAppController] AppStats sin escena, no se lanza app.")
		return
	# Launch the app and start challenge
	if game_launcher.launch_node_app(new_node):
		print("[TreeAppController] Lanzamiento aprobado; iniciando reto")
		if challenge_state.start_challenge(new_node):
			EventBus.challenge_started.emit(new_node)
			challenge_started.emit(new_node)

func _on_node_visited(node: TreeNode) -> void:
	var points := 0
	var reason := ""
	match node.tipo:
		Arbol.NodosJuego.PISTA:
			points = 10
			reason = "Pista visitada"
		Arbol.NodosJuego.DESAFIO:
			points = 5
			reason = "Desafío visitado"
		Arbol.NodosJuego.FINAL:
			points = 50
			reason = "Meta alcanzada"
	if points > 0:
		_add_score(points, reason)
	EventBus.node_visited.emit(node)

func _add_score(amount: int, reason: String) -> void:
	var old_score := score
	score += amount
	EventBus.score_changed.emit(old_score, score, reason)

func _on_score_changed(_old: int, _new: int, reason: String) -> void:
	print("[TreeAppController] Score: %d -> %d (%s)" % [_old, _new, reason])

func _node_type_name(node: TreeNode) -> String:
	if node == null:
		return "null"
	match node.tipo:
		Arbol.NodosJuego.INICIO: return "INICIO"
		Arbol.NodosJuego.DESAFIO: return "DESAFIO"
		Arbol.NodosJuego.PISTA: return "PISTA"
		Arbol.NodosJuego.FINAL: return "FINAL"
		_: return "UNKNOWN"

func get_current_node() -> TreeNode:
	return navigator.current_node

func can_navigate_left() -> bool:
	return challenge_state.can_navigate() and navigator.can_move_left()

func can_navigate_right() -> bool:
	return challenge_state.can_navigate() and navigator.can_move_right()

func can_navigate_up() -> bool:
	return challenge_state.can_navigate() and navigator.can_move_to_parent()

func can_navigate_down() -> bool:
	return challenge_state.can_navigate() and (navigator.can_move_right() or navigator.can_move_left())

func is_node_visible(node: TreeNode) -> bool:
	return visibility.is_discovered(node)

func is_challenge_active() -> bool:
	return challenge_state.is_challenge_active()

func get_active_challenge_node() -> TreeNode:
	return challenge_state.current_challenge_node

func get_challenge_result(node: TreeNode):
	return challenge_state.get_challenge_result(node)

func report_challenge_result(win: bool) -> void:
	if not challenge_state.is_challenge_active():
		push_warning("[TreeAppController] Se intentó reportar resultado sin reto activo.")
		return
	print("[TreeAppController] Recibido resultado de reto: win=%s" % [win])
	challenge_state.resolve_challenge(win)

func _on_challenge_completed(node: TreeNode, win: bool) -> void:
	print("[TreeAppController] Challenge completed callback: win=%s" % [win])
	_last_completed_node = node
	if game_launcher != null and game_launcher.has_method("on_challenge_resolved"):
		print("[TreeAppController] Notificando GameLauncher de resolución")
		game_launcher.on_challenge_resolved(node, win)
	if win:
		call_deferred("_unlock_navigation_after_win")
	else:
		challenge_finished.emit(node, win)
		if node != null:
			call_deferred("_retry_challenge_for_node", node)

func _unlock_navigation_after_win() -> void:
	print("[TreeAppController] Desbloqueando navegación después de victoria")
	await get_tree().process_frame
	if game_launcher != null and game_launcher.has_active_session():
		print("[TreeAppController] GameLauncher aún tiene sesión, esperando...")
		await get_tree().create_timer(0.1).timeout
	EventBus.navigation_ready.emit()
	if _last_completed_node != null:
		challenge_finished.emit(_last_completed_node, true)
		_last_completed_node = null
	print("[TreeAppController] Navegación lista - Estado: %s" % ChallengeStateMachine.State.keys()[challenge_state.current_state])

func _retry_challenge_for_node(node: TreeNode) -> void:
	print("[TreeAppController] Reintentando reto para nodo %s" % [node])
	if node == null:
		return
	if game_launcher == null:
		push_error("[TreeAppController] No hay GameLauncher para reintentar")
		return
	if game_launcher.has_active_session():
		print("[TreeAppController] GameLauncher aún tiene sesión activa; reintento cancelado")
		return
	await get_tree().process_frame
	if game_launcher.has_active_session():
		print("[TreeAppController] GameLauncher reporta sesión activa tras esperar; se pospone relanzamiento")
		call_deferred("_retry_challenge_for_node", node)
		return
	if node.challenge_completed:
		print("[TreeAppController] Nodo ya marcado como completado; no se relanza")
		return
	challenge_state.ready_for_retry()
	_launch_node_app(node)
func _launch_node_app(node: TreeNode) -> void:
	if game_launcher == null:
		push_error("[TreeAppController] GameLauncher no disponible")
		return
	if not challenge_state.can_start_challenge(node):
		print("[TreeAppController] No se puede iniciar desafío para este nodo")
		return
	if game_launcher.has_active_session():
		print("[TreeAppController] GameLauncher reporta sesión activa; no lanzar")
		return
	if game_launcher.launch_node_app(node):
		print("[TreeAppController] Lanzamiento aprobado; iniciando reto")
		if challenge_state.start_challenge(node):
			EventBus.challenge_started.emit(node)
			challenge_started.emit(node)
