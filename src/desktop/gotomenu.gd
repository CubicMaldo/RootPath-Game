extends Button
const MAIN_MENU_PATH := "res://src/menu/MainMenu.tscn"

func _on_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
