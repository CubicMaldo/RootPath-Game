# ClippyEventSchema.gd
# Schema definitions and validation for ClippyEvent types
# Godot 4.5+
#
# This class provides:
# - Schema definitions for each event type
# - Robust validation of event structure and payload
# - Clear error messages for debugging
# - Extensible design for new event types
#
# Usage:
#   var result = ClippyEventSchema.validate_event(event)
#   if not result.valid:
#       print("Validation errors: ", result.errors)

class_name ClippyEventSchema
extends RefCounted

## Schema definition for a single field
class FieldSchema:
	var field_name: String
	var field_type: Variant.Type
	var required: bool
	var default_value: Variant
	var allowed_values: Array = [] # Empty = any value allowed
	
	func _init(name: String, type: Variant.Type, is_required: bool = true, default = null, allowed: Array = []):
		field_name = name
		field_type = type
		required = is_required
		default_value = default
		allowed_values = allowed

## Validation result structure
class ValidationResult:
	var valid: bool = true
	var errors: Array[String] = []
	var warnings: Array[String] = []
	
	func add_error(message: String) -> void:
		errors.append(message)
		valid = false
	
	func add_warning(message: String) -> void:
		warnings.append(message)
	
	func get_summary() -> String:
		if valid:
			var summary = "✓ Validation passed"
			if not warnings.is_empty():
				summary += " (with %d warnings)" % warnings.size()
			return summary
		else:
			return "✗ Validation failed with %d errors" % errors.size()

## Get schema definition for an event type
static func get_schema(event_type: ClippyEvent.EventType) -> Dictionary:
	match event_type:
		ClippyEvent.EventType.TUTORIAL_START:
			return {
				"event_name": "TUTORIAL_START",
				"requires_context_id": true,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("section", TYPE_STRING, false)
				]
			}
		
		ClippyEvent.EventType.MINI_GAME_START:
			return {
				"event_name": "MINI_GAME_START",
				"requires_context_id": true,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("game_type", TYPE_STRING, true),
					FieldSchema.new("difficulty", TYPE_STRING, false, "normal", ["easy", "normal", "hard"]),
					FieldSchema.new("lives", TYPE_INT, false, 3),
					FieldSchema.new("node_id", TYPE_STRING, false)
				]
			}
		
		ClippyEvent.EventType.PLAYER_ERROR:
			return {
				"event_name": "PLAYER_ERROR",
				"requires_context_id": false,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("error_code", TYPE_STRING, true, null, [
						"wrong_answer",
						"timeout",
						"invalid_input",
						"challenge_failed",
						"navigation_blocked",
						"game_over"
					]),
					FieldSchema.new("attempt", TYPE_INT, false, 1)
				]
			}
		
		ClippyEvent.EventType.PROGRESS_UPDATE:
			return {
				"event_name": "PROGRESS_UPDATE",
				"requires_context_id": false,
				"requires_level_id": false,
				"payload_schema": [
					# At least one of these must be present
					FieldSchema.new("completion", TYPE_FLOAT, false),
					FieldSchema.new("action", TYPE_STRING, false),
					FieldSchema.new("new_score", TYPE_INT, false),
					FieldSchema.new("node_id", TYPE_STRING, false),
					FieldSchema.new("custom_text", TYPE_STRING, false)
				],
				"custom_validation": func(payload: Dictionary, result: ValidationResult):
					# Must have at least one progress indicator
					if not (payload.has("completion") or payload.has("action") or payload.has("new_score") or payload.has("custom_text")):
						result.add_error("PROGRESS_UPDATE must have at least one of: completion, action, new_score, or custom_text")
					
					# Validate completion range
					if payload.has("completion"):
						var comp = payload.completion
						if comp < 0.0 or comp > 1.0:
							result.add_error("completion must be between 0.0 and 1.0, got %s" % comp)
			}
		
		ClippyEvent.EventType.ACHIEVEMENT:
			return {
				"event_name": "ACHIEVEMENT",
				"requires_context_id": true,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("achievement_name", TYPE_STRING, false),
					FieldSchema.new("points_earned", TYPE_INT, false),
					FieldSchema.new("node_id", TYPE_STRING, false)
				]
			}
		
		ClippyEvent.EventType.TREE_NODE_ENTERED:
			return {
				"event_name": "TREE_NODE_ENTERED",
				"requires_context_id": true,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("node_id", TYPE_STRING, false)
				]
			}
		
		ClippyEvent.EventType.HINT_REQUESTED:
			return {
				"event_name": "HINT_REQUESTED",
				"requires_context_id": false,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("hint_type", TYPE_STRING, false)
				]
			}
		
		ClippyEvent.EventType.GAME_COMPLETED:
			return {
				"event_name": "GAME_COMPLETED",
				"requires_context_id": false,
				"requires_level_id": false,
				"payload_schema": [
					FieldSchema.new("victory", TYPE_BOOL, false, true),
					FieldSchema.new("final_score", TYPE_INT, false)
				]
			}
		
		_:
			return {
				"event_name": "UNKNOWN",
				"requires_context_id": false,
				"requires_level_id": false,
				"payload_schema": []
			}

## Validate a ClippyEvent against its schema
static func validate_event(event: ClippyEvent) -> ValidationResult:
	var result = ValidationResult.new()
	
	if event == null:
		result.add_error("Event is null")
		return result
	
	var schema = get_schema(event.event_type)
	
	# Validate context_id requirement
	if schema.requires_context_id and event.context_id.is_empty():
		result.add_error("%s requires context_id to be set" % schema.event_name)
	
	# Validate level_id requirement
	if schema.requires_level_id and event.level_id.is_empty():
		result.add_error("%s requires level_id to be set" % schema.event_name)
	
	# Validate payload schema
	if schema.has("payload_schema"):
		_validate_payload(event.payload, schema.payload_schema, schema.event_name, result)
	
	# Run custom validation if present
	if schema.has("custom_validation"):
		schema.custom_validation.call(event.payload, result)
	
	return result

## Validate payload against field schemas
static func _validate_payload(payload: Dictionary, field_schemas: Array, event_name: String, result: ValidationResult) -> void:
	for field_schema in field_schemas:
		var field: FieldSchema = field_schema
		
		# Check if required field is present
		if field.required and not payload.has(field.field_name):
			result.add_error("%s payload missing required field: %s" % [event_name, field.field_name])
			continue
		
		# Skip validation if field is not present and not required
		if not payload.has(field.field_name):
			continue
		
		var value = payload[field.field_name]
		
		# Check type
		if typeof(value) != field.field_type:
			result.add_error("%s field '%s' has wrong type: expected %s, got %s" % [
				event_name,
				field.field_name,
				type_string(field.field_type),
				type_string(typeof(value))
			])
			continue
		
		# Check allowed values if specified
		if not field.allowed_values.is_empty():
			if value not in field.allowed_values:
				result.add_error("%s field '%s' has invalid value '%s'. Allowed: %s" % [
					event_name,
					field.field_name,
					str(value),
					str(field.allowed_values)
				])

## Helper to get readable type name
static func type_string(type: Variant.Type) -> String:
	match type:
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
		_: return "Variant"

## Get all required fields for an event type (useful for debugging/documentation)
static func get_required_fields(event_type: ClippyEvent.EventType) -> Dictionary:
	var schema = get_schema(event_type)
	var required_fields = {
		"context_id": schema.requires_context_id,
		"level_id": schema.requires_level_id,
		"payload": {}
	}
	
	if schema.has("payload_schema"):
		for field_schema in schema.payload_schema:
			var field: FieldSchema = field_schema
			if field.required:
				required_fields.payload[field.field_name] = type_string(field.field_type)
	
	return required_fields
