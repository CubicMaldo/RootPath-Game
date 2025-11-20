# ClippyController.gd
# Main controller for Clippy assistant system
# Godot 4.5+
#
# Architecture:
# - State machine (IDLE, LISTENING, COMPOSING, WAITING_FOR_ACK, ERROR)
# - Event queue with timeout handling
# - Signal-based communication
# - Integration with ClippyResources for documentation
#
# Usage:
#   # Add to scene tree as autoload or child node
#   var clippy = ClippyController.new()
#   add_child(clippy)
#   clippy.ready_to_display.connect(_on_clippy_text_ready)
#   
#   # Send event
#   var event = ClippyEvent.new()
#   event.event_type = ClippyEvent.EventType.TUTORIAL_START
#   clippy.handle_event(event)

class_name ClippyController
extends Node

## State enumeration for state machine
enum State {
	IDLE, ## No active processing
	LISTENING, ## Receiving events
	COMPOSING, ## Generating response text
	WAITING_FOR_ACK, ## Waiting for user acknowledgment
	ERROR ## Error state
}

## Emitted when text is ready to display
## @param text: The generated text to show to player
signal ready_to_display(text: String)

## Emitted when state changes
## @param old_state: Previous state
## @param new_state: New state
signal state_changed(old_state: State, new_state: State)

## Emitted when error occurs
## @param error_msg: Error message
signal error_occurred(error_msg: String)

## Emitted when processing is complete
signal processing_complete()

## Current state of controller
var current_state: State = State.IDLE

## Event queue for processing
var _event_queue: Array[ClippyEvent] = []

## Resources manager
var _resources: ClippyResources = null

## Timer for event processing timeout
var _timeout_timer: Timer = null

## Maximum time to process event (seconds)
@export var event_timeout: float = 5.0

## Whether to auto-load documentation on ready
@export var auto_load_docs: bool = true

## Path to main README
@export var readme_path: String = "res://README.md"

## Progress state tracking
var _progress_state: Dictionary = {
	"events_processed": 0,
	"errors_count": 0,
	"last_event_type": - 1,
	"last_event_time": 0.0,
	"total_display_count": 0
}

func _ready() -> void:
	_initialize_resources()
	_initialize_timeout_timer()
	
	if auto_load_docs:
		_load_documentation()

## Initialize resources manager
func _initialize_resources() -> void:
	_resources = ClippyResources.new()
	add_child(_resources)

## Initialize timeout timer
func _initialize_timeout_timer() -> void:
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.timeout.connect(_on_timeout)
	add_child(_timeout_timer)

## Load all documentation files
func _load_documentation() -> void:
	_resources.load_project_docs(readme_path)
	
	# Load minigame documentation
	var minigames = [
		{"type": "port_scanner", "path": "res://scenes/minigames/port_scanner/README.md"},
		{"type": "sql_injection", "path": "res://scenes/minigames/sql_injection/README.md"},
		{"type": "email_phishing", "path": "res://scenes/minigames/email_phishing/README.md"},
		{"type": "password_cracker", "path": "res://scenes/minigames/password_cracker/README.md"},
		{"type": "network_defender", "path": "res://scenes/minigames/network_defender/README.md"}
	]
	
	for minigame in minigames:
		_resources.load_minigame_doc(minigame.type, minigame.path)

## Main event handler - PUBLIC API
## Processes an event and returns generated text
func handle_event(event: ClippyEvent) -> String:
	print("[ClippyController] Received event: ", event.get_description() if event else "NULL")
	
	if event == null:
		_handle_error("Received null event")
		return ""
	
	if not event.is_valid():
		_handle_error("Received invalid event: " + event.get_description())
		return ""
	
	print("[ClippyController] Event is valid, adding to queue")
	
	# Add to queue
	_event_queue.append(event)
	
	# Process if idle
	if current_state == State.IDLE:
		_process_next_event()
	
	# Return empty string immediately (signal will fire when ready)
	return ""

## Process next event in queue
func _process_next_event() -> void:
	if _event_queue.is_empty():
		_change_state(State.IDLE)
		processing_complete.emit()
		return
	
	_change_state(State.LISTENING)
	var event = _event_queue.pop_front()
	
	_change_state(State.COMPOSING)
	_timeout_timer.start(event_timeout)
	
	print("[ClippyController] Generating text for event...")
	
	# Generate text
	var text = _resources.get_text_for_event(event)
	
	print("[ClippyController] Generated text: ", text.substr(0, 50), "...")
	
	_timeout_timer.stop()
	
	# Update progress state
	_progress_state.events_processed += 1
	_progress_state.last_event_type = event.event_type
	_progress_state.last_event_time = Time.get_ticks_msec() / 1000.0
	_progress_state.total_display_count += 1
	
	# Emit signal
	_change_state(State.WAITING_FOR_ACK)
	print("[ClippyController] Emitting ready_to_display signal")
	ready_to_display.emit(text)
	
	# Auto-acknowledge after short delay to process next event
	await get_tree().create_timer(0.1).timeout
	acknowledge()

## Acknowledge current message and continue processing - PUBLIC API
func acknowledge() -> void:
	if current_state == State.WAITING_FOR_ACK:
		_process_next_event()

## Get current progress state - PUBLIC API
func get_progress_state() -> Dictionary:
	return _progress_state.duplicate()

## Clear event queue - PUBLIC API
func clear_queue() -> void:
	_event_queue.clear()
	_change_state(State.IDLE)

## Reset controller to initial state - PUBLIC API
func reset() -> void:
	clear_queue()
	_progress_state = {
		"events_processed": 0,
		"errors_count": 0,
		"last_event_type": - 1,
		"last_event_time": 0.0,
		"total_display_count": 0
	}
	_change_state(State.IDLE)

## Change state and emit signal
func _change_state(new_state: State) -> void:
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		state_changed.emit(old_state, new_state)

## Handle error condition
func _handle_error(error_msg: String) -> void:
	push_error("ClippyController: " + error_msg)
	_progress_state.errors_count += 1
	_change_state(State.ERROR)
	error_occurred.emit(error_msg)
	
	# Recover to IDLE after error
	await get_tree().create_timer(0.5).timeout
	_change_state(State.IDLE)

## Handle timeout
func _on_timeout() -> void:
	_handle_error("Event processing timeout exceeded (%s seconds)" % event_timeout)
	_process_next_event()

## Manually load documentation - PUBLIC API
func load_project_docs(path: String) -> void:
	_resources.load_project_docs(path)
