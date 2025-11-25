extends Button

## Botón de menú hamburguesa en la barra de tareas
## Muestra un PopupMenu con opciones para volver al menú principal y salir del juego

@onready var popup_menu: PopupMenu = $PopupMenu

const MAIN_MENU_PATH := "res://src/menu/MainMenu.tscn"

enum MenuOption {
	RETURN_TO_MENU,
	QUIT_GAME
}

func _ready() -> void:
	_setup_popup_menu()
	pressed.connect(_on_button_pressed)

func _setup_popup_menu() -> void:
	if popup_menu == null:
		popup_menu = PopupMenu.new()
		popup_menu.name = "PopupMenu"
		add_child(popup_menu)
	
	popup_menu.clear()
	popup_menu.add_item("🏠 Volver al Menú Principal", MenuOption.RETURN_TO_MENU)
	popup_menu.add_separator()
	popup_menu.add_item("❌ Salir del Juego", MenuOption.QUIT_GAME)
	
	popup_menu.id_pressed.connect(_on_menu_option_selected)

func _on_button_pressed() -> void:
	if popup_menu == null:
		return
	
	# Posicionar el menú debajo del botón
	var button_global_pos := global_position
	var button_size := size
	var popup_pos := Vector2(button_global_pos.x, button_global_pos.y + button_size.y)
	
	popup_menu.position = popup_pos
	popup_menu.popup()

func _on_menu_option_selected(id: int) -> void:
	match id:
		MenuOption.RETURN_TO_MENU:
			_return_to_main_menu()
		MenuOption.QUIT_GAME:
			_quit_game()

func _return_to_main_menu() -> void:
	print("[TaskbarMenu] Volviendo al menú principal...")
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _quit_game() -> void:
	print("[TaskbarMenu] Saliendo del juego...")
	get_tree().quit()
