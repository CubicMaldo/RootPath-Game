extends Resource
class_name SQLQueryResource

## Recurso que representa una consulta SQL en el minijuego SQL Injection Defender

@export var query_text: String = ""
@export var user_input: String = ""
@export var is_malicious: bool = false
@export var attack_type: String = ""
@export_multiline var explanation: String = ""
@export_multiline var hint: String = ""

func get_full_query() -> String:
	return query_text.replace("{INPUT}", user_input)

func get_display_text() -> String:
	return "Input del usuario: \"%s\"" % user_input
