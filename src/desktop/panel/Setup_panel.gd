extends Control

@onready var panel: Panel = $Panel
var is_maximized : bool = false

var objective_size : Vector2
var objective_pivot : Vector2

func _setAppStat(appStats : AppStats):
	$Panel/VBoxContainer/MarginContainer/HBoxContainer/TextureRect.texture = appStats.icon
	$Panel/VBoxContainer/MarginContainer/HBoxContainer/Label.text = appStats.app_name
	
	objective_size = appStats.size
	objective_pivot = appStats.size * 0.5

func _ready() -> void:
	panel.size = objective_size
	panel.pivot_offset = objective_pivot

func _on_minimize_pressed() -> void:
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(0.1, 0.1), 0.4)
	
	tween.finished.connect(func(): self.visible = false)


func _on_maximize_pressed() -> void:
	if not is_maximized:
		print("maximizando")
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		is_maximized = true
	else:
		
		panel.set_anchors_preset(Control.PRESET_CENTER)
		
		panel.size = objective_size
		panel.pivot_offset = objective_pivot
		
		is_maximized = false
	
	
