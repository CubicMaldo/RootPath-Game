# ClippyResources.gd
# REFACTORED - Documentation manager for Clippy assistant
# Godot 4.5+
#
# This class now acts as a coordinator for the three specialized modules:
# - ClippyDocumentParser: Parses Markdown documentation
# - ClippyContentIndex: Indexes and searches documentation
# - ClippyTemplateEngine: Generates text from events
#
# Usage:
#   var resources = ClippyResources.new()
#   resources.load_project_docs("res://README.md")
#   var text = resources.get_text_for_event(event)

class_name ClippyResources
extends Node

## Document parser module
var _parser: ClippyDocumentParser

## Content indexing module  
var _index: ClippyContentIndex

## Template and text generation module
var _template_engine: ClippyTemplateEngine

## Minigame documentation cache
var _minigame_docs: Dictionary = {}

func _ready() -> void:
	_initialize_modules()

## Initialize all subsystems
func _initialize_modules() -> void:
	_parser = ClippyDocumentParser.new()
	_index = ClippyContentIndex.new()
	_template_engine = ClippyTemplateEngine.new()
	
	# Link modules
	_template_engine.set_content_index(_index)

## Loads and parses project documentation
func load_project_docs(readme_path: String) -> void:
	var sections = _parser.load_and_parse_file(readme_path, false)
	
	if sections.is_empty():
		push_error("ClippyResources: Failed to load documentation from %s" % readme_path)
		return
	
	_index.set_sections(sections)
	print("[ClippyResources] Loaded %d documentation sections" % sections.size())

## Loads minigame-specific documentation
func load_minigame_doc(game_type: String, doc_path: String) -> void:
	var doc = _parser.load_and_parse_file(doc_path, true)
	
	if doc.is_empty():
		# File doesn't exist or failed to parse (caller checks existence)
		return
	
	_minigame_docs[game_type] = doc
	_template_engine.set_minigame_docs(_minigame_docs)
	print("[ClippyResources] Loaded documentation for minigame: %s" % game_type)

## Main entry point: Generate text for event
func get_text_for_event(event: ClippyEvent) -> String:
	return _template_engine.generate_text_for_event(event)

## Legacy compatibility: Find section by keyword
func find_section(keyword: String) -> String:
	return _index.find_section(keyword)

## Legacy compatibility: Get template
func get_template(event_type: ClippyEvent.EventType) -> String:
	return _template_engine.get_template(event_type)

## Get content index (for advanced usage)
func get_content_index() -> ClippyContentIndex:
	return _index

## Get template engine (for advanced usage)
func get_template_engine() -> ClippyTemplateEngine:
	return _template_engine

## Get parser (for advanced usage)
func get_parser() -> ClippyDocumentParser:
	return _parser
