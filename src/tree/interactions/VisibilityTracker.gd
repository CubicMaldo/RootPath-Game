extends Node
class_name VisibilityTracker

signal node_discovered(node: TreeNode)
signal node_visited(node: TreeNode)
signal current_node_changed(new_node: TreeNode, old_node: TreeNode)

# 🎯 FUENTE DE VERDAD
var current_node: TreeNode = null
var discovered_nodes: Dictionary = {}
var visited_nodes: Dictionary = {}
var debug_mode: bool = true

func _ready() -> void:
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_mode:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var is_f3 : bool = event.keycode == KEY_F3
		var is_x : bool = event.keycode == KEY_X
		if (is_f3 and Input.is_key_pressed(KEY_X)) or (is_x and Input.is_key_pressed(KEY_F3)):
			print("[VisibilityTracker] Combo F3+X detectado (key=%s)" % event.keycode)
			_reveal_entire_tree()

func move_to_node(node: TreeNode) -> void:
	"""Mueve al jugador a un nuevo nodo"""
	if node == null or node == current_node:
		return

	var old_node = current_node
	current_node = node  #Actualizar fuente de verdad

	# Descubrir nodo
	if not discovered_nodes.has(node):
		discover_node(node)

	# Marcar como visitado
	if not visited_nodes.has(node):
		visited_nodes[node] = true
		node_visited.emit(node)

	# Notificar cambio
	current_node_changed.emit(current_node, old_node)

func discover_node(node: TreeNode) -> void:
	if node == null:
		return
	
	if not is_discovered(node):
		discovered_nodes[node] = true
		node_discovered.emit(node)

func visit_node(node: TreeNode) -> void:
	if node == null:
		return
	
	discover_node(node)
	
	if not is_visited(node):
		visited_nodes[node] = true
		node_visited.emit(node)

func reveal_children(node: TreeNode) -> void:
	if node == null:
		return
	
	if node.izquierdo != null:
		discover_node(node.izquierdo)
	
	if node.derecho != null:
		discover_node(node.derecho)

func is_discovered(node: TreeNode) -> bool:
	return discovered_nodes.has(node)

func is_visited(node: TreeNode) -> bool:
	return visited_nodes.has(node)

func get_discovered_count() -> int:
	return discovered_nodes.size()

func get_visited_count() -> int:
	return visited_nodes.size()

func reset() -> void:
	discovered_nodes.clear()
	visited_nodes.clear()

func forced_discovery(node : TreeNode)->void:
	while node.padre:
		discover_node(node)
		node = node.padre

func _reveal_entire_tree() -> void:
	var root := current_node
	if root == null and discovered_nodes.size() > 0:
		root = discovered_nodes.keys()[0]
	if root == null:
		print("[VisibilityTracker] No hay nodo inicial para revelar el árbol completo")
		return
	while root.padre != null:
		root = root.padre
	print("[VisibilityTracker] Revelando árbol completo desde %s" % root)
	_reveal_recursive(root)

func _reveal_recursive(node: TreeNode) -> void:
	if node == null:
		return
	discover_node(node)
	visit_node(node)
	print("[VisibilityTracker] Nodo marcado como visible: %s" % node)
	_reveal_recursive(node.izquierdo)
	_reveal_recursive(node.derecho)
