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

## Priority level for event processing
enum Priority {
	LOW = 0, ## Ambient hints, flavor text
	NORMAL = 1, ## Tutorial steps, standard info
	HIGH = 2, ## Achievements, minigame starts
	CRITICAL = 3 ## Errors, warnings
}

## Priority of this event
@export var priority: Priority = Priority.NORMAL

## Time to live in seconds (0.0 = infinite)
## If event sits in queue longer than this, it will be discarded
@export var expiration_time: float = 0.0

## Timestamp when event was created (auto-set)
var timestamp: float = 0.0

func _init() -> void:
	timestamp = Time.get_ticks_msec() / 1000.0

## Validates that the event has required fields based on type
## Now uses ClippyEventSchema for robust validation
func is_valid() -> bool:
	var result = ClippyEventSchema.validate_event(self)
	
	# Print validation errors for debugging
	if not result.valid:
		push_warning("ClippyEvent validation failed: %s" % get_description())
		for error in result.errors:
			push_warning("  - %s" % error)
	
	# Print warnings if any
	if not result.warnings.is_empty():
		for warning in result.warnings:
			push_warning("  ⚠ %s" % warning)
	
	return result.valid

## Get detailed validation result (for debugging and testing)
func validate_detailed() -> ClippyEventSchema.ValidationResult:
	return ClippyEventSchema.validate_event(self)

## Returns a human-readable description of the event (for debugging)
func get_description() -> String:
	var type_name = EventType.keys()[event_type]
	var priority_name = Priority.keys()[priority]
	return "ClippyEvent[%s | prio=%s | level=%s | context=%s | payload=%s]" % [
		type_name, priority_name, level_id, context_id, str(payload)
	]

## Serializes event to Dictionary for saving/networking
func to_dict() -> Dictionary:
	return {
		"event_type": event_type,
		"level_id": level_id,
		"context_id": context_id,
		"payload": payload,
		"timestamp": timestamp,
		"priority": priority,
		"expiration_time": expiration_time
	}

## Deserializes event from Dictionary
static func from_dict(data: Dictionary) -> ClippyEvent:
	var event = ClippyEvent.new()
	event.event_type = data.get("event_type", EventType.TUTORIAL_START)
	event.level_id = data.get("level_id", "")
	event.context_id = data.get("context_id", "")
	event.payload = data.get("payload", {})
	event.timestamp = data.get("timestamp", 0.0)
	event.priority = data.get("priority", Priority.NORMAL)
	event.expiration_time = data.get("expiration_time", 0.0)
	return event
