# test_clippy_events.gd
# Unit tests for ClippyEvent resource class
# Godot 4.5+
#
# Run tests using GUT (Godot Unit Testing) framework
# Or manually by adding this script to a test scene and calling test methods

extends Node

## Test: Create event and validate fields
func test_create_tutorial_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.level_id = "tutorial_area"
	event.context_id = "tree_navigation_intro"
	event.payload = {"section": "controls"}
	
	assert(event.is_valid(), "Tutorial event should be valid")
	assert(event.event_type == ClippyEvent.EventType.TUTORIAL_START, "Event type mismatch")
	assert(event.context_id == "tree_navigation_intro", "Context ID mismatch")
	print("✓ test_create_tutorial_event PASSED")

## Test: Create minigame event
func test_create_minigame_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "port_scanner"
	event.payload = {
		"game_type": "port_scanner",
		"difficulty": "normal",
		"lives": 3
	}
	
	assert(event.is_valid(), "Minigame event should be valid")
	assert(event.payload.has("game_type"), "Payload missing game_type")
	print("✓ test_create_minigame_event PASSED")

## Test: Invalid event (missing required fields)
func test_invalid_event_missing_fields() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	# Missing context_id
	
	assert(not event.is_valid(), "Event should be invalid without context_id")
	print("✓ test_invalid_event_missing_fields PASSED")

## Test: Player error event
func test_player_error_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {
		"error_code": "wrong_answer",
		"attempt": 2
	}
	
	assert(event.is_valid(), "Error event should be valid")
	assert(event.payload.error_code == "wrong_answer", "Error code mismatch")
	print("✓ test_player_error_event PASSED")

## Test: Progress update event
func test_progress_update_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {
		"completion": 0.65,
		"nodes_visited": 8
	}
	
	assert(event.is_valid(), "Progress event should be valid")
	assert(event.payload.completion == 0.65, "Completion value mismatch")
	print("✓ test_progress_update_event PASSED")

## Test: Achievement event
func test_achievement_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.ACHIEVEMENT
	event.context_id = "first_minigame_complete"
	event.payload = {
		"achievement_name": "Port Scanner Master",
		"points_earned": 180
	}
	
	assert(event.is_valid(), "Achievement event should be valid")
	print("✓ test_achievement_event PASSED")

## Test: Event serialization (to_dict / from_dict)
func test_event_serialization() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.level_id = "level_1"
	event.context_id = "sql_injection"
	event.payload = {"game_type": "sql_injection"}
	
	var dict = event.to_dict()
	var restored = ClippyEvent.from_dict(dict)
	
	assert(restored.event_type == event.event_type, "Event type not preserved")
	assert(restored.level_id == event.level_id, "Level ID not preserved")
	assert(restored.context_id == event.context_id, "Context ID not preserved")
	print("✓ test_event_serialization PASSED")

## Test: Event description
func test_event_description() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "intro"
	
	var desc = event.get_description()
	assert(desc.contains("TUTORIAL_START"), "Description missing event type")
	assert(desc.contains("intro"), "Description missing context")
	print("✓ test_event_description PASSED")

## Test: Timestamp auto-generation
func test_event_timestamp() -> void:
	var event1 = ClippyEvent.new()
	await get_tree().create_timer(0.1).timeout
	var event2 = ClippyEvent.new()
	
	assert(event2.timestamp > event1.timestamp, "Timestamp should increase")
	print("✓ test_event_timestamp PASSED")

## Run all tests
func run_all_tests() -> void:
	print("\n=== Running ClippyEvent Tests ===")
	test_create_tutorial_event()
	test_create_minigame_event()
	test_invalid_event_missing_fields()
	test_player_error_event()
	test_progress_update_event()
	test_achievement_event()
	test_event_serialization()
	test_event_description()
	await test_event_timestamp()
	print("=== All ClippyEvent Tests Complete ===\n")

func _ready() -> void:
	await run_all_tests()
