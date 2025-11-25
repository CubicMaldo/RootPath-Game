extends Node

## Script de debug temporal para diagnosticar problemas de navegación
## INSTRUCCIONES:
## 1. Adjunta este script a cualquier nodo de tu escena principal (ej: UI, GameManager, etc.)
## 2. Presiona F3 durante el juego para ver el estado de navegación
## 3. Elimina este script cuando encuentres el problema

func _ready():
	#print("[NavigationDebugger] Presiona F3 para ver estado de navegación")
	#print("[NavigationDebugger] Presiona F4 para forzar actualización de UI")
	
	# Conectar a eventos para debug
	#EventBus.navigation_ready.connect(_on_navigation_ready)
	#EventBus.challenge_completed.connect(_on_challenge_completed)
	pass

func _on_navigation_ready():
	print("[NavigationDebugger] 🟢 NAVIGATION_READY evento recibido")

func _on_challenge_completed(node, win):
	print("[NavigationDebugger] Challenge completed: win=%s, node=%s" % [win, node])

func _input(_event):
	#if event is InputEventKey and event.pressed:
	#	if _event.keycode == KEY_F3:
	#		_print_navigation_state()
	#	elif _event.keycode == KEY_F4:
	#		_force_ui_update()
	pass

func _force_ui_update():
	print("[NavigationDebugger] Forzando actualización de UI...")
	# Emitir señal de navegación lista
	EventBus.navigation_ready.emit()
	print("[NavigationDebugger] Señal emitida")

func _print_navigation_state():
	print("\n========== NAVIGATION DEBUG ==========")
	
	if Global.treeMap == null:
		print("❌ Global.treeMap es NULL")
		return
	
	var controller = Global.treeMap
	
	# Estado del desafío
	print("\n--- Challenge State ---")
	print("Challenge active: ", controller.is_challenge_active())
	if controller.challenge_state:
		print("Current state: ", ChallengeStateMachine.State.keys()[controller.challenge_state.current_state])
		print("Current challenge node: ", controller.challenge_state.current_challenge_node)
	
	# Estado del GameLauncher
	print("\n--- GameLauncher State ---")
	if controller.game_launcher:
		print("Has active session: ", controller.game_launcher.has_active_session())
	else:
		print("❌ GameLauncher es NULL")
	
	# Capacidad de navegación
	print("\n--- Navigation Capabilities ---")
	print("Can navigate left: ", controller.can_navigate_left())
	print("Can navigate right: ", controller.can_navigate_right())
	print("Can navigate up: ", controller.can_navigate_up())
	print("Can navigate down: ", controller.can_navigate_down())
	
	# Nodo actual
	print("\n--- Current Node ---")
	var current = controller.get_current_node()
	if current:
		print("Node type: ", controller._node_type_name(current))
		print("Has app: ", current.has_app_resource())
		print("Challenge completed: ", current.challenge_completed)
	else:
		print("❌ Current node es NULL")
	
	print("======================================\n")
