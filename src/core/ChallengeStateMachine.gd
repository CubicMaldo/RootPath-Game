class_name ChallengeStateMachine
extends RefCounted

## Gestiona los estados del sistema de desafíos
## Reemplaza múltiples booleanos por una máquina de estados clara

enum State {
	IDLE,           # Sin desafío activo
	STARTING,       # Iniciando desafío
	ACTIVE,         # Desafío en progreso
	RESOLVING,      # Procesando resultado
	RETRY_PENDING   # Esperando para reintentar
}

var current_state: State = State.IDLE
var current_challenge_node: TreeNode = null
var challenge_results: Dictionary = {}  # node_id -> bool

func _init():
	#print("[ChallengeStateMachine] Inicializado")
	pass

## Intenta iniciar un desafío para el nodo dado
func start_challenge(node: TreeNode) -> bool:
	if not can_start_challenge(node):
		print("[ChallengeStateMachine] No se puede iniciar desafío en estado %s" % State.keys()[current_state])
		return false
	
	var old_state := current_state
	current_state = State.STARTING
	current_challenge_node = node
	
	#print("[ChallengeStateMachine] Desafío iniciado para nodo %s" % node)
	EventBus.challenge_state_changed.emit(old_state, current_state)
	
	# Transición automática a ACTIVE
	_transition_to(State.ACTIVE)
	return true

## Marca el desafío como activo
func _transition_to(new_state: State) -> void:
	if current_state == new_state:
		return
	
	var old_state := current_state
	current_state = new_state
	print("[ChallengeStateMachine] Transición: %s -> %s" % [State.keys()[old_state], State.keys()[new_state]])
	EventBus.challenge_state_changed.emit(old_state, new_state)

## Resuelve el desafío actual con el resultado dado
func resolve_challenge(win: bool) -> void:
	if current_state != State.ACTIVE:
		push_warning("[ChallengeStateMachine] Intento de resolver desafío en estado inválido: %s" % State.keys()[current_state])
		return
	
	_transition_to(State.RESOLVING)
	
	if current_challenge_node != null:
		var node_id := current_challenge_node.get_instance_id()
		if win:
			challenge_results[node_id] = true
			current_challenge_node.challenge_completed = true
			current_challenge_node.challenge_result = true
			print("[ChallengeStateMachine] Desafío ganado para nodo %d" % node_id)
		else:
			challenge_results.erase(node_id)
			current_challenge_node.challenge_completed = false
			current_challenge_node.challenge_result = false
			print("[ChallengeStateMachine] Desafío perdido para nodo %d" % node_id)
		
		EventBus.challenge_completed.emit(current_challenge_node, win)
	
	# Transición según resultado
	if win:
		reset()
	else:
		_transition_to(State.RETRY_PENDING)

## Reinicia el estado a IDLE
func reset() -> void:
	var was_active := is_challenge_active()
	_transition_to(State.IDLE)
	current_challenge_node = null
	print("[ChallengeStateMachine] Reiniciado a IDLE")
	
	# Notificar que la navegación está disponible nuevamente
	if was_active:
		EventBus.navigation_blocked.emit("")  # String vacío = desbloqueado

## Marca que el retry está listo para ejecutarse
func ready_for_retry() -> void:
	if current_state == State.RETRY_PENDING:
		_transition_to(State.IDLE)

## Verifica si se puede iniciar un desafío
func can_start_challenge(node: TreeNode) -> bool:
	if current_state != State.IDLE:
		return false
	if node == null or not node.has_app_resource():
		return false
	var node_id := node.get_instance_id()
	if challenge_results.has(node_id):
		return false  # Ya completado
	if node.challenge_completed:
		return false
	return true

## Verifica si la navegación está permitida
func can_navigate() -> bool:
	return current_state in [State.IDLE, State.RETRY_PENDING]

## Verifica si hay un desafío activo
func is_challenge_active() -> bool:
	return current_state in [State.STARTING, State.ACTIVE, State.RESOLVING]

## Obtiene el resultado de un desafío previo
func get_challenge_result(node: TreeNode):
	if node == null:
		return null
	var node_id := node.get_instance_id()
	return challenge_results.get(node_id, null)

## Limpia todos los resultados
func clear_results() -> void:
	challenge_results.clear()
	print("[ChallengeStateMachine] Resultados limpiados")
