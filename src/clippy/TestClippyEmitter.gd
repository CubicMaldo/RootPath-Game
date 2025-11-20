# TestClippyEmitter.gd
# Manual test script to emit events and verify Clippy integration
# Add this to MainMenu or Desktop scene temporarily for testing
# Godot 4.5+
#
# Usage:
#   1. Add as child node to MainMenu or Desktop scene
#   2. Run game
#   3. Press keys to trigger events:
#      - T: Tutorial event
#      - M: Minigame event
#      - E: Error event
#      - P: Progress event
#      - A: Achievement event

extends Node

func _ready() -> void:
	print("=" * 60)
	print("[TestClippyEmitter] Test emitter ready")
	print("[TestClippyEmitter] Press keys to test Clippy:")
	print("  T = Tutorial Start")
	print("  M = Minigame Start")
	print("  E = Player Error")
	print("  P = Progress Update")
	print("  A = Achievement")
	print("  N = Navigation Ready")
	print("=" * 60)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				_emit_tutorial_event()
			KEY_M:
				_emit_minigame_event()
			KEY_E:
				_emit_error_event()
			KEY_P:
				_emit_progress_event()
			KEY_A:
				_emit_achievement_event()
			KEY_N:
				_emit_navigation_ready()

func _emit_tutorial_event() -> void:
	print("\n[TestClippyEmitter] Emitting TUTORIAL_START event...")
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TUTORIAL_START
	event.context_id = "test_tutorial"
	event.payload = {"section": "controls"}
	Clippy.handle_event(event)

func _emit_minigame_event() -> void:
	print("\n[TestClippyEmitter] Emitting MINI_GAME_START event...")
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.MINI_GAME_START
	event.context_id = "port_scanner"
	event.payload = {"game_type": "port_scanner"}
	Clippy.handle_event(event)

func _emit_error_event() -> void:
	print("\n[TestClippyEmitter] Emitting PLAYER_ERROR event...")
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PLAYER_ERROR
	event.payload = {"error_code": "wrong_answer", "attempt": 2}
	Clippy.handle_event(event)

func _emit_progress_event() -> void:
	print("\n[TestClippyEmitter] Emitting PROGRESS_UPDATE event...")
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.PROGRESS_UPDATE
	event.payload = {"completion": 0.65}
	Clippy.handle_event(event)

func _emit_achievement_event() -> void:
	print("\n[TestClippyEmitter] Emitting ACHIEVEMENT event...")
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.ACHIEVEMENT
	event.context_id = "first_win"
	event.payload = {"achievement_name": "Test Achievement"}
	Clippy.handle_event(event)

func _emit_navigation_ready() -> void:
	print("\n[TestClippyEmitter] Emitting navigation_ready via EventBus...")
	EventBus.navigation_ready.emit()
