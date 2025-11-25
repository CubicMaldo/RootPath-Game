extends Resource
class_name PasswordLevelDatabase

@export var easy_levels: Array[PasswordLevelResource] = []
@export var medium_levels: Array[PasswordLevelResource] = []
@export var hard_levels: Array[PasswordLevelResource] = []

func get_all_levels() -> Array[PasswordLevelResource]:
	var ordered: Array[PasswordLevelResource] = []
	ordered.append_array(easy_levels)
	ordered.append_array(medium_levels)
	ordered.append_array(hard_levels)
	return ordered
