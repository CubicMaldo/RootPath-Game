# test_clippy_schema.gd
# Unit tests for ClippyEventSchema validation system
# Godot 4.5+
#
# Run tests using GUT (Godot Unit Testing) framework
# Or manually by adding this script to a test scene and calling test methods

extends Node

## Test: Valid MINI_GAME_START event
func test_valid_minigame_event() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "port_scanner"
	event.payload = {"game_type": "port_scanner"}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Valid minigame event should pass validation")
	assert(result.errors.is_empty(), "Should have no errors")
	print("✓ test_valid_minigame_event PASSED")

## Test: MINI_GAME_START missing required field
func test_minigame_missing_game_type() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "port_scanner"
	event.payload = {} # Missing game_type
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "Event should fail validation without game_type")
	assert(result.errors.size() > 0, "Should have validation errors")
	print("✓ test_minigame_missing_game_type PASSED")

## Test: PLAYER_ERROR with invalid error_code
func test_player_error_invalid_code() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {"error_code": "invalid_code_xyz"} # Not in allowed values
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "Event should fail with invalid error_code")
	assert(result.errors.any(func(e): return "invalid value" in e.to_lower()),
		"Should have error about invalid value")
	print("✓ test_player_error_invalid_code PASSED")

## Test: PLAYER_ERROR with valid error_code
func test_player_error_valid() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {"error_code": "wrong_answer", "attempt": 2}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Valid error event should pass")
	print("✓ test_player_error_valid PASSED")

## Test: PROGRESS_UPDATE with completion out of range
func test_progress_completion_out_of_range() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {"completion": 1.5} # > 1.0
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "Completion > 1.0 should fail validation")
	assert(result.errors.any(func(e): return "between 0.0 and 1.0" in e),
		"Should have error about range")
	print("✓ test_progress_completion_out_of_range PASSED")

## Test: PROGRESS_UPDATE with valid completion
func test_progress_valid_completion() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {"completion": 0.75}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Valid completion should pass")
	print("✓ test_progress_valid_completion PASSED")

## Test: PROGRESS_UPDATE with no progress indicators
func test_progress_no_indicators() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {} # No completion, action, or new_score
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "PROGRESS_UPDATE needs at least one indicator")
	print("✓ test_progress_no_indicators PASSED")

## Test: PROGRESS_UPDATE with action (no completion)
func test_progress_with_action() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {"action": "visited", "node_id": "node_123"}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Action is valid progress indicator")
	print("✓ test_progress_with_action PASSED")

## Test: Type mismatch in payload
func test_type_mismatch() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "test"
	event.payload = {"game_type": 123} # Should be String, got int
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "Type mismatch should fail")
	assert(result.errors.any(func(e): return "wrong type" in e.to_lower()),
		"Should have type error")
	print("✓ test_type_mismatch PASSED")

## Test: TUTORIAL_START missing context_id
func test_tutorial_missing_context() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "" # Required but empty
	
	var result = ClippyEventSchema.validate_event(event)
	assert(not result.valid, "Tutorial needs context_id")
	assert(result.errors.any(func(e): return "context_id" in e.to_lower()),
		"Should mention context_id")
	print("✓ test_tutorial_missing_context PASSED")

## Test: ACHIEVEMENT valid event
func test_achievement_valid() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.ACHIEVEMENT
	event.context_id = "first_win"
	event.payload = {"achievement_name": "Port Master", "points_earned": 100}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Valid achievement should pass")
	print("✓ test_achievement_valid PASSED")

## Test: Get required fields helper
func test_get_required_fields() -> void:
	var fields = ClippyEventSchema.get_required_fields(ClippyEvent.EventType.MINI_GAME_START)
	
	assert(fields.has("context_id"), "Should have context_id key")
	assert(fields.context_id == true, "context_id should be required")
	assert(fields.has("payload"), "Should have payload key")
	assert(fields.payload.has("game_type"), "payload should require game_type")
	print("✓ test_get_required_fields PASSED")

## Test: Null event handling
func test_null_event() -> void:
	var result = ClippyEventSchema.validate_event(null)
	assert(not result.valid, "Null event should fail")
	assert(result.errors.size() > 0, "Should have error for null")
	print("✓ test_null_event PASSED")

## Test: HINT_REQUESTED (no requirements)
func test_hint_requested_minimal() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.HINT_REQUESTED
	# Empty payload, context, level
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "HINT_REQUESTED has no requirements")
	print("✓ test_hint_requested_minimal PASSED")

## Test: GAME_COMPLETED with victory flag
func test_game_completed() -> void:
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.GAME_COMPLETED
	event.payload = {"victory": true, "final_score": 1000}
	
	var result = ClippyEventSchema.validate_event(event)
	assert(result.valid, "Valid game completion should pass")
	print("✓ test_game_completed PASSED")

## Run all tests
func run_all_tests() -> void:
	print("\n=== Running ClippyEventSchema Tests ===")
	test_valid_minigame_event()
	test_minigame_missing_game_type()
	test_player_error_invalid_code()
	test_player_error_valid()
	test_progress_completion_out_of_range()
	test_progress_valid_completion()
	test_progress_no_indicators()
	test_progress_with_action()
	test_type_mismatch()
	test_tutorial_missing_context()
	test_achievement_valid()
	test_get_required_fields()
	test_null_event()
	test_hint_requested_minimal()
	test_game_completed()
	print("=== All ClippyEventSchema Tests Complete ===\n")

func _ready() -> void:
	run_all_tests()
