class_name PlayerNavigator
extends Node

## Handles player's current position in the tree and navigation logic
## Completely independent of the tree generation

signal node_changed(old_node: TreeNode, new_node: TreeNode)
signal navigation_blocked(direction: String, reason: String)

var current_node: TreeNode = null
var navigation_history: Array[TreeNode] = []

func _init(starting_node: TreeNode = null):
	if starting_node:
		set_current_node(starting_node)

func set_current_node(node: TreeNode) -> void:
	if node == null:
		push_warning("Attempted to set null node")
		return
	
	var old_node = current_node
	current_node = node
	navigation_history.append(node)
	emit_signal("node_changed", old_node, current_node)

func move_left() -> bool:
	if current_node == null:
		emit_signal("navigation_blocked", "left", "No current node")
		return false
	
	if current_node.izquierdo == null:
		emit_signal("navigation_blocked", "left", "No left child")
		return false
	
	set_current_node(current_node.izquierdo)
	return true

func move_right() -> bool:
	if current_node == null:
		emit_signal("navigation_blocked", "right", "No current node")
		return false
	
	if current_node.derecho == null:
		emit_signal("navigation_blocked", "right", "No right child")
		return false
	
	set_current_node(current_node.derecho)
	return true

func move_to_parent() -> bool:
	if current_node == null:
		emit_signal("navigation_blocked", "parent", "No current node")
		return false
	
	if current_node.padre == null:
		emit_signal("navigation_blocked", "parent", "Already at root")
		return false
	
	set_current_node(current_node.padre)
	return true

func can_move_left() -> bool:
	return current_node != null and current_node.izquierdo != null

func can_move_right() -> bool:
	return current_node != null and current_node.derecho != null

func can_move_to_parent() -> bool:
	return current_node != null and current_node.padre != null

func get_navigation_depth() -> int:
	return navigation_history.size()

func get_current_position_depth() -> int:
	var depth = 0
	var node = current_node
	while node != null and node.padre != null:
		depth += 1
		node = node.padre
	return depth
