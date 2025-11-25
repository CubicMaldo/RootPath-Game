extends Resource
class_name SQLQueryDatabase

## Base de datos de consultas SQL para el minijuego SQL Injection Defender

@export var queries: Array[SQLQueryResource] = []

func get_all_queries() -> Array[SQLQueryResource]:
	return queries

func get_query_count() -> int:
	return queries.size()
