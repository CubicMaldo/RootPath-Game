extends Control

@onready var panel: Panel = $Panel
var is_maximized : bool = false

var objective_size : Vector2 = Vector2.ZERO
var objective_pivot : Vector2 = Vector2.ZERO

func _setAppStat(appStats : AppStats):
	%Icon.texture = appStats.icon
	%Text.text = appStats.app_name
	
	objective_size = appStats.size
	objective_pivot = appStats.size * 0.5

func _ready() -> void:
	if panel == null:
		push_warning("Setup_panel: Panel node not found; skipping layout setup")
		return
	panel.size = objective_size
	panel.pivot_offset = objective_pivot
	_register_focus_listeners(self)

func _on_minimize_pressed() -> void:
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(0.1, 0.1), 0.4)
	
	tween.finished.connect(func(): self.visible = false)


func _on_maximize_pressed() -> void:
	if panel == null:
		return
	if not is_maximized:
		print("maximizando")
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		is_maximized = true
	else:
		
		panel.set_anchors_preset(Control.PRESET_CENTER)
		
		panel.size = objective_size
		panel.pivot_offset = objective_pivot
		
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
	
	
