# ClippyEvent.gd
# Resource class for Clippy assistant events
# Godot 4.5+
# 
# Usage:
#   var event = ClippyEvent.new()
#   event.event_type = ClippyEvent.EventType.TUTORIAL_START
#   event.context_id = "tree_navigation_intro"
#   event.payload = {"node_count": 5}
#   clippy_controller.handle_event(event)

class_name ClippyEvent
extends Resource

## Event type enumeration
enum EventType {
	TUTORIAL_START, ## Fired when a tutorial section begins
	MINI_GAME_START, ## Fired when a minigame is launched
	PLAYER_ERROR, ## Fired when player makes an error
	PROGRESS_UPDATE, ## Fired when player completes a milestone
	ACHIEVEMENT, ## Fired when player unlocks an achievement
	TREE_NODE_ENTERED, ## Fired when entering a tree node
	HINT_REQUESTED, ## Fired when player requests a hint
	GAME_COMPLETED ## Fired when game is completed
}

## Type of event
@export var event_type: EventType = EventType.TUTORIAL_START

## Level or area identifier (e.g., "level_1", "tutorial_area")
@export var level_id: String = ""

## Specific context within the level (e.g., "port_scanner", "sql_injection")
@export var context_id: String = ""

## Additional event data (flexible dictionary for event-specific information)
## Examples:
##   PLAYER_ERROR: {"error_code": "wrong_answer", "attempt": 2}
##   MINI_GAME_START: {"game_type": "port_scanner", "difficulty": "normal"}
##   PROGRESS_UPDATE: {"completion": 0.75, "nodes_visited": 12}
@export var payload: Dictionary = {}

## Timestamp when event was created (auto-set)
var timestamp: float = 0.0

func _init() -> void:
	timestamp = Time.get_ticks_msec() / 1000.0

## Validates that the event has required fields based on type
func is_valid() -> bool:
	match event_type:
		EventType.TUTORIAL_START:
			return context_id != ""
		EventType.MINI_GAME_START:
			return context_id != "" and payload.has("game_type")
		EventType.PLAYER_ERROR:
			return payload.has("error_code")
		EventType.PROGRESS_UPDATE:
			return payload.has("completion")
		EventType.ACHIEVEMENT:
			return context_id != ""
		EventType.TREE_NODE_ENTERED:
			return context_id != ""
		EventType.HINT_REQUESTED:
			return true # No specific requirements
		EventType.GAME_COMPLETED:
			return true
		_:
			return false

## Returns a human-readable description of the event (for debugging)
func get_description() -> String:
	var type_name = EventType.keys()[event_type]
	return "ClippyEvent[%s | level=%s | context=%s | payload=%s]" % [
		type_name, level_id, context_id, str(payload)
	]

## Serializes event to Dictionary for saving/networking
func to_dict() -> Dictionary:
	return {
		"event_type": event_type,
		"level_id": level_id,
		"context_id": context_id,
		"payload": payload,
		"timestamp": timestamp
	}

## Deserializes event from Dictionary
static func from_dict(data: Dictionary) -> ClippyEvent:
	var event = ClippyEvent.new()
	event.event_type = data.get("event_type", EventType.TUTORIAL_START)
	event.level_id = data.get("level_id", "")
	event.context_id = data.get("context_id", "")
	event.payload = data.get("payload", {})
	event.timestamp = data.get("timestamp", 0.0)
	return event
