extends CanvasLayer

class_name VirusOverlay

@onready var container = $VirusContainer
@onready var background = $Background

func _ready():
	visible = false

func show_overlay():
	visible = true
	# Animación de entrada podría ir aquí

func hide_overlay():
	visible = false
	# Limpiar hijos por si acaso
	for child in container.get_children():
		child.queue_free()

func add_virus(virus_scene: PackedScene) -> BaseVirus:
	var virus_instance = virus_scene.instantiate()
	if not virus_instance is BaseVirus:
		push_error("VirusOverlay: La escena instanciada no hereda de BaseVirus")
		return null
	
	container.add_child(virus_instance)
	virus_instance.hide_buttons()
	return virus_instance
