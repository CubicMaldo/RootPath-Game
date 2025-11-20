extends TextureRect

class_name VirusDraggable

@export var id: int = 0

func _get_drag_data(_at_position):
	var preview = self.duplicate()
	preview.modulate.a = 0.5
	set_drag_preview(preview)
	return self
