extends PanelContainer

class_name PopUpWindow

signal closed
signal duplicate_requested

@onready var timer = $Timer
@onready var close_button = $VBoxContainer/Header/CloseButton

var lifetime: float = 3.0

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	timer.wait_time = lifetime + randf_range(-0.5, 1.0)
	timer.timeout.connect(_on_timeout)
	timer.start()
	
	# Posición aleatoria inicial (ajustada por el padre)
	
func _on_close_pressed():
	closed.emit()
	queue_free()

func _on_timeout():
	duplicate_requested.emit()
	# Reiniciar timer para seguir duplicándose si no se cierra
	timer.start()
	
	# Feedback visual de urgencia
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.2)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.2)
