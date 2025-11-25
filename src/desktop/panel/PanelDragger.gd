extends Control
class_name PanelDragger

## Script para mover un panel desde un nodo hijo
## Adjuntar este script al nodo que será el área de arrastre

@export_group("Target Settings")
@export var panel_path: NodePath = "../.."  # Ruta al panel a mover
@export var auto_detect_panel: bool = true  # Buscar automáticamente el Panel padre

@export_group("Drag Settings")
@export var enable_drag: bool = true
@export var drag_button: MouseButton = MOUSE_BUTTON_LEFT
@export var only_drag_on_this_control: bool = true  # Solo arrastra si el mouse está sobre este Control

var drag_active: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var panel: Panel = null

# Sistema de bloqueo global - solo una instancia puede arrastrar a la vez
static var active_dragger: PanelDragger = null

func _ready() -> void:
	# Intentar obtener el panel
	if auto_detect_panel:
		panel = _find_parent_panel()
	else:
		panel = get_node_or_null(panel_path)
	
	if panel == null:
		push_error("PanelDragger: No se pudo encontrar el Panel. Verifica el panel_path o activa auto_detect_panel")
		return
	
	# Asegurar que este Control capture eventos
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	#print("PanelDragger: Panel encontrado en: ", panel.get_path())

func _find_parent_panel() -> Panel:
	var current_node = get_parent()
	while current_node != null:
		if current_node is Panel:
			return current_node
		current_node = current_node.get_parent()
	return null

func _input(event: InputEvent) -> void:
	if not enable_drag or panel == null:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == drag_button:
			if event.pressed:
				# Solo iniciar drag si no hay otro dragger activo y el mouse está sobre este control
				if active_dragger == null:
					if only_drag_on_this_control and _is_mouse_over() and _is_panel_on_top():
						_start_drag(event.position)
						_bring_to_front()
					elif not only_drag_on_this_control and _is_panel_on_top():
						_start_drag(event.position)
						_bring_to_front()
			else:
				# Solo detener si este es el dragger activo
				if active_dragger == self:
					_stop_drag()
	
	elif event is InputEventMouseMotion:
		# Solo procesar movimiento si este es el dragger activo
		if drag_active and active_dragger == self:
			_update_drag(event.position)

func _start_drag(mouse_pos: Vector2) -> void:
	drag_active = true
	last_mouse_pos = mouse_pos
	active_dragger = self  # Establecer esta instancia como el dragger activo

func _stop_drag() -> void:
	drag_active = false
	if active_dragger == self:
		active_dragger = null  # Liberar el bloqueo solo si somos el dragger activo

func _update_drag(mouse_pos: Vector2) -> void:
	var delta: Vector2 = mouse_pos - last_mouse_pos
	last_mouse_pos = mouse_pos
	panel.position += delta

func _is_mouse_over() -> bool:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var rect: Rect2 = get_global_rect()
	return rect.has_point(mouse_pos)

func _is_panel_on_top() -> bool:
	# Verificar si este panel es el que está más arriba en el z-order
	var mouse_pos: Vector2 = get_global_mouse_position()
	var panel_rect: Rect2 = panel.get_global_rect()
	
	# Si el mouse no está sobre este panel, no está "on top"
	if not panel_rect.has_point(mouse_pos):
		return false
	
	# Obtener el padre que contiene todos los paneles
	var parent_node = panel.get_parent()
	if parent_node == null:
		return true
	
	# Buscar todos los paneles hermanos
	var highest_index: int = panel.get_index()
	for child in parent_node.get_children():
		# Buscar nodos Control que contengan un Panel
		if child is Control and child != panel.get_parent():
			var other_panel = _find_panel_in_child(child)
			if other_panel != null and other_panel != panel:
				var other_rect: Rect2 = other_panel.get_global_rect()
				# Si el otro panel también contiene el mouse y tiene mayor índice, este no está on top
				if other_rect.has_point(mouse_pos) and child.get_index() > highest_index:
					return false
	
	return true

func _find_panel_in_child(node: Node) -> Panel:
	# Buscar recursivamente un Panel en los hijos
	if node is Panel:
		return node
	for child in node.get_children():
		var found = _find_panel_in_child(child)
		if found != null:
			return found
	return null

func _bring_to_front() -> void:
	# Mover el nodo padre del panel al final de la lista de hijos (mayor z-index)
	var parent_control = panel.get_parent()
	if parent_control and parent_control.get_parent():
		parent_control.get_parent().move_child(parent_control, -1)

## Debug: Mostrar información del panel
func get_panel_info() -> String:
	if panel:
		return "Panel: %s, Position: %s" % [panel.name, panel.position]
	return "Panel no encontrado"
