# ClippyContentIndex.gd
# Content indexing and search module for Clippy system
# Godot 4.5+
#
# Handles keyword indexing and document section lookup
#
# Usage:
#   var index = ClippyContentIndex.new()
#   index.build_index(sections)
#   var section = index.find_section("controls")

class_name ClippyContentIndex
extends RefCounted

## Documentation sections indexed by name
var _doc_sections: Dictionary = {}

## Keyword index for fast section lookup
var _keyword_index: Dictionary = {}

## Initialize with documentation sections
func set_sections(sections: Dictionary) -> void:
	_doc_sections = sections
	build_keyword_index()

## Builds keyword index for fast lookups
func build_keyword_index() -> void:
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
## Returns section content or empty string if not found
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

## Finds section by category (from keyword index)
func find_by_category(category: String) -> Array[String]:
	if _keyword_index.has(category):
		return _keyword_index[category]
	return []

## Search for content containing query
## Returns array of section names that match
func search_content(query: String) -> Array[String]:
	var results: Array[String] = []
	
	for section_name in _doc_sections:
		var content: String = _doc_sections[section_name]
		if query.to_lower() in content.to_lower() or query.to_lower() in section_name.to_lower():
			results.append(section_name)
	
	return results

## Get all section names
func get_all_sections() -> Array[String]:
	var sections: Array[String] = []
	for key in _doc_sections.keys():
		sections.append(key)
	return sections
