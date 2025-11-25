extends Control

## Settings Screen Controller
## Manages settings UI and synchronization with SettingsManager

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_label: Label = %MasterLabel
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var back_button: Button = %BackButton

const MAIN_MENU_PATH := "res://src/menu/MainMenu.tscn"

func _ready() -> void:
	_load_current_settings()
	_connect_signals()
	_focus_back_button()

func _load_current_settings() -> void:
	# Load audio settings
	if master_slider:
		master_slider.value = SettingsManager.get_master_volume() * 100.0
		_update_master_label(master_slider.value)
	
	if music_slider:
		music_slider.value = SettingsManager.get_music_volume() * 100.0
		_update_music_label(music_slider.value)
	
	if sfx_slider:
		sfx_slider.value = SettingsManager.get_sfx_volume() * 100.0
		_update_sfx_label(sfx_slider.value)
	
	# Load video settings
	if fullscreen_check:
		fullscreen_check.button_pressed = SettingsManager.get_fullscreen()

func _connect_signals() -> void:
	# Audio controls
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Video controls
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Navigation
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _focus_back_button() -> void:
	if back_button:
		back_button.grab_focus()

# === AUDIO CALLBACKS ===

func _on_master_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value / 100.0)
	_update_master_label(value)

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.set_music_volume(value / 100.0)
	_update_music_label(value)

func _on_sfx_volume_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value / 100.0)
	_update_sfx_label(value)

func _update_master_label(value: float) -> void:
	if master_label:
		master_label.text = "Master: %d%%" % int(value)

func _update_music_label(value: float) -> void:
	if music_label:
		music_label.text = "Música: %d%%" % int(value)

func _update_sfx_label(value: float) -> void:
	if sfx_label:
		sfx_label.text = "Efectos: %d%%" % int(value)

# === VIDEO CALLBACKS ===

func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

# === NAVIGATION ===

func _on_back_pressed() -> void:
	print("[Settings] Volviendo al menú principal...")
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
