extends Control

## Main Menu controller
## Handles navigation to game and quit functionality

@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton
@onready var welcome_dialog: AcceptDialog = %WelcomeDialog

const GAME_SCENE_PATH := "res://principalGameScene.tscn"

func _ready() -> void:
	_connect_buttons()
	_focus_play_button()
	_setup_welcome_dialog()

func _connect_buttons() -> void:
	if play_button != null:
		play_button.pressed.connect(_on_play_pressed)
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)

func _setup_welcome_dialog() -> void:
	if welcome_dialog != null:
		welcome_dialog.confirmed.connect(_start_game)
		welcome_dialog.canceled.connect(_start_game)
		welcome_dialog.close_requested.connect(_start_game)

func _focus_play_button() -> void:
	if play_button != null:
		play_button.grab_focus()

func _on_play_pressed() -> void:
	print("[MainMenu] Mostrando mensaje de bienvenida...")
	if welcome_dialog != null:
		welcome_dialog.popup_centered()
	else:
		_start_game()

func _start_game() -> void:
	print("[MainMenu] Iniciando juego...")
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_pressed() -> void:
	print("[MainMenu] Saliendo del juego...")
	get_tree().quit()
