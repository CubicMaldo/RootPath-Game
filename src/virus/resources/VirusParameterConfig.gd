extends Resource

class_name VirusParameterConfig

## Defines how a numeric parameter scales with the global virus difficulty level.

enum ScalingMode { CONSTANT, ADDITIVE, MULTIPLICATIVE }

@export var property_name: StringName
@export var scaling_mode: ScalingMode = ScalingMode.ADDITIVE
@export var base_value: float = 0.0
@export var per_level_delta: float = 0.0
@export var per_level_multiplier: float = 1.0
@export var min_value: float = -INF
@export var max_value: float = INF

@export var apply_as_integer: bool = false

func compute_value(difficulty_level: int, fallback_value) -> Variant:
	var level_offset: int = max(0, difficulty_level - 1)
	var starting_value: Variant = base_value if property_name != StringName() else fallback_value
	var result: float = float(starting_value)
	if scaling_mode == ScalingMode.CONSTANT:
		result = float(base_value)
	elif scaling_mode == ScalingMode.ADDITIVE:
		result = float(base_value) + per_level_delta * level_offset
	elif scaling_mode == ScalingMode.MULTIPLICATIVE:
		var multiplier := pow(per_level_multiplier, level_offset)
		result = float(base_value) * multiplier
	result = clamp(result, min_value, max_value)
	if apply_as_integer:
		result = int(round(result))
	return result
