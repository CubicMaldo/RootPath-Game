class_name BaseVirus
extends Control

const VirusDefinition = preload("res://src/virus/resources/VirusDefinition.gd")

## Clase base para todos los virus
## Define la interfaz común y señales que el VirusController espera

signal virus_cleared
signal virus_failed

@export var difficulty_level: int = 1
var virus_definition: VirusDefinition

var _parameter_values: Dictionary = {}

# Método virtual que debe ser sobrescrito por cada virus
func start_infection() -> void:
	push_warning("BaseVirus: start_infection() no implementado")

# Llamado cuando el jugador resuelve el virus
func _on_virus_cleared() -> void:
	virus_cleared.emit()
	queue_free()

# Llamado cuando el jugador falla el virus (si aplica)
func _on_virus_failed() -> void:
	virus_failed.emit()
	# Dependiendo del diseño, podría reiniciar o penalizar más

func hide_buttons() -> void:
	pass

func configure_from_definition(definition: VirusDefinition, global_difficulty: int) -> void:
	virus_definition = definition
	difficulty_level = max(1, global_difficulty)
	_parameter_values = {}
	if virus_definition:
		_parameter_values = virus_definition.get_all_parameters(difficulty_level)

func get_config_value(param_name: String, default_value):
	if _parameter_values.has(param_name):
		return _parameter_values[param_name]
	if virus_definition:
		return virus_definition.get_parameter_value(param_name, difficulty_level, default_value)
	return default_value
