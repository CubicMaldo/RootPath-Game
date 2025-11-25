extends Node

## Settings Manager Singleton
## Manages game configuration (audio, video, controls) with persistence

signal settings_changed(setting_name: String, value: Variant)

const SETTINGS_PATH := "user://settings.cfg"

# Default settings
const DEFAULT_SETTINGS := {
	"audio_master": 1.0,
	"audio_music": 0.8,
	"audio_sfx": 1.0,
	"video_fullscreen": false,
}

# Current settings
var settings := {}

func _ready() -> void:
	load_settings()
	apply_all_settings()

## Load settings from file or use defaults
func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	
	if err != OK:
		print("[SettingsManager] No se encontró archivo de configuración, usando valores por defecto")
		settings = DEFAULT_SETTINGS.duplicate()
		save_settings()
		return
	
	# Load each setting or use default if missing
	for key in DEFAULT_SETTINGS.keys():
		if config.has_section_key("settings", key):
			settings[key] = config.get_value("settings", key)
		else:
			settings[key] = DEFAULT_SETTINGS[key]
	
	print("[SettingsManager] Configuración cargada: ", settings)

## Save all settings to file
func save_settings() -> void:
	var config := ConfigFile.new()
	
	for key in settings.keys():
		config.set_value("settings", key, settings[key])
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("[SettingsManager] Error al guardar configuración: " + str(err))
	else:
		print("[SettingsManager] Configuración guardada en: ", SETTINGS_PATH)

## Apply all settings at once
func apply_all_settings() -> void:
	set_master_volume(settings.audio_master)
	set_music_volume(settings.audio_music)
	set_sfx_volume(settings.audio_sfx)
	set_fullscreen(settings.video_fullscreen)

## Get a setting value
func get_setting(key: String) -> Variant:
	return settings.get(key, null)

## Set a setting value and save
func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	save_settings()
	settings_changed.emit(key, value)

# === AUDIO SETTINGS ===

func set_master_volume(value: float) -> void:
	settings.audio_master = clamp(value, 0.0, 1.0)
	var db := linear_to_db(settings.audio_master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	save_settings()
	settings_changed.emit("audio_master", settings.audio_master)

func get_master_volume() -> float:
	return settings.audio_master

func set_music_volume(value: float) -> void:
	settings.audio_music = clamp(value, 0.0, 1.0)
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		var db := linear_to_db(settings.audio_music)
		AudioServer.set_bus_volume_db(music_bus, db)
	save_settings()
	settings_changed.emit("audio_music", settings.audio_music)

func get_music_volume() -> float:
	return settings.audio_music

func set_sfx_volume(value: float) -> void:
	settings.audio_sfx = clamp(value, 0.0, 1.0)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		var db := linear_to_db(settings.audio_sfx)
		AudioServer.set_bus_volume_db(sfx_bus, db)
	save_settings()
	settings_changed.emit("audio_sfx", settings.audio_sfx)

func get_sfx_volume() -> float:
	return settings.audio_sfx

# === VIDEO SETTINGS ===

func set_fullscreen(enabled: bool) -> void:
	settings.video_fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()
	settings_changed.emit("video_fullscreen", enabled)

func get_fullscreen() -> bool:
	return settings.video_fullscreen

func toggle_fullscreen() -> void:
	set_fullscreen(not settings.video_fullscreen)
