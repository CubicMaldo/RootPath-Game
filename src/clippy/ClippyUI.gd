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
#   var clippy_ui = preload("res://src/clippy/ClippyUI.tscn").instantiate()
#   add_child(clippy_ui)

extends CanvasLayer

## Display duration (seconds) before auto-dismiss. Set to 0 to disable auto-dismiss.
@export var auto_dismiss_time: float = 8.0

## Whether to show the character icon
@export var show_icon: bool = true

## Animation duration for show/hide
@export var animation_duration: float = 0.3

## Nodes
@onready var panel: PanelContainer = %ClippyPanel
@onready var message_label: RichTextLabel = %MessageLabel
@onready var character_icon: TextureRect = %CharacterIcon
@onready var dismiss_button: Button = %DismissButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Timer for auto-dismiss
var dismiss_timer: Timer = null

## Reference to Clippy controller
var clippy: ClippyController = null

func _ready() -> void:
	print("[ClippyUI] Initializing...")
	
	# Initially hide panel
	if panel:
		panel.modulate.a = 0.0
		panel.visible = false
		print("[ClippyUI] Panel hidden initially")
	
	# Setup dismiss button
	if dismiss_button:
		dismiss_button.pressed.connect(_on_dismiss_pressed)
	
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
		print("[ClippyUI] ✓ Connected to Clippy signals")
	else:
		push_error("[ClippyUI] ✗ Clippy autoload not found!")
	
	# Hide character icon if disabled
	if character_icon and not show_icon:
		character_icon.visible = false
	
	print("[ClippyUI] Ready and waiting for messages")

## Called when Clippy has a message ready
func _on_clippy_message(text: String) -> void:
	print("[ClippyUI] Received message: ", text.substr(0, 50), "...")
	
	if text.is_empty():
		print("[ClippyUI] Text is empty, ignoring")
		return
	
	_show_message(text)

## Show message with animation
func _show_message(text: String) -> void:
	print("[ClippyUI] Showing message")
	
	if message_label:
		message_label.text = text
	
	if panel:
		panel.visible = true
		
		# Animate in
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(panel, "modulate:a", 1.0, animation_duration)
		print("[ClippyUI] Panel animated in")
	
	# Start auto-dismiss timer
	if dismiss_timer and auto_dismiss_time > 0:
		dismiss_timer.start(auto_dismiss_time)
		print("[ClippyUI] Auto-dismiss timer started (", auto_dismiss_time, "s)")

## Hide message with animation
func _hide_message() -> void:
	if panel:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(panel, "modulate:a", 0.0, animation_duration)
		tween.tween_callback(func(): panel.visible = false)
	
	# Acknowledge to Clippy
	if clippy:
		clippy.acknowledge()

## Dismiss button pressed
func _on_dismiss_pressed() -> void:
	if dismiss_timer:
		dismiss_timer.stop()
	_hide_message()

## Public method to manually show a message
func show_custom_message(text: String) -> void:
	_show_message(text)

## Public method to manually hide
func hide_current_message() -> void:
	if dismiss_timer:
		dismiss_timer.stop()
	_hide_message()
