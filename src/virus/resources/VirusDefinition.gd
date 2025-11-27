extends Resource

class_name VirusDefinition


enum VirusCategory { FULLSCREEN, APP }

@export var identifier: StringName
@export var display_name: String = ""
@export var category: VirusCategory = VirusCategory.FULLSCREEN
@export var virus_scene: PackedScene
@export var app_stats: AppStats
@export var spawn_weight: float = 1.0
@export var min_failures: int = 0
@export var max_failures: int = 0 ## 0 = sin límite superior
@export var base_time_limit: float = 0.0
@export var alert_message: String = ""
@export var clippy_hint: String = ""
@export var monitor_spike: float = 12.0
@export var accent_color: Color = Color(0.94, 0.35, 0.2, 1.0)
@export var parameter_configs: Array[VirusParameterConfig] = []

func matches_failure_window(current_failures: int) -> bool:
	if current_failures < min_failures:
		return false
	if max_failures > 0 and current_failures > max_failures:
		return false
	return true

func get_category_name() -> String:
	return "app" if category == VirusCategory.APP else "fullscreen"

func get_parameter_value(param_name: String, difficulty_level: int, fallback_value) -> Variant:
	for config in parameter_configs:
		if config.property_name == StringName(param_name):
			return config.compute_value(difficulty_level, fallback_value)
	return fallback_value

func get_all_parameters(difficulty_level: int) -> Dictionary:
	var result: Dictionary = {}
	for config in parameter_configs:
		if config.property_name == StringName():
			continue
		result[str(config.property_name)] = config.compute_value(difficulty_level, result.get(str(config.property_name), 0))
	return result
