extends Node
class_name TreeLayout

# Orientación y espaciado básico
@export_enum("vertical", "horizontal") var orientation := "vertical"
@export var node_spacing: float = 200.0
@export var subtree_spacing: float = 260.0
@export var level_spacing: float = 240.0

# Tamaño de nodos
@export_group("Tamaño de Nodos")
@export var node_width: float = 100.0
@export var use_node_size_in_spacing: bool = true

# Escalado y adaptación
@export_group("Escalado")
@export var vertical_scale_factor: float = 0.2
@export var use_adaptive_vertical_spacing: bool = false
@export var min_level_spacing: float = 180.0
@export var max_level_spacing: float = 380.0
@export_range(0.5, 2.0) var aspect_ratio: float = 1.6

# Espaciado entre hermanos
@export_group("Espaciado")
@export_range(0.1, 3.0) var sibling_spacing_multiplier: float = 3
@export_range(0.0, 1.0) var apportion_smoothing: float = 0.15
@export var compact_mode: bool = false
@export_range(0.5, 1.5) var compact_factor: float = 0.9

# Centrado y alineación
@export_group("Alineación")
@export_enum("center", "left", "right", "weighted_leaves", "weighted_children") var centering_mode := "weighted_leaves"
@export var align_leaf_nodes: bool = false
@export var center_tree_layout: bool = false

# Márgenes
@export_group("Márgenes")
@export var margin_top: float = 20.0
@export var margin_left: float = 20.0

# Balance
@export_group("Balance")
@export var balance_subtrees: bool = true

var _layout_data: Dictionary = {}  # TreeNode -> Dictionary con datos de layout

func _get_layout(node: TreeNode) -> Dictionary:
	if not _layout_data.has(node):
		var default_offsets: Array[Dictionary] = []
		var default_left: Array[float] = []
		var default_right: Array[float] = []
		_layout_data[node] = {
			"x": 0.0,
			"leaf_count": 0,
			"level": 0,
			"child_offsets": default_offsets,
			"left_contour": default_left,
			"right_contour": default_right,
			"subtree_left": 0.0,
			"subtree_right": 0.0
		}
	return _layout_data[node]

func _set_x(node: TreeNode, value: float) -> void:
	_get_layout(node)["x"] = value

func _get_x(node: TreeNode) -> float:
	return _get_layout(node)["x"]

# ------------------------------------------------------------
# FUNCIÓN PRINCIPAL DE LAYOUT
# ------------------------------------------------------------

func calculate_layout(root: TreeNode) -> Dictionary:
	if root == null:
		return {}

	# Limpiar datos anteriores
	_layout_data.clear()

	# Preparar estructura (hermanos, metadatos)
	_prepare_tree_structure(root)

	var base_spacing: float = node_spacing * sibling_spacing_multiplier
	if use_node_size_in_spacing:
		base_spacing = max(base_spacing, node_width)
	var subtree_gap: float = max(subtree_spacing, base_spacing)

	if compact_mode:
		base_spacing *= compact_factor
		subtree_gap *= compact_factor

	base_spacing = max(base_spacing, 1.0)
	subtree_gap = max(subtree_gap, 1.0)

	_measure_subtree(root, base_spacing, subtree_gap)
	_assign_world_positions(root, 0.0)

	var positions: Dictionary = {}
	_collect_positions(root, positions, 0, level_spacing)
	
	if align_leaf_nodes:
		_align_leaves(positions, root)
	
	positions = _normalize_positions(positions)
	positions = _apply_margins(positions)
	positions = _center_tree(positions)
	
	return positions

# ------------------------------------------------------------
# PREPARACIÓN DEL ÁRBOL
# ------------------------------------------------------------

func _prepare_tree_structure(node: TreeNode, _parent: TreeNode = null, level: int = 0) -> void:
	var layout: Dictionary = _get_layout(node)
	layout["level"] = level
	
	var children: Array[TreeNode] = _get_tree_children(node)
	
	# Recorrer hijos en orden declarado
	for child in children:
		_prepare_tree_structure(child, node, level + 1)
	
	# Calcular metadata
	layout["leaf_count"] = _count_leaves(node)

# ------------------------------------------------------------
# HELPERS PARA NODOS
# ------------------------------------------------------------

func _get_tree_children(node: TreeNode) -> Array[TreeNode]:
	var result: Array[TreeNode] = []
	if node == null:
		return result
	for child in node.get_children():
		if child is TreeNode:
			result.append(child)
	return result

func _is_leaf(node: TreeNode) -> bool:
	if node == null:
		return false
	return _get_tree_children(node).is_empty()

# ------------------------------------------------------------
# POSICIONAMIENTO INICIAL (NUEVO ALGORITMO)
# ------------------------------------------------------------

func _measure_subtree(node: TreeNode, node_gap: float, subtree_gap: float) -> void:
	if node == null:
		return

	var layout: Dictionary = _get_layout(node)
	var children: Array[TreeNode] = _get_tree_children(node)

	if children.is_empty():
		var half_span: float = node_gap * 0.5
		if use_node_size_in_spacing:
			half_span = max(node_width * 0.5, node_gap * 0.5)
		var empty_offsets: Array[Dictionary] = []
		var left_contour: Array[float] = [-half_span]
		var right_contour: Array[float] = [half_span]
		layout["child_offsets"] = empty_offsets
		layout["left_contour"] = left_contour
		layout["right_contour"] = right_contour
		layout["subtree_left"] = -half_span
		layout["subtree_right"] = half_span
		return

	for child in children:
		_measure_subtree(child, node_gap, subtree_gap)

	var child_offsets: Array[Dictionary] = []
	var aggregate_left: Array[float] = [0.0]
	var aggregate_right: Array[float] = [0.0]
	var separation: float = max(node_gap, subtree_gap)

	# Usa contornos acumulados para mantener separación horizontal entre subárboles
	# y conservar a los hijos únicos alineados con su padre.

	var empty_contour: Array[float] = []
	for child in children:
		var child_layout: Dictionary = _get_layout(child)
		var offset: float = 0.0
		var child_left_variant = child_layout.get("left_contour", empty_contour)
		var child_right_variant = child_layout.get("right_contour", empty_contour)
		var child_left_contour: Array[float] = child_left_variant as Array[float]
		var child_right_contour: Array[float] = child_right_variant as Array[float]
		if child_left_contour == null:
			child_left_contour = empty_contour
		if child_right_contour == null:
			child_right_contour = empty_contour
		if child_offsets.size() > 0:
			offset = _calculate_needed_offset(aggregate_right, child_left_contour, separation)
		child_offsets.append({"node": child, "offset": offset})
		_merge_contours(aggregate_left, aggregate_right, child_left_contour, child_right_contour, offset)

	var raw_left: float = 0.0
	var raw_right: float = 0.0
	for value in aggregate_left:
		raw_left = min(raw_left, value)
	for value in aggregate_right:
		raw_right = max(raw_right, value)

	var parent_x: float = _resolve_parent_anchor(node, children, child_offsets)
	if balance_subtrees and child_offsets.size() > 1:
		var span_center: float = (raw_left + raw_right) * 0.5
		parent_x = lerpf(parent_x, span_center, 0.5)

	var min_bound: float = 0.0
	var max_bound: float = 0.0
	for entry in child_offsets:
		var entry_dict: Dictionary = entry
		entry_dict["offset"] = float(entry_dict["offset"]) - parent_x
		var offset: float = float(entry_dict["offset"])
		min_bound = min(min_bound, offset)
		max_bound = max(max_bound, offset)

	for i in range(aggregate_left.size()):
		aggregate_left[i] = aggregate_left[i] - parent_x
		aggregate_right[i] = aggregate_right[i] - parent_x
		min_bound = min(min_bound, aggregate_left[i])
		max_bound = max(max_bound, aggregate_right[i])

	var half_width: float = node_gap * 0.5
	if use_node_size_in_spacing:
		half_width = node_width * 0.5
	aggregate_left[0] = min(aggregate_left[0], -half_width)
	aggregate_right[0] = max(aggregate_right[0], half_width)
	min_bound = min(min_bound, -half_width)
	max_bound = max(max_bound, half_width)

	layout["child_offsets"] = child_offsets
	layout["left_contour"] = aggregate_left
	layout["right_contour"] = aggregate_right
	layout["subtree_left"] = min_bound
	layout["subtree_right"] = max_bound

func _calculate_needed_offset(existing_right: Array[float], child_left: Array[float], gap: float) -> float:
	var offset: float = 0.0
	var max_depth: int = min(existing_right.size() - 1, child_left.size())
	for i in range(max_depth):
		var depth := i + 1
		if depth < existing_right.size():
			var required: float = float(existing_right[depth]) + gap
			var actual: float = float(child_left[i]) + offset
			offset = max(offset, required - actual)
	if apportion_smoothing > 0.0:
		offset = lerpf(offset, offset * apportion_smoothing, apportion_smoothing)
	return offset

func _merge_contours(aggregate_left: Array[float], aggregate_right: Array[float], child_left: Array[float], child_right: Array[float], offset: float) -> void:
	for i in range(child_left.size()):
		var depth := i + 1
		var left_val: float = float(child_left[i]) + offset
		var right_val: float = float(child_right[i]) + offset
		if depth >= aggregate_left.size():
			aggregate_left.append(left_val)
			aggregate_right.append(right_val)
		else:
			aggregate_left[depth] = min(aggregate_left[depth], left_val)
			aggregate_right[depth] = max(aggregate_right[depth], right_val)

func _resolve_parent_anchor(_node: TreeNode, children: Array[TreeNode], offsets: Array[Dictionary]) -> float:
	if offsets.is_empty():
		return 0.0
	if offsets.size() == 1:
		var single_entry: Dictionary = offsets[0]
		return float(single_entry["offset"])
	# Ajusta la posición horizontal del padre según el modo de centrado solicitado.
	match centering_mode:
		"left":
			var left_entry: Dictionary = offsets[0]
			return float(left_entry["offset"])
		"right":
			var right_entry: Dictionary = offsets[offsets.size() - 1]
			return float(right_entry["offset"])
		"weighted_children":
			var total: float = 0.0
			for entry in offsets:
				var entry_dict: Dictionary = entry
				total += float(entry_dict["offset"])
			return total / float(offsets.size())
		"weighted_leaves":
			var total_weight: float = 0.0
			var weighted_sum: float = 0.0
			for i in range(children.size()):
				var child: TreeNode = children[i]
				var entry_dict: Dictionary = offsets[i]
				var offset: float = float(entry_dict["offset"])
				var weight: float = float(_count_leaves(child))
				if weight <= 0.0:
					weight = 1.0
				total_weight += weight
				weighted_sum += offset * weight
			if total_weight > 0.0:
				return weighted_sum / total_weight
			var first_entry: Dictionary = offsets[0]
			var last_entry: Dictionary = offsets[offsets.size() - 1]
			return (float(first_entry["offset"]) + float(last_entry["offset"])) * 0.5
		_:
			var first_entry_default: Dictionary = offsets[0]
			var last_entry_default: Dictionary = offsets[offsets.size() - 1]
			return (float(first_entry_default["offset"]) + float(last_entry_default["offset"])) * 0.5

func _assign_world_positions(node: TreeNode, x_position: float) -> void:
	if node == null:
		return
	_set_x(node, x_position)
	var layout: Dictionary = _get_layout(node)
	var fallback_offsets: Array[Dictionary] = []
	var child_offsets: Array[Dictionary] = layout.get("child_offsets", fallback_offsets) as Array[Dictionary]
	if child_offsets == null:
		child_offsets = fallback_offsets
	for entry in child_offsets:
		var entry_dict: Dictionary = entry
		var child: TreeNode = entry_dict.get("node", null)
		if child == null:
			continue
		var offset: float = float(entry_dict.get("offset", 0.0))
		_assign_world_positions(child, x_position + offset)

# ------------------------------------------------------------
# RECOLECCIÓN DE POSICIONES
# ------------------------------------------------------------

func _collect_positions(node: TreeNode, positions: Dictionary, level: int, _level_spacing: float) -> void:
	if node == null:
		return

	var vertical_scale: float = 1.0
	if use_adaptive_vertical_spacing:
		vertical_scale = 1.0 + vertical_scale_factor * float(_count_levels(node))
	
	var effective_level_spacing: float = _level_spacing * vertical_scale
	effective_level_spacing = clamp(effective_level_spacing, min_level_spacing, max_level_spacing)
	
	var pos: Vector2
	if orientation == "vertical":
		pos = Vector2(_get_x(node) * aspect_ratio, float(level) * effective_level_spacing)
	else:
		pos = Vector2(float(level) * effective_level_spacing, _get_x(node) * aspect_ratio)
	
	positions[node] = pos

	var children: Array[TreeNode] = _get_tree_children(node)
	for child in children:
		_collect_positions(child, positions, level + 1, _level_spacing)

# ------------------------------------------------------------
# ALINEACIÓN DE HOJAS
# ------------------------------------------------------------

func _align_leaves(positions: Dictionary, root: TreeNode) -> void:
	var max_depth: int = _count_levels(root)
	var leaves: Array[TreeNode] = _collect_leaves(root)
	
	for leaf in leaves:
		if leaf in positions:
			var pos = positions[leaf]
			if orientation == "vertical":
				var target_y = (max_depth - 1) * level_spacing
				positions[leaf] = Vector2(pos.x, target_y)
			else:
				var target_x = (max_depth - 1) * level_spacing
				positions[leaf] = Vector2(target_x, pos.y)

func _collect_leaves(node: TreeNode) -> Array[TreeNode]:
	var leaves: Array[TreeNode] = []
	if _is_leaf(node):
		leaves.append(node)
	else:
		var children: Array[TreeNode] = _get_tree_children(node)
		for child in children:
			leaves.append_array(_collect_leaves(child))
	return leaves

# ------------------------------------------------------------
# FUNCIONES AUXILIARES
# ------------------------------------------------------------

func _count_leaves(node: TreeNode) -> int:
	if node == null:
		return 0
	if _is_leaf(node):
		return 1
	var count: int = 0
	var children: Array[TreeNode] = _get_tree_children(node)
	for child in children:
		count += _count_leaves(child)
	return count

func _count_levels(node: TreeNode) -> int:
	if node == null:
		return 0
	if _is_leaf(node):
		return 1
	var max_level: int = 0
	var children: Array[TreeNode] = _get_tree_children(node)
	for child in children:
		max_level = max(max_level, _count_levels(child))
	return max_level + 1

func _normalize_positions(positions: Dictionary) -> Dictionary:
	if positions.is_empty():
		return positions
	
	var min_x: float = INF
	var min_y: float = INF
	
	for pos in positions.values():
		min_x = minf(min_x, pos.x)
		min_y = minf(min_y, pos.y)
	
	if min_x < 0.0 or min_y < 0.0:
		for key in positions.keys():
			var pos = positions[key]
			positions[key] = Vector2(
				pos.x - (min_x if min_x < 0.0 else 0.0),
				pos.y - (min_y if min_y < 0.0 else 0.0)
			)
	
	return positions

func _apply_margins(positions: Dictionary) -> Dictionary:
	var offset: Vector2 = Vector2(margin_left, margin_top)
	for key in positions.keys():
		positions[key] += offset
	return positions

func _center_tree(positions: Dictionary) -> Dictionary:
	if positions.is_empty():
		return positions
	var min_x: float = INF
	var max_x: float = -INF
	for pos in positions.values():
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
	if center_tree_layout:
		var center_offset := -(max_x - min_x) / 2.0
		for key in positions.keys():
			positions[key].x += center_offset + margin_left
	else:
		var left_offset := margin_left - min_x
		for key in positions.keys():
			positions[key].x += left_offset
	return positions
