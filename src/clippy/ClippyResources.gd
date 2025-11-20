# ClippyResources.gd
# Documentation parser and template manager for Clippy assistant
# Godot 4.5+
#
# Responsibilities:
# - Parse README.md and minigame documentation files
# - Index keywords for fast lookup
# - Provide templates for text generation
# - Map events to relevant documentation sections
#
# Usage:
#   var resources = ClippyResources.new()
#   resources.load_project_docs("res://README.md")
#   var text = resources.get_text_for_event(event)

class_name ClippyResources
extends Node

## Documentation sections indexed by keyword
var _doc_sections: Dictionary = {}

## Templates for each event type
var _templates: Dictionary = {}

## Minigame documentation cache
var _minigame_docs: Dictionary = {}

## Keyword index for fast section lookup
var _keyword_index: Dictionary = {}

func _ready() -> void:
	_initialize_templates()

## Loads and parses project documentation
func load_project_docs(readme_path: String) -> void:
	if not FileAccess.file_exists(readme_path):
		push_error("ClippyResources: README not found at %s" % readme_path)
		return
	
	var file = FileAccess.open(readme_path, FileAccess.READ)
	if file == null:
		push_error("ClippyResources: Failed to open README at %s" % readme_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	_parse_readme(content)
	_build_keyword_index()

## Loads minigame-specific documentation
func load_minigame_doc(game_type: String, doc_path: String) -> void:
	if not FileAccess.file_exists(doc_path):
		push_warning("ClippyResources: Minigame doc not found: %s" % doc_path)
		return
	
	var file = FileAccess.open(doc_path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	_minigame_docs[game_type] = _parse_minigame_doc(content)

## Parses README into sections
func _parse_readme(content: String) -> void:
	var lines = content.split("\n")
	var current_section = ""
	var current_content = []
	
	for line in lines:
		# Check if line is a header (starts with #)
		if line.begins_with("#"):
			# Save previous section
			if current_section != "":
				_doc_sections[current_section] = "\n".join(current_content)
			
			# Start new section
			current_section = line.trim_prefix("#").strip_edges().to_lower()
			current_content = []
		else:
			current_content.append(line)
	
	# Save last section
	if current_section != "":
		_doc_sections[current_section] = "\n".join(current_content)

## Parses minigame documentation
func _parse_minigame_doc(content: String) -> Dictionary:
	var result = {
		"objective": "",
		"controls": "",
		"tips": [],
		"mechanics": []
	}
	
	var lines = content.split("\n")
	var current_section = ""
	var current_content = []
	
	for line in lines:
		if line.begins_with("## "):
			var header = line.trim_prefix("##").strip_edges().to_lower()
			
			if "objetivo" in header or "objective" in header:
				current_section = "objective"
			elif "control" in header:
				current_section = "controls"
			elif "consejo" in header or "tip" in header:
				current_section = "tips"
			elif "mecánica" in header or "mechanic" in header:
				current_section = "mechanics"
		elif line.strip_edges() != "" and current_section != "":
			if current_section in ["tips", "mechanics"]:
				if line.strip_edges().begins_with("-"):
					result[current_section].append(line.strip_edges().trim_prefix("-").strip_edges())
			else:
				current_content.append(line)
				result[current_section] = "\n".join(current_content)
	
	return result

## Builds keyword index for fast lookups
func _build_keyword_index() -> void:
	_keyword_index.clear()
	
	# Common keywords mapped to sections
	var keyword_map = {
		"tutorial": ["tutorial", "how to play", "getting started"],
		"controls": ["controls", "keyboard", "mouse"],
		"navigation": ["navigation", "tree", "nodes"],
		"tips": ["tips", "hints", "advice"],
		"mechanics": ["mechanics", "gameplay"],
		"scoring": ["scoring", "points", "lives"]
	}
	
	for category in keyword_map:
		for keyword in keyword_map[category]:
			for section_name in _doc_sections:
				if keyword in section_name:
					if not _keyword_index.has(category):
						_keyword_index[category] = []
					_keyword_index[category].append(section_name)

## Finds documentation section by keyword
func find_section(keyword: String) -> String:
	keyword = keyword.to_lower()
	
	# Direct match
	if _doc_sections.has(keyword):
		return _doc_sections[keyword]
	
	# Partial match
	for section_name in _doc_sections:
		if keyword in section_name:
			return _doc_sections[section_name]
	
	return ""

## Gets text template for event type
func get_template(event_type: ClippyEvent.EventType) -> String:
	return _templates.get(event_type, "{context}")

## Generates text for a given event using templates and documentation
func get_text_for_event(event: ClippyEvent) -> String:
	if event == null or not event.is_valid():
		return tr("CLIPPY_ERROR_INVALID_EVENT")
	
	var template = get_template(event.event_type)
	var context_text = ""
	
	match event.event_type:
		ClippyEvent.EventType.TUTORIAL_START:
			context_text = _get_tutorial_text(event)
		ClippyEvent.EventType.MINI_GAME_START:
			context_text = _get_minigame_text(event)
		ClippyEvent.EventType.PLAYER_ERROR:
			context_text = _get_error_text(event)
		ClippyEvent.EventType.PROGRESS_UPDATE:
			context_text = _get_progress_text(event)
		ClippyEvent.EventType.ACHIEVEMENT:
			context_text = _get_achievement_text(event)
		ClippyEvent.EventType.TREE_NODE_ENTERED:
			context_text = _get_node_text(event)
		ClippyEvent.EventType.HINT_REQUESTED:
			context_text = _get_hint_text(event)
		ClippyEvent.EventType.GAME_COMPLETED:
			context_text = tr("CLIPPY_GAME_COMPLETED")
	
	# Replace template placeholders
	return template.format({
		"context": context_text,
		"level": event.level_id,
		"area": event.context_id
	})

## Helper: Get tutorial text
func _get_tutorial_text(event: ClippyEvent) -> String:
	var section = find_section("controls")
	if section != "":
		return tr("CLIPPY_TUTORIAL_START") + "\n\n" + section.substr(0, 200)
	return tr("CLIPPY_TUTORIAL_GENERIC")

## Helper: Get minigame text
func _get_minigame_text(event: ClippyEvent) -> String:
	var game_type = event.payload.get("game_type", "")
	
	if _minigame_docs.has(game_type):
		var doc = _minigame_docs[game_type]
		var objective = doc.get("objective", "")
		return tr("CLIPPY_MINIGAME_START").format({"game": game_type}) + "\n\n" + objective
	
	return tr("CLIPPY_MINIGAME_GENERIC").format({"game": game_type})

## Helper: Get error text
func _get_error_text(event: ClippyEvent) -> String:
	var error_code = event.payload.get("error_code", "unknown")
	var attempt = event.payload.get("attempt", 1)
	
	# Map error codes to helpful messages
	var error_messages = {
		"wrong_answer": tr("CLIPPY_ERROR_WRONG_ANSWER"),
		"timeout": tr("CLIPPY_ERROR_TIMEOUT"),
		"invalid_input": tr("CLIPPY_ERROR_INVALID_INPUT")
	}
	
	var message = error_messages.get(error_code, tr("CLIPPY_ERROR_GENERIC"))
	
	if attempt > 2:
		message += "\n\n" + tr("CLIPPY_ERROR_HINT_SUGGESTION")
	
	return message

## Helper: Get progress text
func _get_progress_text(event: ClippyEvent) -> String:
	var completion = event.payload.get("completion", 0.0)
	
	if completion >= 0.75:
		return tr("CLIPPY_PROGRESS_HIGH")
	elif completion >= 0.5:
		return tr("CLIPPY_PROGRESS_MID")
	else:
		return tr("CLIPPY_PROGRESS_LOW")

## Helper: Get achievement text
func _get_achievement_text(event: ClippyEvent) -> String:
	return tr("CLIPPY_ACHIEVEMENT").format({
		"achievement": event.context_id
	})

## Helper: Get node entry text
func _get_node_text(event: ClippyEvent) -> String:
	return tr("CLIPPY_NODE_ENTERED").format({
		"node": event.context_id
	})

## Helper: Get hint text
func _get_hint_text(event: ClippyEvent) -> String:
	var tips_section = find_section("tips")
	if tips_section != "":
		return tips_section.substr(0, 150)
	return tr("CLIPPY_HINT_GENERIC")

## Initialize text templates
func _initialize_templates() -> void:
	_templates[ClippyEvent.EventType.TUTORIAL_START] = "{context}"
	_templates[ClippyEvent.EventType.MINI_GAME_START] = "{context}"
	_templates[ClippyEvent.EventType.PLAYER_ERROR] = "{context}"
	_templates[ClippyEvent.EventType.PROGRESS_UPDATE] = "{context}"
	_templates[ClippyEvent.EventType.ACHIEVEMENT] = "{context}"
	_templates[ClippyEvent.EventType.TREE_NODE_ENTERED] = "{context}"
	_templates[ClippyEvent.EventType.HINT_REQUESTED] = "{context}"
	_templates[ClippyEvent.EventType.GAME_COMPLETED] = "{context}"
