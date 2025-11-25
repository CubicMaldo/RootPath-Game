class_name TreeDebugger
extends Node

## Utility class for debugging tree state with visibility
## Decoupled from both tree generation and game logic

static func print_tree_with_visibility(
	tree: Arbol,
	visibility: VisibilityTracker,
	current_node: TreeNode,
	nodo: TreeNode = null,
	prefijo: String = "",
	es_izq: bool = true
) -> void:
	if nodo == null:
		nodo = tree.raiz
	
	if nodo == null:
		return
	
	# VERIFICAR SI ESTÁ DESCUBIERTO ANTES DE PROCESAR
	if not visibility.is_discovered(nodo):
		return
	
	# Print right subtree (solo si existe Y está descubierto)
	if nodo.derecho != null and visibility.is_discovered(nodo.derecho):
		print_tree_with_visibility(tree, visibility, current_node, nodo.derecho, 
			prefijo + ("│   " if es_izq else "    "), false)
	
	# Print current node
	var tipo_str = _tipo_to_string(nodo.tipo)
	var marker = ""
	
	if nodo == current_node:
		marker = " ⬅️"
	elif visibility.is_visited(nodo):
		marker = " ✓"
	
	print(prefijo + ("└── " if es_izq else "┌── ") + tipo_str + marker)
	
	# Print left subtree (solo si existe Y está descubierto)
	if nodo.izquierdo != null and visibility.is_discovered(nodo.izquierdo):
		print_tree_with_visibility(tree, visibility, current_node, nodo.izquierdo,
			prefijo + ("    " if es_izq else "│   "), true)

static func print_full_tree(tree: Arbol, current_node: TreeNode = null) -> void:
	_print_tree_recursive(tree.raiz, current_node, "", true)

static func _print_tree_recursive(
	nodo: TreeNode,
	current_node: TreeNode,
	prefijo: String,
	es_izq: bool
) -> void:
	if nodo == null:
		return
	
	_print_tree_recursive(nodo.derecho, current_node, 
		prefijo + ("│   " if es_izq else "    "), false)
	
	var tipo_str = _tipo_to_string(nodo.tipo)
	var marker = " ⬅️" if nodo == current_node else ""
	
	print(prefijo + ("└── " if es_izq else "┌── ") + tipo_str + marker)
	
	_print_tree_recursive(nodo.izquierdo, current_node,
		prefijo + ("    " if es_izq else "│   "), true)

static func _tipo_to_string(tipo: int) -> String:
	match tipo:
		Arbol.NodosJuego.INICIO: return "INICIO"
		Arbol.NodosJuego.DESAFIO: return "DESAFIO"
		Arbol.NodosJuego.PISTA: return "PISTA"
		Arbol.NodosJuego.FINAL: return "FINAL"
		_: return str(tipo)

static func get_tree_stats(tree: Arbol) -> Dictionary:
	var stats = {
		"total_nodes": 0,
		"inicio": 0,
		"desafio": 0,
		"pista": 0,
		"final": 0,
		"max_depth": 0
	}
	
	_count_nodes(tree.raiz, stats, 0)
	return stats

static func _count_nodes(nodo: TreeNode, stats: Dictionary, depth: int) -> void:
	if nodo == null:
		return
	
	stats.total_nodes += 1
	stats.max_depth = max(stats.max_depth, depth)
	
	match nodo.tipo:
		Arbol.NodosJuego.INICIO: stats.inicio += 1
		Arbol.NodosJuego.DESAFIO: stats.desafio += 1
		Arbol.NodosJuego.PISTA: stats.pista += 1
		Arbol.NodosJuego.FINAL: stats.final += 1
	
	_count_nodes(nodo.izquierdo, stats, depth + 1)
	_count_nodes(nodo.derecho, stats, depth + 1)
