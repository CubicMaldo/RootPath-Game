# ClippyTemplateEngine.gd
# Template and text generation module for Clippy system
# Godot 4.5+
#
# Handles text generation from events using templates and documentation
#
# Usage:
#   var engine = ClippyTemplateEngine.new()
#   engine.set_content_index(index)
#   engine.set_minigame_docs(docs)
#   var text = engine.generate_text_for_event(event)

class_name ClippyTemplateEngine
extends RefCounted

## Templates for each event type
var _templates: Dictionary = {}

## Reference to content index for doc lookup
var _content_index: ClippyContentIndex = null

## Minigame documentation cache
var _minigame_docs: Dictionary = {}

const NODE_TYPE_VISIT_KEYS := {
	0: "CLIPPY_PROGRESS_VISIT_START",
	1: "CLIPPY_PROGRESS_VISIT_CHALLENGE",
	2: "CLIPPY_PROGRESS_VISIT_HINT",
	3: "CLIPPY_PROGRESS_VISIT_FINAL"
}

const SCORE_REASON_KEYS := {
	"hint_node": "CLIPPY_PROGRESS_SCORE_HINT",
	"challenge_visit": "CLIPPY_PROGRESS_SCORE_CHALLENGE",
	"goal_reached": "CLIPPY_PROGRESS_SCORE_FINAL"
}

const MINIGAME_COPY := {
	"email_phishing": {
		"intro": "CLIPPY_MINIGAME_EMAIL_INTRO",
		"objective": "CLIPPY_MINIGAME_EMAIL_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_EMAIL_TIP"
	},
	"port_scanner": {
		"intro": "CLIPPY_MINIGAME_PORT_SCANNER_INTRO",
		"objective": "CLIPPY_MINIGAME_PORT_SCANNER_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_PORT_SCANNER_TIP"
	},
	"sql_injection": {
		"intro": "CLIPPY_MINIGAME_SQL_INJECTION_INTRO",
		"objective": "CLIPPY_MINIGAME_SQL_INJECTION_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_SQL_INJECTION_TIP"
	},
	"password_cracker": {
		"intro": "CLIPPY_MINIGAME_PASSWORD_CRACKER_INTRO",
		"objective": "CLIPPY_MINIGAME_PASSWORD_CRACKER_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_PASSWORD_CRACKER_TIP"
	},
	"network_defender": {
		"intro": "CLIPPY_MINIGAME_NETWORK_DEFENDER_INTRO",
		"objective": "CLIPPY_MINIGAME_NETWORK_DEFENDER_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_NETWORK_DEFENDER_TIP"
	},
	"password_strength": {
		"intro": "CLIPPY_MINIGAME_PASSWORD_STRENGTH_INTRO",
		"objective": "CLIPPY_MINIGAME_PASSWORD_STRENGTH_OBJECTIVE",
		"tip": "CLIPPY_MINIGAME_PASSWORD_STRENGTH_TIP"
	},
	"default": {
		"intro": "CLIPPY_MINIGAME_START",
		"objective": "CLIPPY_MINIGAME_GENERIC",
		"tip": "CLIPPY_ERROR_HINT_SUGGESTION"
	}
}

func _init():
	_initialize_templates()

## Set content index reference
func set_content_index(index: ClippyContentIndex) -> void:
	_content_index = index

## Set minigame documentation
func set_minigame_docs(docs: Dictionary) -> void:
	_minigame_docs = docs

## Gets text template for event type
func get_template(event_type: ClippyEvent.EventType) -> String:
	return _templates.get(event_type, "{context}")

## Main text generation entry point
## Generates text for a given event using templates and documentation
func generate_text_for_event(event: ClippyEvent) -> String:
	if event == null or not event.is_valid():
		return tr("CLIPPY_ERROR_INVALID_EVENT")

	if event.payload.has("custom_text"):
		return str(event.payload.get("custom_text", ""))

	var template = get_template(event.event_type)
	var context_text = ""
	
	match event.event_type:
		ClippyEvent.EventType.TUTORIAL_START:
			context_text = generate_tutorial_text(event)
		ClippyEvent.EventType.MINI_GAME_START:
			context_text = generate_minigame_text(event)
		ClippyEvent.EventType.PLAYER_ERROR:
			context_text = generate_error_text(event)
		ClippyEvent.EventType.PROGRESS_UPDATE:
			context_text = generate_progress_text(event)
		ClippyEvent.EventType.ACHIEVEMENT:
			context_text = generate_achievement_text(event)
		ClippyEvent.EventType.TREE_NODE_ENTERED:
			context_text = generate_node_text(event)
		ClippyEvent.EventType.HINT_REQUESTED:
			context_text = generate_hint_text(event)
		ClippyEvent.EventType.GAME_COMPLETED:
			context_text = generate_completion_text(event)
		ClippyEvent.EventType.VIRUS_INFECTED:
			context_text = generate_virus_help_text(event)
		ClippyEvent.EventType.VIRUS_FAILED:
			context_text = generate_virus_failure_text(event)
		ClippyEvent.EventType.VIRUS_CLEARED:
			context_text = generate_virus_cleared_text(event)
	
	# Replace template placeholders
	return template.format({
		"context": context_text,
		"level": event.level_id,
		"area": event.context_id
	})

## Generate tutorial text
func generate_tutorial_text(_event: ClippyEvent) -> String:
	if _content_index:
		var section = _content_index.find_section("controls")
		if section != "":
			return tr("CLIPPY_TUTORIAL_START") + "\n\n" + section.substr(0, 200)
	return tr("CLIPPY_TUTORIAL_GENERIC")

## Generate minigame text
func generate_minigame_text(event: ClippyEvent) -> String:
	var game_type = event.payload.get("game_type", "")
	var descriptor: Dictionary = MINIGAME_COPY.get(game_type, MINIGAME_COPY["default"])
	var display_name = _format_game_name(event)
	var segments: Array[String] = []

	var intro_key: String = descriptor.get("intro", "")
	if intro_key != "":
		segments.append(tr(intro_key).format({"game": display_name}))

	var doc: Dictionary = _minigame_docs.get(game_type, {})
	var objective_text: String = ""
	if doc.has("objective"):
		objective_text = str(doc.get("objective", ""))
	if objective_text.strip_edges() == "":
		var objective_key: String = descriptor.get("objective", "")
		if objective_key != "":
			objective_text = tr(objective_key).format({"game": display_name})
	if objective_text.strip_edges() != "":
		segments.append(objective_text.strip_edges())

	var tip_text: String = _extract_tip(doc)
	if tip_text == "":
		var tip_key: String = descriptor.get("tip", "")
		if tip_key != "":
			tip_text = tr(tip_key)
	if tip_text.strip_edges() != "":
		segments.append(tip_text.strip_edges())

	if segments.is_empty():
		return tr("CLIPPY_MINIGAME_GENERIC").format({"game": display_name})

	return "\n\n".join(segments)

## Generate error text
func generate_error_text(event: ClippyEvent) -> String:
	var error_code = event.payload.get("error_code", "unknown")
	var attempt = event.payload.get("attempt", 1)
	
	# Map error codes to helpful messages
	var error_messages = {
		"wrong_answer": tr("CLIPPY_ERROR_WRONG_ANSWER"),
		"timeout": tr("CLIPPY_ERROR_TIMEOUT"),
		"invalid_input": tr("CLIPPY_ERROR_INVALID_INPUT"),
		"challenge_failed": tr("CLIPPY_ERROR_CHALLENGE_FAILED"),
		"navigation_blocked": tr("CLIPPY_ERROR_NAVIGATION_BLOCKED"),
		"game_over": tr("CLIPPY_ERROR_GAME_OVER")
	}
	
	var message = error_messages.get(error_code, tr("CLIPPY_ERROR_GENERIC"))
	
	if attempt > 2:
		message += "\n\n" + tr("CLIPPY_ERROR_HINT_SUGGESTION")
	
	return message

## Generate progress text
func generate_progress_text(event: ClippyEvent) -> String:
	if event.payload.has("action"):
		return _generate_progress_text_for_action(event.payload)

	if event.payload.has("new_score"):
		return _generate_progress_text_for_score(event.payload)
		
	var completion = event.payload.get("completion", 0.0)
	
	if completion >= 0.75:
		return tr("CLIPPY_PROGRESS_HIGH")
	elif completion >= 0.5:
		return tr("CLIPPY_PROGRESS_MID")
	else:
		return tr("CLIPPY_PROGRESS_LOW")

## Generate achievement text
func generate_achievement_text(event: ClippyEvent) -> String:
	return tr("CLIPPY_ACHIEVEMENT").format({
		"achievement": event.context_id
	})

## Generate node entry text
func generate_node_text(event: ClippyEvent) -> String:
	return tr("CLIPPY_NODE_ENTERED").format({
		"node": event.context_id
	})

## Generate hint text
func generate_hint_text(_event: ClippyEvent) -> String:
	if _content_index:
		var tips_section = _content_index.find_section("tips")
		if tips_section != "":
			return tips_section.substr(0, 150)
	return tr("CLIPPY_HINT_GENERIC")

## Generate completion text
func generate_completion_text(_event: ClippyEvent) -> String:
	return tr("CLIPPY_GAME_COMPLETED")

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
	_templates[ClippyEvent.EventType.VIRUS_INFECTED] = "{context}"
	_templates[ClippyEvent.EventType.VIRUS_FAILED] = "{context}"
	_templates[ClippyEvent.EventType.VIRUS_CLEARED] = "{context}"

func _generate_progress_text_for_action(payload: Dictionary) -> String:
	var action: String = str(payload.get("action", ""))
	var node_label: String = _format_node_label(payload)
	if action == "visited":
		var node_type: int = int(payload.get("node_type", -1))
		var key: String = NODE_TYPE_VISIT_KEYS.get(node_type, "CLIPPY_PROGRESS_VISIT_GENERIC")
		return tr(key).format({"node": node_label})
	elif action == "discovered":
		return tr("CLIPPY_PROGRESS_DISCOVERED_NODE").format({"node": node_label})
	return tr("CLIPPY_PROGRESS_LOW")

func _generate_progress_text_for_score(payload: Dictionary) -> String:
	var reason_code: String = str(payload.get("reason_code", "generic"))
	var key: String = SCORE_REASON_KEYS.get(reason_code, "CLIPPY_PROGRESS_SCORE_GENERIC")
	var delta: int = int(payload.get("delta", 0))
	var new_score: int = int(payload.get("new_score", 0))
	var reason: String = str(payload.get("reason", ""))
	return tr(key).format({
		"delta": delta,
		"score": new_score,
		"reason": reason
	})

func _format_node_label(payload: Dictionary) -> String:
	var node_label: String = str(payload.get("node_label", ""))
	if node_label == "" or node_label == "unknown":
		return tr("CLIPPY_NODE_UNKNOWN_LABEL")
	return node_label

func _format_game_name(event: ClippyEvent) -> String:
	if event == null:
		return ""
	var payload := event.payload
	if payload.has("node_id") and str(payload.node_id) != "":
		return str(payload.node_id)
	if event.context_id != "":
		return event.context_id
	var game_type: String = str(payload.get("game_type", ""))
	return _prettify_identifier(str(game_type))

func _extract_tip(doc: Dictionary) -> String:
	if doc.is_empty():
		return ""
	if doc.has("tips"):
		var tips = doc.get("tips", [])
		if tips is Array and not tips.is_empty():
			return str(tips[0])
	return ""

func _prettify_identifier(id_text: String) -> String:
	if id_text == "":
		return ""
	var words := id_text.replace("_", " ").split(" ")
	for i in range(words.size()):
		if words[i].length() > 0:
			words[i] = words[i][0].to_upper() + words[i].substr(1)
	return " ".join(words)

# ---------------------------------------------------------------------------
# Virus Event Text Generation
# ---------------------------------------------------------------------------

## Generate virus help text
func generate_virus_help_text(event: ClippyEvent) -> String:
	var virus_type = event.context_id
	var virus_name = event.payload.get("virus_name", "Virus")
	
	# Get localized help text
	var help_text = _get_virus_help_localized(virus_type)
	
	return tr("CLIPPY_VIRUS_INFECTED").format({
		"virus_name": virus_name,
		"help_text": help_text
	})

## Generate virus failure text
func generate_virus_failure_text(event: ClippyEvent) -> String:
	var failed = event.payload.get("failed_count", 0)
	var max_fails = event.payload.get("max_failures", 3)
	var remaining = event.payload.get("remaining", 0)
	
	if remaining == 0:
		return tr("CLIPPY_VIRUS_FAILED_CRITICAL").format({
			"failed_count": failed,
			"max_failures": max_fails
		})
	elif remaining == 1:
		return tr("CLIPPY_VIRUS_FAILED_WARNING").format({
			"failed_count": failed,
			"max_failures": max_fails,
			"remaining": remaining
		})
	else:
		return tr("CLIPPY_VIRUS_FAILED_NORMAL").format({
			"failed_count": failed,
			"max_failures": max_fails,
			"remaining": remaining
		})

## Generate virus cleared text
func generate_virus_cleared_text(event: ClippyEvent) -> String:
	var virus_name = event.payload.get("virus_name", "virus")
	return tr("CLIPPY_VIRUS_CLEARED").format({"virus_name": virus_name})

## Get localized help for virus type
func _get_virus_help_localized(virus_type: String) -> String:
	# Try to find virus help section in content index first
	if _content_index:
		var section = _content_index.find_section(virus_type)
		if section != "":
			return section.strip_edges()
	
	# Map virus type to localization key
	var help_key_map = {
		"fake_update": "CLIPPY_VIRUS_HELP_FAKE_UPDATE",
		"captcha": "CLIPPY_VIRUS_HELP_CAPTCHA",
		"survey": "CLIPPY_VIRUS_HELP_SURVEY",
		"glitch": "CLIPPY_VIRUS_HELP_GLITCH",
		"adware": "CLIPPY_VIRUS_HELP_ADWARE",
		"phishing": "CLIPPY_VIRUS_HELP_PHISHING"
	}
	
	var help_key = help_key_map.get(virus_type, "CLIPPY_VIRUS_HELP_DEFAULT")
	return tr(help_key)
