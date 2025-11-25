extends Button
class_name ButtonVisualEffects

## Clase genérica para efectos visuales en botones de Godot
## Incluye efectos de rotación 3D, hover y sombra dinámica

@export_group("Rotation Settings")
@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var enable_rotation_effect: bool = true

@export_group("Shadow Settings")
@export var max_offset_shadow: float = 8.0
@export var enable_shadow_effect: bool = true

@export_group("Hover Settings")
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var enable_hover_scale: bool = true

@export_group("Node References")
@export var texture_node: Control
@export var shadow_node: Control

var tween_rot: Tween
var tween_hover: Tween

func _ready() -> void:
	# Convertir a radianes para usar con lerp_angle
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	

func _process(_delta: float) -> void:
	if enable_shadow_effect and shadow_node:
		_handle_shadow()

func _handle_shadow() -> void:
	# La sombra se desplaza en X según la distancia al centro de la pantalla
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	
	shadow_node.position.x = lerp(0.0, -sign(distance) * max_offset_shadow, abs(distance / center.x))

func _on_gui_input(event: InputEvent) -> void:
	if not enable_rotation_effect or not texture_node: return
	if not event is InputEventMouseMotion: return
	
	# Obtener posición local del mouse
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	# Calcular valores de interpolación
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0.0, 1.0)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0.0, 1.0)
	
	# Calcular rotaciones
	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y))
	
	# Aplicar rotaciones al shader
	if texture_node.material:
		texture_node.material.set_shader_parameter("x_rot", rot_y)
		texture_node.material.set_shader_parameter("y_rot", rot_x)

func _on_mouse_entered() -> void:
	if not enable_hover_scale: return
	
	# Escalar al hacer hover
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", hover_scale, 0.55)

func _on_mouse_exited() -> void:
	# Resetear rotación
	if enable_rotation_effect and texture_node and texture_node.material:
		if tween_rot and tween_rot.is_running():
			tween_rot.kill()
		tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
		tween_rot.tween_property(texture_node.material, "shader_parameter/x_rot", 0.0, 0.5)
		tween_rot.tween_property(texture_node.material, "shader_parameter/y_rot", 0.0, 0.5)
	
	# Resetear escala
	if enable_hover_scale:
		if tween_hover and tween_hover.is_running():
			tween_hover.kill()
		tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween_hover.tween_property(self, "scale", Vector2.ONE, 0.55)

## Método opcional para aplicar efecto de disolución
func apply_dissolve_effect(duration: float = 2.0) -> void:
	if not texture_node: return
	
	texture_node.use_parent_material = true
	var tween_dissolve = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_dissolve.tween_property(material, "shader_parameter/dissolve_value", 0.0, duration).from(1.0)
	
	if shadow_node:
		tween_dissolve.parallel().tween_property(shadow_node, "self_modulate:a", 0.0, duration * 0.5)

## Método para animar escala (útil para feedback de clicks)
func animate_scale(target_scale: Vector2, duration: float = 0.5) -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", target_scale, duration)
