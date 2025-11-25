extends Resource
class_name PasswordStrengthTip

## Recurso que representa un consejo sobre contraseñas seguras

@export var tip_title: String = ""
@export_multiline var tip_description: String = ""
@export var tip_category: String = ""  # "longitud", "complejidad", "diversidad", "evitar"
@export var example_bad: String = ""
@export var example_good: String = ""
@export var priority: int = 1  # 1=crítico, 2=importante, 3=recomendado
