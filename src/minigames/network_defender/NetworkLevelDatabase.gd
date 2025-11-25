extends Resource
class_name NetworkLevelDatabase

## Base de datos de niveles para el minijuego Network Defender

@export var easy_levels: Array[ConnectionResource] = []
@export var medium_levels: Array[ConnectionResource] = []
@export var hard_levels: Array[ConnectionResource] = []

func get_all_levels() -> Array[ConnectionResource]:
	var all_levels: Array[ConnectionResource] = []
	all_levels.append_array(easy_levels)
	all_levels.append_array(medium_levels)
	all_levels.append_array(hard_levels)
	return all_levels

func get_level_by_difficulty(difficulty: String) -> Array[ConnectionResource]:
	match difficulty.to_lower():
		"easy", "fácil":
			return easy_levels
		"medium", "medio", "media":
			return medium_levels
		"hard", "difícil":
			return hard_levels
		_:
			return []
