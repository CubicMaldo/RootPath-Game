extends Node

## Simplified global - only holds the game controller reference
## All game logic is now in TreeAppController

var treeMap : TreeAppController

## Optional autoload references cached for backwards compatibility
var ClippyBridge: Node = null
var should_show_clippy_intro := false

func _ready() -> void:
	_refresh_optional_singletons()

func ensure_tree_map() -> TreeAppController:
	## Lazily create the TreeAppController when the app is opened
	if treeMap == null:
		treeMap = TreeAppController.new()
		add_child(treeMap)
	return treeMap

func report_challenge_result(win: bool) -> void:
	if treeMap == null:
		return
	treeMap.report_challenge_result(win)

func has_singleton(singleton_name: StringName) -> bool:
	return _get_singleton(singleton_name) != null

func get_singleton(singleton_name: StringName) -> Node:
	return _get_singleton(singleton_name)

func _refresh_optional_singletons() -> void:
	ClippyBridge = _get_singleton("ClippyBridge")

func _get_singleton(singleton_name: StringName) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var root := tree.root
	if root == null:
		return null
	return root.get_node_or_null(NodePath(singleton_name))
