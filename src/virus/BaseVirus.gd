class_name BaseVirus
extends Control

## Clase base para todos los virus
## Define la interfaz común y señales que el VirusController espera

signal virus_cleared
signal virus_failed

@export var difficulty_level: int = 1

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
