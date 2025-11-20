extends PanelContainer

class_name VirusSlot

signal item_dropped

func _can_drop_data(_at_position, data):
	return is_instance_valid(data) and data is VirusDraggable

func _drop_data(_at_position, data):
	var original_parent = data.get_parent()
	
	# Si ya hay un hijo aquí, lo intercambiamos
	if get_child_count() > 0:
		var current_child = get_child(0)
		current_child.reparent(original_parent)
	
	data.reparent(self)
	item_dropped.emit()
