# ClippyUI.gd
# UI component for displaying Clippy assistant messages
# Godot 4.5+
#
# This is a reusable UI component that:
# - Listens to ClippyController's ready_to_display signal
# - Shows messages in a styled panel
# - Auto-dismisses or waits for user interaction
# - Can be added to any scene that needs Clippy
#
# Usage:
#   # Add to scene tree
#   var clippy_ui = preload("res://src/clippy/ui/ClippyUI.tscn").instantiate()
#   add_child(clippy_ui)

extends Control

## Display duration (seconds) before auto-dismiss. Set to 0 to disable auto-dismiss.
@export var auto_dismiss_time: float = 10.0

## Whether to show the character icon
@export var show_icon: bool = true

## Animation duration for show/hide
@export var animation_duration: float = 0.3

## Nodes (with safe fallback)
@onready var message_label: RichTextLabel = get_node_or_null("%MessageLabel")
@onready var character_icon: TextureRect = get_node_or_null("%CharacterIcon")
@onready var dismiss_button: Button = get_node_or_null("%DismissButton")
@onready var next_button: Button = get_node_or_null("%NextButton")

## Timer for auto-dismiss
var dismiss_timer: Timer = null
var _paused_time_left: float = 0.0
var _is_hovering: bool = false

## Reference to Clippy controller
var clippy: ClippyController = null

## Current message priority (to prevent low-priority messages from overriding high-priority ones)
var current_message_priority: int = ClippyEvent.Priority.LOW
var is_showing_message: bool = false
var _is_sequence_mode: bool = false

## Signal for sequence navigation
signal next_message_requested()

func _ready() -> void:
	DebugLogger.clippy("Initializing ClippyUI...")
	
	# Verify required nodes exist
	if not message_label:
		push_error("[ClippyUI] MessageLabel node not found! Check scene structure.")
		return
	if not character_icon:
		DebugLogger.clippy("CharacterIcon node not found (optional)")
	if not dismiss_button:
		DebugLogger.clippy("DismissButton node not found (optional)")
	
	# Initially hide panel
	self.modulate.a = 0.0
	self.visible = false
	DebugLogger.clippy("Panel hidden initially")
	
	# Setup dismiss button
	if dismiss_button:
		dismiss_button.pressed.connect(_on_dismiss_pressed)
	else:
		push_warning("[ClippyUI] Cannot connect dismiss button - button not found")
	
	# Setup next button
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		next_button.visible = false  # Hidden by default
	else:
		DebugLogger.clippy("NextButton node not found (optional)")
	
	# Connect mouse signals for hover behavior
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Setup auto-dismiss timer
	if auto_dismiss_time > 0:
		dismiss_timer = Timer.new()
		dismiss_timer.one_shot = true
		dismiss_timer.timeout.connect(_hide_message)
		add_child(dismiss_timer)
	
	# Connect to Clippy
	await get_tree().process_frame
	if has_node("/root/Clippy"):
		clippy = get_node("/root/Clippy")
		clippy.ready_to_display.connect(_on_clippy_message)
		DebugLogger.clippy("✓ Connected to Clippy signals")
	else:
		push_error("[ClippyUI] ✗ Clippy autoload not found!")
	
	# Hide character icon if disabled
	if character_icon and not show_icon:
		character_icon.visible = false
	
	DebugLogger.clippy("Ready and waiting for messages")

## Called when Clippy has a message ready (now with priority parameter)
func _on_clippy_message(text: String, priority: int) -> void:
	DebugLogger.clippy("Received message: %s... (priority %d)", [text.substr(0, 50), priority])
	
	if text.is_empty():
		DebugLogger.clippy("Text is empty, ignoring")
		return
	
	# Check if we should show this message based on priority
	if _should_show_message(priority):
		_show_message(text, priority)
	else:
		DebugLogger.clippy("Message ignored (priority %d blocked by current priority %d)", [priority, current_message_priority])

## Show message with animation (now with priority)
func _show_message(text: String, priority: int = ClippyEvent.Priority.NORMAL) -> void:
	DebugLogger.clippy("Showing message (priority %d)", [priority])
	
	if message_label:
		message_label.text = text
	
	# Update current priority
	current_message_priority = priority
	is_showing_message = true
	
	self.visible = true
	
	# Choose animation based on priority
	if priority >= ClippyEvent.Priority.HIGH:
		_show_critical_popup()
	else:
		_show_normal_fade_in()
	
	# Start auto-dismiss timer
	if dismiss_timer and auto_dismiss_time > 0:
		dismiss_timer.stop()
		
		if _is_hovering:
			_paused_time_left = auto_dismiss_time
			DebugLogger.clippy("Mouse hovering: Timer start deferred (%.2fs)", [auto_dismiss_time])
		else:
			dismiss_timer.start(auto_dismiss_time)
			DebugLogger.clippy("Auto-dismiss timer started (%s s)", [auto_dismiss_time])

## Hide message with animation
func _hide_message() -> void:
	if self:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "modulate:a", 0.0, animation_duration)
		tween.tween_callback(func():
			self.visible = false
			is_showing_message = false
			current_message_priority = ClippyEvent.Priority.LOW # Reset priority
		)
	
	# Acknowledge to Clippy
	if clippy:
		clippy.acknowledge()

## Dismiss button pressed
func _on_dismiss_pressed() -> void:
	if dismiss_timer:
		dismiss_timer.stop()
	_hide_message()

## Next button pressed (advance to next message in sequence)
func _on_next_pressed() -> void:
	# Don't hide, just signal that user wants next message
	# The sequence handler will take care of showing the next one
	next_message_requested.emit()
	DebugLogger.clippy("Next message requested by user")

## Public method to manually show a message
func show_custom_message(text: String) -> void:
	_show_message(text)

## Public method to manually hide
func hide_current_message() -> void:
	if dismiss_timer:
		dismiss_timer.stop()
	_hide_message()

## Enable sequence mode (shows next button)
func set_sequence_mode(enabled: bool) -> void:
	_is_sequence_mode = enabled
	if next_button:
		next_button.visible = enabled
	DebugLogger.clippy("Sequence mode: %s" % enabled)

# ---------------------------------------------------------------------------
# Priority Management
# ---------------------------------------------------------------------------

## Check if incoming message should be shown based on priority
func _should_show_message(incoming_priority: int) -> bool:
	# If no message is currently showing, always show
	if not is_showing_message:
		return true
	
	# Priority hierarchy: CRITICAL > HIGH > NORMAL > LOW
	# A message can only interrupt if its priority is HIGHER
	if incoming_priority > current_message_priority:
		DebugLogger.clippy("Higher priority message (%d) interrupting current (%d)", [incoming_priority, current_message_priority])
		return true
	
	# Same or lower priority: don't interrupt
	return false

## Get priority of the current event being processed
func _get_current_event_priority() -> int:
	if not clippy:
		return ClippyEvent.Priority.NORMAL
	
	# Try to get the priority from the event queue
	# Since we don't have direct access, we'll need to add a way to track this
	# For now, we'll use a signal or add a method to ClippyController
	# As a fallback, return NORMAL
	return ClippyEvent.Priority.NORMAL

# ---------------------------------------------------------------------------
# Mouse Interaction (Hover to Pause)
# ---------------------------------------------------------------------------

func _on_mouse_entered() -> void:
	if dismiss_timer and not dismiss_timer.is_stopped():
		_paused_time_left = dismiss_timer.time_left
		dismiss_timer.stop()
		DebugLogger.clippy("Mouse entered: Timer paused (%.2fs left)", [_paused_time_left])
	_is_hovering = true

func _on_mouse_exited() -> void:
	if _paused_time_left > 0:
		dismiss_timer.start(_paused_time_left)
		DebugLogger.clippy("Mouse exited: Timer resumed (%.2fs)", [_paused_time_left])
		_paused_time_left = 0.0
	_is_hovering = false

# ---------------------------------------------------------------------------
# Animation Methods
# ---------------------------------------------------------------------------

## Normal fade-in animation for low/normal priority
func _show_normal_fade_in() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, animation_duration)
	DebugLogger.clippy("Panel animated in (normal)")

## Critical popup animation with red flashes for high/critical priority
func _show_critical_popup() -> void:
	# Instant popup (no fade)
	self.modulate.a = 1.0
	
	# Create red flash effect
	var flash_tween = create_tween()
	flash_tween.set_loops(3)
	
	# Flash red color
	var red_modulate = Color(1.5, 0.3, 0.3, 1.0)  # Bright red
	var normal_modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal white
	
	flash_tween.tween_property(self, "modulate", red_modulate, 0.15)
	flash_tween.tween_property(self, "modulate", normal_modulate, 0.15)
	
	DebugLogger.clippy("Panel animated in (CRITICAL with red flashes)")
