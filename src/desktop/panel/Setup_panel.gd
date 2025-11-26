extends Control

@onready var panel: Panel = $Panel
var is_maximized: bool = false

var objective_size: Vector2 = Vector2.ZERO
var objective_pivot: Vector2 = Vector2.ZERO

# Store original state for restoration
var original_anchors: Dictionary = {}
var original_offsets: Dictionary = {}
var original_size: Vector2 = Vector2.ZERO

func _setAppStat(appStats: AppStats):
	%Icon.texture = appStats.icon
	%Text.text = appStats.app_name
	
	objective_size = appStats.size
	objective_pivot = appStats.size * 0.5

func _ready() -> void:
	if panel == null:
		push_warning("Setup_panel: Panel node not found; skipping layout setup")
		return
	
	# Set size on the root Control node (self)
	self.custom_minimum_size = objective_size
	self.size = objective_size
	self.pivot_offset = objective_pivot
	
	_register_focus_listeners(self)
	
	# Store original state
	_store_original_state()

func _store_original_state() -> void:
	original_anchors = {
		"left": self.anchor_left,
		"top": self.anchor_top,
		"right": self.anchor_right,
		"bottom": self.anchor_bottom
	}
	original_offsets = {
		"left": self.offset_left,
		"top": self.offset_top,
		"right": self.offset_right,
		"bottom": self.offset_bottom
	}
	original_size = self.size

func _on_minimize_pressed() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(panel, "scale", Vector2(0.01, 0.01), 0.4)
	
	tween.finished.connect(func(): self.visible = false)

func _on_maximize_pressed() -> void:
	if not is_maximized:
		# Maximize: expand to fill entire parent (desktop)
		self.anchor_left = 0.0
		self.anchor_top = 0.0
		self.anchor_right = 1.0
		self.anchor_bottom = 1.0
		self.offset_left = 0.0
		self.offset_top = 0.0
		self.offset_right = 0.0
		self.offset_bottom = 0.0
		self.grow_horizontal = Control.GROW_DIRECTION_BOTH
		self.grow_vertical = Control.GROW_DIRECTION_BOTH
		is_maximized = true
	else:
		# Restore: return to original centered state
		self.anchor_left = original_anchors.get("left", 0.5)
		self.anchor_top = original_anchors.get("top", 0.5)
		self.anchor_right = original_anchors.get("right", 0.5)
		self.anchor_bottom = original_anchors.get("bottom", 0.5)
		self.offset_left = original_offsets.get("left", -400.0)
		self.offset_top = original_offsets.get("top", -384.0)
		self.offset_right = original_offsets.get("right", 400.0)
		self.offset_bottom = original_offsets.get("bottom", 384.0)
		self.grow_horizontal = Control.GROW_DIRECTION_BOTH
		self.grow_vertical = Control.GROW_DIRECTION_BOTH
		self.size = objective_size
		self.pivot_offset = objective_pivot
		is_maximized = false

func _register_focus_listeners(node: Node) -> void:
	if node is Control and node != self:
		var control_node: Control = node
		if not control_node.gui_input.is_connected(_on_descendant_gui_input):
			control_node.gui_input.connect(_on_descendant_gui_input)
	for child in node.get_children():
		_register_focus_listeners(child)

func _gui_input(event: InputEvent) -> void:
	_bring_to_front(event)

func _on_descendant_gui_input(event: InputEvent) -> void:
	_bring_to_front(event)

func _bring_to_front(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_to_front()
	
func hide_buttons():
	$Panel/VBoxContainer/MarginContainer/HBoxContainer/minimize.visible = false
	$Panel/VBoxContainer/MarginContainer/HBoxContainer/maximize.visible = false
