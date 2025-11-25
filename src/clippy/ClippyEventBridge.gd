# ClippyEventBridge.gd
# EventBus subscriber that converts game events to ClippyEvents
# Godot 4.5+
#
# This bridge decouples Clippy from game code by:
# - Subscribing to EventBus signals
# - Converting them to ClippyEvent instances
# - Forwarding to ClippyController
#
# Integration: Add as autoload AFTER EventBus and Clippy
# Project Settings > Autoload:
#   - EventBus (already exists)
#   - Clippy (ClippyController.gd)
#   - ClippyBridge (this file)

extends Node

## Reference to ClippyController (set in _ready)
var clippy: ClippyController = null

func _ready() -> void:
	print("[ClippyBridge] Initializing...")
	
	# Wait one frame to ensure Clippy autoload is ready
	await get_tree().process_frame
	
	# Get Clippy reference (assumes it's added as autoload named "Clippy")
	if has_node("/root/Clippy"):
		clippy = get_node("/root/Clippy")
		print("[ClippyBridge] ✓ Found Clippy autoload")
		_connect_eventbus_signals()
		print("[ClippyBridge] ✓ Connected to EventBus signals")
		print("[ClippyBridge] Ready and listening for events")
	else:
		push_error("[ClippyBridge] ✗ Clippy autoload not found! Add ClippyController.gd as 'Clippy' autoload")

## Connect all relevant EventBus signals
func _connect_eventbus_signals() -> void:
	# Navigation events
	#EventBus.player_moved.connect(_on_player_moved)
	#EventBus.node_visited.connect(_on_node_visited)
	#EventBus.node_discovered.connect(_on_node_discovered)
	#EventBus.navigation_ready.connect(_on_navigation_ready)
	EventBus.navigation_blocked.connect(_on_navigation_blocked)
	
	# Challenge events
	EventBus.challenge_started.connect(_on_challenge_started)
	EventBus.challenge_completed.connect(_on_challenge_completed)
	EventBus.challenge_state_changed.connect(_on_challenge_state_changed)
	
	# Game events
	#EventBus.game_over.connect(_on_game_over)
	#EventBus.score_changed.connect(_on_score_changed)
	
	# Resource events
	#EventBus.resources_loaded.connect(_on_resources_loaded)

## Send event to Clippy
func _send_clippy_event(event: ClippyEvent) -> void:
	if clippy != null:
		print("[ClippyBridge] → Sending event: ", event.get_description())
		clippy.handle_event(event)
	else:
		push_warning("[ClippyBridge] Cannot send event - Clippy is null")

# ============================================================================
# EVENT HANDLERS - Navigation
# ============================================================================

const NODE_TYPE_UNKNOWN := -1

func _on_player_moved(node: TreeNode) -> void:
	var meta := _describe_node(node)
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TREE_NODE_ENTERED
	event.context_id = meta.label
	event.payload = {
		"node_type": meta.type,
		"is_challenge": (node != null and node.tipo == TreeNode.NodosJuego.DESAFIO),
		"node_label": meta.label
	}
	event.priority = ClippyEvent.Priority.LOW
	event.expiration_time = 3.0 # Expire quickly if player keeps moving
	_send_clippy_event(event)

func _on_node_visited(node: TreeNode) -> void:
	var meta := _describe_node(node)
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {
		"node_id": meta.id,
		"node_label": meta.label,
		"node_type": meta.type,
		"action": "visited"
	}
	event.priority = ClippyEvent.Priority.LOW
	event.expiration_time = 5.0
	_send_clippy_event(event)

func _on_node_discovered(node: TreeNode) -> void:
	var meta := _describe_node(node)
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TREE_NODE_ENTERED
	event.context_id = "new_node_discovered"
	event.payload = {
		"node_id": meta.id,
		"node_label": meta.label,
		"node_type": meta.type,
		"discovered": true
	}
	event.priority = ClippyEvent.Priority.NORMAL
	event.expiration_time = 10.0
	_send_clippy_event(event)

func _on_navigation_ready() -> void:
	# Tutorial start - game navigation is ready
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "tree_navigation_intro"
	event.payload = {"section": "navigation"}
	event.priority = ClippyEvent.Priority.NORMAL
	_send_clippy_event(event)

func _on_navigation_blocked(reason: String) -> void:
	# Player error - navigation blocked
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {
		"error_code": "navigation_blocked",
		"reason": reason
	}
	event.priority = ClippyEvent.Priority.CRITICAL
	_send_clippy_event(event)

# ============================================================================
# EVENT HANDLERS - Challenges
# ============================================================================

func _on_challenge_started(node: TreeNode) -> void:
	# Minigame start
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	
	# Determine game type from node
	var node_id = "unknown"
	if node:
		node_id = str(node.get_instance_id())
		if node.has_app_resource() and node.app_resource:
			node_id = node.app_resource.app_name

	# Determine game type from node
	var game_type = "unknown"
	if node and node.has_meta("challenge_type"):
		game_type = node.get_meta("challenge_type")
	elif node and node.has_app_resource() and node.app_resource:
		# Try to extract from app name
		if "port_scanner" in node.app_resource.app_name.to_lower():
			game_type = "port_scanner"
		elif "sql" in node.app_resource.app_name.to_lower():
			game_type = "sql_injection"
		elif "phishing" in node.app_resource.app_name.to_lower():
			game_type = "email_phishing"
		elif "password" in node.app_resource.app_name.to_lower():
			game_type = "password_cracker"
		elif "network" in node.app_resource.app_name.to_lower():
			game_type = "network_defender"
	
	event.context_id = game_type
	event.payload = {
		"game_type": game_type,
		"node_id": node_id
	}
	event.priority = ClippyEvent.Priority.HIGH
	_send_clippy_event(event)

func _on_challenge_completed(node: TreeNode, win: bool) -> void:
	if win:
		# Achievement unlocked
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.ACHIEVEMENT
		event.context_id = "challenge_completed"
		var node_id = "unknown"
		if node:
			node_id = str(node.get_instance_id())
			
		event.payload = {
			"node_id": node_id,
			"success": true
		}
		event.priority = ClippyEvent.Priority.HIGH
		_send_clippy_event(event)
	else:
		# Player error
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.PLAYER_ERROR
		var node_id = "unknown"
		if node:
			node_id = str(node.get_instance_id())

		event.payload = {
			"error_code": "challenge_failed",
			"node_id": node_id
		}
		event.priority = ClippyEvent.Priority.CRITICAL
		_send_clippy_event(event)

func _on_challenge_state_changed(_old_state: int, _new_state: int) -> void:
	# Could track challenge progress
	pass

# ============================================================================
# EVENT HANDLERS - Game
# ============================================================================

func _on_game_over(win: bool) -> void:
	if win:
		# Game completed!
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.GAME_COMPLETED
		event.payload = {"victory": true}
		event.priority = ClippyEvent.Priority.HIGH
		_send_clippy_event(event)
	else:
		# Game over - show encouragement
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.PLAYER_ERROR
		event.payload = {
			"error_code": "game_over",
			"can_retry": true
		}
		event.priority = ClippyEvent.Priority.CRITICAL
		_send_clippy_event(event)

func _on_score_changed(old_score: int, new_score: int, reason: String) -> void:
	# Progress update based on score change
	if new_score > old_score:
		var reason_code := _reason_to_code(reason)
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
		event.payload = {
			"old_score": old_score,
			"new_score": new_score,
			"delta": new_score - old_score,
			"reason": reason,
			"reason_code": reason_code
		}
		event.priority = ClippyEvent.Priority.LOW
		event.expiration_time = 5.0
		_send_clippy_event(event)

# ============================================================================
# EVENT HANDLERS - Resources
# ============================================================================

func _on_resources_loaded(success: bool) -> void:
	if success:
		# Tutorial - game is ready
		var event = ClippyEvent.new()
		event.event_type = ClippyEvent.EventType.TUTORIAL_START
		event.context_id = "game_start"
		event.payload = {"section": "welcome"}
		event.priority = ClippyEvent.Priority.NORMAL
		_send_clippy_event(event)

func _describe_node(node: TreeNode) -> Dictionary:
	var node_id := "unknown"
	var node_label := "unknown"
	var node_type := NODE_TYPE_UNKNOWN
	if node != null:
		node_type = node.tipo
		node_id = str(node.get_instance_id())
		node_label = node_id
		if node.has_app_resource() and node.app_resource:
			if node.app_resource.app_name != "":
				node_label = node.app_resource.app_name
			else:
				node_label = node_id
	return {
		"id": node_id,
		"label": node_label,
		"type": node_type
	}

func _reason_to_code(reason: String) -> String:
	var normalized := reason.strip_edges().to_lower()
	normalized = normalized.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
	match normalized:
		"pista visitada":
			return "hint_node"
		"desafio visitado":
			return "challenge_visit"
		"meta alcanzada":
			return "goal_reached"
		_:
			return "generic"
