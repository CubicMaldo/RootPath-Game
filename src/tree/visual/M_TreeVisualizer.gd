# TreeVisualizer.gd
extends Control

@export_category("Dependencies")
@export var nodo_escena: PackedScene
@export var layout_engine: TreeLayout
@export var camera_controller: TreeCamera

@export_category("Visual Settings")
@export var animation_duration: float = 0.5
@export var auto_center_on_ready: bool = true
@export var fog_of_war_enabled: bool = true

@export_category("Node Colors")
@export var color_undiscovered: Color = Color(0.3, 0.3, 0.3, 0.3)  # Gris oscuro
@export var color_discovered: Color = Color.WHITE  # Blanco (descubierto pero no visitado)
@export var color_visited: Color = Color(0.4, 0.6, 0.9, 1.0)  # Azul (visitado)
@export var color_current: Color = Color(1.0, 0.8, 0.2, 1.0)  # Amarillo/Dorado (actual)

enum NodosJuego { INICIO = 0, DESAFIO = 1, PISTA = 2, FINAL = 3 }

# Señales
signal tree_centered()
#signal zoom_changed(new_zoom: float)
signal view_reset()
signal tree_loaded()
signal node_visual_revealed(node: TreeNode)

var tree: Arbol
var visibility_tracker: VisibilityTracker
var lineas: Array[Array] = []

# Mapeo de nodos lógicos a nodos visuales
var node_to_visual: Dictionary = {}  # TreeNode -> Control/Node2D
var current_node: TreeNode = null  # 🆕 Nodo actual

# Referencias a contenedores
var nodos_container: Control
var lineas_node: Node2D

func _ready() -> void:
	_setup_containers()
	_initialize_dependencies()
	
	if is_inside_tree():
		await get_tree().process_frame
	queue_redraw()

func _setup_containers() -> void:
	nodos_container = _get_or_create_control("NodosContainer")
	lineas_node = _get_or_create_node2d("Lineas")
	move_child(lineas_node, 0)

func _get_or_create_control(node_name: String) -> Control:
	var node: Control = get_node_or_null(node_name)
	if node == null:
		node = Control.new()
		node.name = node_name
		add_child(node)
	return node

func _get_or_create_node2d(node_name: String) -> Node2D:
	var node: Node2D = get_node_or_null(node_name)
	if node == null:
		node = Node2D.new()
		node.name = node_name
		add_child(node)
	return node

func _initialize_dependencies() -> void:
	if layout_engine == null:
		layout_engine = TreeLayout.new()
	
	if camera_controller == null:
		camera_controller = TreeCamera.new()
		camera_controller.setup(self, nodos_container, lineas_node)

# ========== API PÚBLICA CON VISIBILITY ==========

## Actualizar el nodo actual manualmente (si VisibilityTracker no tiene señal)
func set_current_node(node: TreeNode) -> void:
	"""Establece el nodo actual y actualiza la visualización"""
	if current_node == node:
		return
	
	var old_node = current_node
	current_node = node
	
	# Actualizar apariencia del nodo anterior
	if old_node and node_to_visual.has(old_node):
		var old_visual = node_to_visual[old_node]
		_update_node_appearance(old_node, old_visual)
	
	# Actualizar apariencia del nodo actual
	if current_node and node_to_visual.has(current_node):
		var new_visual = node_to_visual[current_node]
		_update_node_appearance(current_node, new_visual)
	
	#print("🎯 Current node set to: ", node.tipo if node else "null")

## Conectar con el sistema de visibilidad
func connect_visibility_tracker(tracker: VisibilityTracker) -> void:
	if visibility_tracker != null:
		# Desconectar señales previas
		if visibility_tracker.has_signal("node_discovered") and visibility_tracker.node_discovered.is_connected(_on_node_discovered):
			visibility_tracker.node_discovered.disconnect(_on_node_discovered)
		if visibility_tracker.has_signal("node_visited") and visibility_tracker.node_visited.is_connected(_on_node_visited):
			visibility_tracker.node_visited.disconnect(_on_node_visited)
		if visibility_tracker.has_signal("current_node_changed") and visibility_tracker.current_node_changed.is_connected(_on_current_node_changed):
			visibility_tracker.current_node_changed.disconnect(_on_current_node_changed)
	
	visibility_tracker = tracker
	
	if visibility_tracker != null:
		# Conectar señales si existen
		if visibility_tracker.has_signal("node_discovered"):
			visibility_tracker.node_discovered.connect(_on_node_discovered)
		
		if visibility_tracker.has_signal("node_visited"):
			visibility_tracker.node_visited.connect(_on_node_visited)
		
		if visibility_tracker.has_signal("current_node_changed"):
			visibility_tracker.current_node_changed.connect(_on_current_node_changed)
		
		# Sincronizar nodo actual
		if "current_node" in visibility_tracker and visibility_tracker.current_node:
			current_node = visibility_tracker.current_node

## Mostrar árbol (con o sin fog of war)
func mostrar_arbol(arbol: Arbol, tracker: VisibilityTracker = null) -> void:
	if arbol == null or arbol.raiz == null:
		push_warning("Árbol vacío o nulo")
		return
	
	_ensure_containers_ready()
	_initialize_dependencies()
	_clear_tree_visual()
	tree = arbol
	
	# Conectar tracker si se proporciona
	if tracker != null:
		connect_visibility_tracker(tracker)
	
	# Calcular layout del árbol COMPLETO
	var positions = layout_engine.calculate_layout(tree.raiz)
	
	# Dibujar según visibilidad
	if fog_of_war_enabled and visibility_tracker != null:
		_draw_tree_with_fog_of_war(positions)
	else:
		_draw_tree_with_positions(positions)
	
	if auto_center_on_ready and is_inside_tree():
		await get_tree().process_frame
		center_tree()
	tree_loaded.emit()

## Actualizar visualización según visibilidad actual
func refresh_visibility() -> void:
	if tree == null:
		return
	
	# Recalcular posiciones
	var positions = layout_engine.calculate_layout(tree.raiz)
	var offset = _calculate_drawing_offset(positions)
	
	# Actualizar visibilidad de cada nodo
	for nodo in node_to_visual.keys():
		var visual = node_to_visual[nodo]
		
		if visual and is_instance_valid(visual):
			_update_node_appearance(nodo, visual)
	
	# Actualizar líneas
	if fog_of_war_enabled and visibility_tracker != null:
		_update_visible_lines(positions, offset)

# ========== CALLBACKS DE VISIBILITY TRACKER ==========

func _on_node_discovered(node: TreeNode) -> void:
	#print("🔍 Node discovered in visualizer: ", node.tipo)
	
	if not node_to_visual.has(node):
		# El nodo no existe visualmente, crearlo
		var positions = layout_engine.calculate_layout(tree.raiz)
		var offset = _calculate_drawing_offset(positions)
		if positions.has(node):
			_create_visual_node(node, positions[node] + offset)
	
	# Hacer visible el nodo
	if node_to_visual.has(node):
		var visual = node_to_visual[node]
		_reveal_node_visual(visual, node)
		node_visual_revealed.emit(node)
	
	# Actualizar líneas para mostrar conexiones
	refresh_visibility()

func _on_node_visited(node: TreeNode) -> void:
	#print("✅ Node visited in visualizer: ", node.tipo)
	
	if node_to_visual.has(node):
		var visual = node_to_visual[node]
		_update_node_appearance(node, visual)

func _on_current_node_changed(new_node: TreeNode, old_node: TreeNode) -> void:
	#print("🎯 Current node changed: ", old_node, " -> ", new_node)
	
	# Actualizar el nodo anterior
	if old_node and node_to_visual.has(old_node):
		var old_visual = node_to_visual[old_node]
		_update_node_appearance(old_node, old_visual)
	
	# Actualizar el nodo actual
	current_node = new_node
	if new_node and node_to_visual.has(new_node):
		var new_visual = node_to_visual[new_node]
		_update_node_appearance(new_node, new_visual)

# ========== DIBUJO CON FOG OF WAR ==========

func _draw_tree_with_fog_of_war(positions: Dictionary) -> void:
	if positions.is_empty():
		return
	
	var offset = _calculate_drawing_offset(positions)
	
	# Crear TODOS los nodos, pero ocultos
	for nodo in positions:
		var pos = positions[nodo] + offset
		var visual = _create_visual_node(nodo, pos)
		
		# Configurar apariencia inicial
		if not visibility_tracker or not visibility_tracker.is_discovered(nodo):
			_hide_node_visual(visual)
		else:
			_reveal_node_visual(visual, nodo)
			_update_node_appearance(nodo, visual)
	
	# Dibujar solo líneas visibles
	_update_visible_lines(positions, offset)

func _update_visible_lines(positions: Dictionary, offset: Vector2) -> void:
	lineas.clear()
	
	if not visibility_tracker:
		# Sin tracker, mostrar todas las líneas
		for nodo in positions:
			_add_node_connections(nodo, positions, offset, true)
		_update_lineas_node()
		return
	
	for nodo in positions:
		# Solo dibujar líneas si el nodo está descubierto
		if not visibility_tracker.is_discovered(nodo):
			continue
		
		_add_node_connections(nodo, positions, offset, false)
	
	_update_lineas_node()

func _add_node_connections(nodo: TreeNode, positions: Dictionary, offset: Vector2, ignore_visibility: bool) -> void:
	var start_pos = positions[nodo] + offset
	
	# Línea a hijo izquierdo
	if nodo.izquierdo and positions.has(nodo.izquierdo):
		if ignore_visibility or visibility_tracker.is_discovered(nodo.izquierdo):
			var end_pos = positions[nodo.izquierdo] + offset
			lineas.append([start_pos, end_pos])
	
	# Línea a hijo derecho
	if nodo.derecho and positions.has(nodo.derecho):
		if ignore_visibility or visibility_tracker.is_discovered(nodo.derecho):
			var end_pos = positions[nodo.derecho] + offset
			lineas.append([start_pos, end_pos])

# ========== MANIPULACIÓN DE APARIENCIA DE NODOS ==========

func _update_node_appearance(nodo: TreeNode, visual: Node) -> void:
	"""Actualiza la apariencia del nodo según su estado actual"""
	if visual == null or not is_instance_valid(visual):
		return
	
	var target_color: Color
	var target_scale: Vector2 = Vector2.ONE
	
	# Determinar el estado del nodo
	if nodo == current_node:
		# Nodo actual - PRIORIDAD MÁXIMA
		target_color = color_current
		target_scale = Vector2(1.1, 1.1)  # Ligeramente más grande
	elif visibility_tracker and visibility_tracker.is_visited(nodo):
		# Nodo visitado
		target_color = color_visited
	elif visibility_tracker and visibility_tracker.is_discovered(nodo):
		# Nodo descubierto pero no visitado
		target_color = color_discovered
	else:
		# Nodo no descubierto
		target_color = color_undiscovered
	
	# Aplicar cambios con animación suave
	_animate_node_appearance(visual, target_color, target_scale)

func _animate_node_appearance(visual: Node, target_color: Color, target_scale: Vector2) -> void:
	"""Anima el cambio de apariencia del nodo"""
	if not (visual is NodoVisual):
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animar color
	if visual.has_method("set_modulate"):
		tween.tween_property(visual, "modulate", target_color, 0.3)
	
	# Animar escala
	tween.tween_property(visual, "scale", target_scale, 0.3)

func _hide_node_visual(visual: Node) -> void:
	if visual == null:
		return
	
	visual.visible = false
	
	# Aplicar color de no descubierto
	if visual.has_method("set_modulate"):
		visual.modulate = color_undiscovered

func _reveal_node_visual(visual: Node, node: TreeNode) -> void:
	if visual == null:
		return
	
	visual.visible = true
	
	# Animación de revelación
	if visual is Control or visual is Node2D:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		
		# Escala desde 0
		visual.scale = Vector2.ZERO
		tween.tween_property(visual, "scale", Vector2.ONE, 0.3)
		
		# Fade in con el color correcto
		if visual.has_method("set_modulate"):
			visual.modulate = Color(1, 1, 1, 0)
			var target_color = _get_node_color(node)
			tween.tween_property(visual, "modulate", target_color, 0.3)

func _get_node_color(nodo: TreeNode) -> Color:
	"""Obtiene el color apropiado para un nodo según su estado"""
	if nodo == current_node:
		return color_current
	elif visibility_tracker and visibility_tracker.is_visited(nodo):
		return color_visited
	elif visibility_tracker and visibility_tracker.is_discovered(nodo):
		return color_discovered
	else:
		return color_undiscovered

# ========== FUNCIONES DE DIBUJO ORIGINALES (modificadas) ==========

func _draw_tree_with_positions(positions: Dictionary) -> void:
	if positions.is_empty():
		return
	
	var offset = _calculate_drawing_offset(positions)
	_draw_nodes_and_lines(positions, offset)
	_update_lineas_node()

func _calculate_drawing_offset(positions: Dictionary) -> Vector2:
	var bounds = _calculate_tree_bounds(positions)
	var viewport_center = size / 2.0
	return Vector2(viewport_center.x - bounds.get_center().x, 50 - bounds.position.y)

func _calculate_tree_bounds(positions: Dictionary) -> Rect2:
	if positions.is_empty():
		return Rect2()
	
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for pos in positions.values():
		min_pos = min_pos.min(pos)
		max_pos = max_pos.max(pos)
	
	return Rect2(min_pos, max_pos - min_pos)

func _draw_nodes_and_lines(positions: Dictionary, offset: Vector2) -> void:
	lineas.clear()
	
	for nodo in positions:
		var pos = positions[nodo] + offset
		_create_visual_node(nodo, pos)
	
	for nodo in positions:
		_create_connections(nodo, positions, offset)

func _create_visual_node(nodo: TreeNode, _position: Vector2) -> Node:
	if not nodo_escena:
		push_error("nodo_escena no está asignado")
		return null
	
	var nodo_visual = nodo_escena.instantiate()
	nodo_visual.position = _position
	nodos_container.add_child(nodo_visual)
	
	# Guardar mapeo
	node_to_visual[nodo] = nodo_visual
	
	_configure_visual_node(nodo_visual, nodo)
	
	return nodo_visual

func _configure_visual_node(nodo_visual: Node, nodo: TreeNode) -> void:
	if nodo_visual.has_method("set_visuals"):
		if nodo_visual.set_visuals is Callable:
			nodo_visual.set_visuals.call_deferred(nodo)
		else:
			nodo_visual.set_visuals(nodo.tipo)

func _create_connections(nodo: TreeNode, positions: Dictionary, offset: Vector2) -> void:
	var start_pos = positions[nodo] + offset
	
	if nodo.izquierdo and positions.has(nodo.izquierdo):
		var end_pos = positions[nodo.izquierdo] + offset
		lineas.append([start_pos, end_pos])
	
	if nodo.derecho and positions.has(nodo.derecho):
		var end_pos = positions[nodo.derecho] + offset
		lineas.append([start_pos, end_pos])

func _update_lineas_node() -> void:
	if lineas_node and lineas_node.has_method("actualizar_lineas"):
		lineas_node.actualizar_lineas(lineas)

# ========== OTRAS FUNCIONES ==========

func center_tree() -> void:
	if camera_controller == null:
		push_error("Camera controller not initialized")
		return
	var bounds = _get_tree_bounds()
	if bounds.size == Vector2.ZERO:
		return
	
	var viewport_center : Vector2 = size / 2.0
	var tree_center = bounds.get_center()
	var offset = viewport_center - tree_center
	
	camera_controller.center_on_position(offset, animation_duration)
	
	if is_inside_tree():
		await get_tree().create_timer(animation_duration).timeout
	tree_centered.emit()

func fit_to_view() -> void:
	if camera_controller == null:
		push_error("Camera controller not initialized")
		return
	
	var bounds = _get_tree_bounds()
	if bounds.size == Vector2.ZERO:
		return
	
	camera_controller.fit_to_bounds(bounds, size)

func reset_view() -> void:
	if camera_controller == null:
		push_error("Camera controller not initialized")
		return
	
	camera_controller.reset_view(animation_duration)
	view_reset.emit()

func set_zoom(new_zoom: float) -> void:
	if camera_controller == null:
		push_error("Camera controller not initialized")
		return
	
	camera_controller.set_target_zoom(new_zoom)

func get_current_zoom() -> float:
	if camera_controller == null:
		return 1.0
	return camera_controller.get_current_zoom()

func _ensure_containers_ready() -> void:
	if nodos_container == null or lineas_node == null:
		_setup_containers()

func _clear_tree_visual() -> void:
	lineas.clear()
	node_to_visual.clear()
	current_node = null  # 🆕 Resetear nodo actual
	
	if nodos_container:
		for child in nodos_container.get_children():
			child.queue_free()
	
	_reset_containers_directly()

func _reset_containers_directly() -> void:
	if nodos_container:
		nodos_container.position = Vector2.ZERO
		nodos_container.scale = Vector2.ONE
	
	if lineas_node:
		lineas_node.position = Vector2.ZERO
		lineas_node.scale = Vector2.ONE
	
	if camera_controller:
		camera_controller.reset_containers()

func _get_tree_bounds() -> Rect2:
	if nodos_container == null or nodos_container.get_child_count() == 0:
		return Rect2()
	
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	for child in nodos_container.get_children():
		if child is Control or child is Node2D:
			var pos = child.position
			min_pos = min_pos.min(pos)
			max_pos = max_pos.max(pos)
	
	return Rect2(min_pos, max_pos - min_pos)

func _input(event: InputEvent) -> void:
	if camera_controller != null:
		camera_controller.handle_input(event)

func _process(delta: float) -> void:
	if camera_controller != null:
		camera_controller.process_camera(delta)
