# ClippyDocumentParser.gd
# Document parsing module for Clippy system
# Godot 4.5+
#
# Handles parsing of Markdown documentation files
# Extracts sections, lists, and structured content
#
# Usage:
#   var parser = ClippyDocumentParser.new()
#   var sections = parser.parse_markdown(content)

class_name ClippyDocumentParser
extends RefCounted

## Parses README/Markdown content into sections
## Returns Dictionary with section names as keys
func parse_markdown(content: String) -> Dictionary:
	var sections: Dictionary = {}
	var lines = content.split("\n")
	var current_section = ""
	var current_content = []
	
	for line in lines:
		# Check if line is a header (starts with #)
		if line.begins_with("#"):
			# Save previous section
			if current_section != "":
				sections[current_section] = "\n".join(current_content)
			
			# Start new section
			current_section = line.trim_prefix("#").strip_edges().to_lower()
			current_content = []
		else:
			current_content.append(line)
	
	# Save last section
	if current_section != "":
		sections[current_section] = "\n".join(current_content)
	
	return sections

## Parses minigame documentation with specific structure
## Returns structured dictionary with objective, controls, tips, mechanics
func parse_minigame_doc(content: String) -> Dictionary:
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

## Loads and parses a file
## Returns parsed sections or empty dict on error
func load_and_parse_file(file_path: String, is_minigame: bool = false) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		# File not found is no longer a warning since caller checks existence
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("ClippyDocumentParser: Failed to open file: %s" % file_path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	if is_minigame:
		return parse_minigame_doc(content)
	else:
		return parse_markdown(content)
