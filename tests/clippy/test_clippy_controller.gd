# test_clippy_controller.gd
# Integration tests for ClippyController
# Godot 4.5+
#
# Tests event handling, state transitions, signal emissions

extends Node

var clippy: ClippyController = null
var last_text_received: String = ""
var signal_received: bool = false

func _ready() -> void:
	await run_all_tests()

## Setup test environment
func setup() -> void:
	clippy = ClippyController.new()
	clippy.auto_load_docs = false # Disable auto-load for faster tests
	add_child(clippy)
	clippy.ready_to_display.connect(_on_text_ready)
	last_text_received = ""
	signal_received = false

## Teardown test environment
func teardown() -> void:
	if clippy:
		clippy.queue_free()
	clippy = null

## Signal handler
func _on_text_ready(text: String) -> void:
	last_text_received = text
	signal_received = true

## Test: Basic event handling
func test_handle_tutorial_event() -> void:
	setup()
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "intro"
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	assert(signal_received, "Signal should be emitted")
	assert(last_text_received != "", "Text should be generated")
	print("✓ test_handle_tutorial_event PASSED")
	
	teardown()

## Test: Minigame event handling
func test_handle_minigame_event() -> void:
	setup()
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "port_scanner"
	event.payload = {"game_type": "port_scanner"}
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	assert(signal_received, "Signal should be emitted for minigame")
	print("✓ test_handle_minigame_event PASSED")
	
	teardown()

## Test: Error event handling
func test_handle_error_event() -> void:
	setup()
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {"error_code": "wrong_answer", "attempt": 1}
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	assert(signal_received, "Signal should be emitted for error")
	print("✓ test_handle_error_event PASSED")
	
	teardown()

## Test: Multiple events in queue
func test_event_queue() -> void:
	setup()
	
	var event1 = ClippyEvent.new()
	event1.event_type = ClippyEvent.EventType.TUTORIAL_START
	event1.context_id = "intro"
	
	var event2 = ClippyEvent.new()
	event2.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event2.payload = {"completion": 0.5}
	
	clippy.handle_event(event1)
	clippy.handle_event(event2)
	
	await get_tree().create_timer(0.5).timeout
	
	var state = clippy.get_progress_state()
	assert(state.events_processed >= 2, "Should process multiple events")
	print("✓ test_event_queue PASSED")
	
	teardown()

## Test: Invalid event handling
func test_invalid_event() -> void:
	setup()
	
	var error_occurred = false
	clippy.error_occurred.connect(func(_msg): error_occurred = true)
	
	# Create invalid event (no context_id for TUTORIAL_START)
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	assert(error_occurred, "Error should be emitted for invalid event")
	print("✓ test_invalid_event PASSED")
	
	teardown()

## Test: Null event handling
func test_null_event() -> void:
	setup()
	
	var error_occurred = false
	clippy.error_occurred.connect(func(_msg): error_occurred = true)
	
	clippy.handle_event(null)
	await get_tree().create_timer(0.3).timeout
	
	assert(error_occurred, "Error should be emitted for null event")
	print("✓ test_null_event PASSED")
	
	teardown()

## Test: State transitions
func test_state_transitions() -> void:
	setup()
	
	var states_seen = []
	clippy.state_changed.connect(func(_old, new_state): states_seen.append(new_state))
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "intro"
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	assert(states_seen.size() > 0, "Should have state transitions")
	print("✓ test_state_transitions PASSED")
	
	teardown()

## Test: Progress state tracking
func test_progress_state() -> void:
	setup()
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {"completion": 0.75}
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	var state = clippy.get_progress_state()
	assert(state.events_processed > 0, "Events should be counted")
	assert(state.last_event_type == ClippyEvent.EventType.PROGRESS_UPDATE, "Last event type should be tracked")
	print("✓ test_progress_state PASSED")
	
	teardown()

## Test: Reset functionality
func test_reset() -> void:
	setup()
	
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "intro"
	
	clippy.handle_event(event)
	await get_tree().create_timer(0.3).timeout
	
	clippy.reset()
	
	var state = clippy.get_progress_state()
	assert(state.events_processed == 0, "Reset should clear progress")
	assert(clippy.current_state == ClippyController.State.IDLE, "Should return to IDLE state")
	print("✓ test_reset PASSED")
	
	teardown()

## Test: Clear queue
func test_clear_queue() -> void:
	setup()
	
	var event1 = ClippyEvent.new()
	event1.event_type = ClippyEvent.EventType.TUTORIAL_START
	event1.context_id = "intro"
	
	var event2 = ClippyEvent.new()
	event2.event_type = ClippyEvent.EventType.TUTORIAL_START
	event2.context_id = "intro2"
	
	# Don't process, just add to queue
	clippy._event_queue.append(event1)
	clippy._event_queue.append(event2)
	
	assert(clippy._event_queue.size() == 2, "Queue should have events")
	
	clippy.clear_queue()
	
	assert(clippy._event_queue.size() == 0, "Queue should be empty")
	print("✓ test_clear_queue PASSED")
	
	teardown()

## Run all tests
func run_all_tests() -> void:
	print("\n=== Running ClippyController Tests ===")
	await test_handle_tutorial_event()
	await test_handle_minigame_event()
	await test_handle_error_event()
	await test_event_queue()
	await test_invalid_event()
	await test_null_event()
	await test_state_transitions()
	await test_progress_state()
	await test_reset()
	await test_clear_queue()
	print("=== All ClippyController Tests Complete ===\n")
