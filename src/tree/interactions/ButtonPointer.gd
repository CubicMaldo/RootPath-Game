extends Button

@export_enum("Izquierda", "Centro", "Derecha") var direccion: String = "Izquierda"

func _ready() -> void:
	# Connect to game controller events
	var controller := Global.ensure_tree_map()
	controller.player_moved.connect(_on_player_moved)
	# Initial state
	_update_state()

func _on_pressed() -> void:
	match direccion:
		"Izquierda":
			if Global.treeMap.can_navigate_left():
				Global.treeMap.navigate_left()
			else:
				Global.treeMap.navigate_down()
		"Derecha":
			if Global.treeMap.can_navigate_right():
				Global.treeMap.navigate_right()
			else:
				Global.treeMap.navigate_down()
		"Centro":
			Global.treeMap.navigate_up()
			

func _on_player_moved(_node: TreeNode) -> void:
	_update_state()

func _update_state() -> void:
	match direccion:
		"Izquierda":
			var can_move = Global.treeMap.can_navigate_down()
			disabled = not can_move
		
		"Derecha":
			var can_move = Global.treeMap.can_navigate_down()
			disabled = not can_move
		
		"Centro":
			disabled = not Global.treeMap.can_navigate_up()
