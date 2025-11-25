class_name NodoVisual
extends  Control
# Puedes usar Control si prefieres, pero Button te da interacción directa

enum NodosJuego { INICIO = 0, DESAFIO = 1, PISTA = 2, FINAL = 3}
var nodo: TreeNode  # Referencia al nodo lógico
@onready var button: Button = $Button

func _ready():
	# Opcional: tamaño estándar y estilo base
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size = Vector2(64, 64)

# 🔹 Configura el aspecto según el tipo del nodo
func set_visuals(_nodo : TreeNode):
	match _nodo.tipo:
		NodosJuego.INICIO:
			modulate = Color(0.2, 1.0, 0.2)  # Verde
		NodosJuego.DESAFIO:
			modulate = Color(0.8, 0.8, 0.8)
		NodosJuego.PISTA:
			modulate = Color(0.2, 0.6, 1.0)  # Azul
		NodosJuego.FINAL:
			modulate = Color(1.0, 0.8, 0.2)
	if _nodo.app_resource:
		if _nodo.app_resource.icon:
			button.set_button_icon(_nodo.app_resource.icon)

# 🔹 Si el nodo está marcado como visto, cámbiale el estilo
func actualizar_estado_visto():
	if nodo != null and nodo.visto:
		modulate = Color(1.0, 1.0, 1.0)  # Blanco encendido
	else:
		modulate = Color(0.4, 0.4, 0.4)  # Atenuado


# 🔹 Detecta clics en el nodo (opcional)
func _pressed():
	if nodo != null:
		print("🟢 TreeNode presionado:", nodo.tipo)
		# Aquí podrías emitir una señal global para saltar a ese nodo


func _on_button_pressed() -> void:
	pass # Replace with function body.
