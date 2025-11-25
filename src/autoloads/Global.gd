extends Node

## Simplified global - only holds the game controller reference
## All game logic is now in TreeAppController

var treeMap : TreeAppController

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
