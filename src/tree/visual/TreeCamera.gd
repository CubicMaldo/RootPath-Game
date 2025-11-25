# TreeCamera.gd
class_name TreeCamera
extends Control

# Configuración
var zoom_min: float = 0.1
var zoom_max: float = 2
var zoom_step: float = 0.05
var zoom_smooth_speed: float = 10.0
var pan_with_right_click: bool = true

# Estado de la cámara
var drag_active: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var camera_offset: Vector2 = Vector2.ZERO
var zoom_factor: float = 1.0
var target_zoom: float = 1.0

# Referencias
var parent: Control = null
var nodos_container: Control = null
var lineas_node: Node2D = null

# ========== CONFIGURACIÓN ==========

func setup(parent_node: Control, nodes_container: Control, lines_node: Node2D) -> void:
	parent = parent_node
	nodos_container = nodes_container
	lineas_node = lines_node

func update_settings(new_zoom_min: float, new_zoom_max: float, 
					new_zoom_step: float, new_smooth_speed: float,
					use_right_click_pan: bool) -> void:
	zoom_min = new_zoom_min
	zoom_max = new_zoom_max
	zoom_step = new_zoom_step
	zoom_smooth_speed = new_smooth_speed
	pan_with_right_click = use_right_click_pan

func handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and drag_active:
		_handle_mouse_drag(event)

func process_camera(delta: float) -> void:
	if abs(target_zoom - zoom_factor) > 0.001:
		_apply_smooth_zoom(delta)

func set_target_zoom(new_zoom: float) -> void:
	target_zoom = clamp(new_zoom, zoom_min, zoom_max)

func get_current_zoom() -> float:
	return zoom_factor

func center_on_position(_position: Vector2, duration: float = 0.5) -> void:
	if nodos_container == null or lineas_node == null:
		push_warning("Containers not set in TreeCamera")
		return
	
	var tween = _create_tween()
	if tween:
		tween.tween_property(nodos_container, "position", _position, duration)
		tween.tween_property(lineas_node, "position", _position, duration)

func fit_to_bounds(bounds: Rect2, viewport_size: Vector2) -> void:
	if bounds.size == Vector2.ZERO:
		return
	
	var scale_x = viewport_size.x / bounds.size.x * 0.8
	var scale_y = viewport_size.y / bounds.size.y * 0.8
	var new_zoom = min(scale_x, scale_y)
	
	set_target_zoom(new_zoom)
	
	var bounds_center = bounds.get_center()
	var viewport_center = viewport_size / 2.0
	var offset = viewport_center - bounds_center * new_zoom
	
	center_on_position(offset, 0.5)

func reset_view(duration: float = 0.5) -> void:
	if nodos_container == null or lineas_node == null:
		push_warning("Containers not set in TreeCamera")
		return
	
	target_zoom = 1.0
	
	var tween = _create_tween()
	if tween:
		var target_position = parent.size / 2.0 - Vector2(parent.size.x / 2.0, 0)
		
		tween.tween_property(nodos_container, "position", target_position, duration)
		tween.tween_property(lineas_node, "position", target_position, duration)
		tween.tween_property(nodos_container, "scale", Vector2.ONE, duration)
		tween.tween_property(lineas_node, "scale", Vector2.ONE, duration)
	
	# Resetear estado interno
	zoom_factor = 1.0
	camera_offset = Vector2.ZERO

func reset_containers() -> void:
	if nodos_container:
		nodos_container.position = Vector2.ZERO
		nodos_container.scale = Vector2.ONE
	
	if lineas_node:
		lineas_node.position = Vector2.ZERO
		lineas_node.scale = Vector2.ONE

# ========== FUNCIONES INTERNAS ==========

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(1)
		MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-1)
		MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				reset_view()
		_:
			_handle_drag_buttons(event)

func _handle_drag_buttons(event: InputEventMouseButton) -> void:
	var button_index = event.button_index
	
	if button_index == MOUSE_BUTTON_RIGHT and not pan_with_right_click:
		return
	
	if event.pressed:
		drag_active = true
		last_mouse_pos = event.position
	else:
		drag_active = false

func _handle_mouse_drag(event: InputEventMouseMotion) -> void:
	if not drag_active:
		return
	
	var delta = event.position - last_mouse_pos
	last_mouse_pos = event.position
	
	_apply_pan(delta)

func _apply_pan(delta: Vector2) -> void:
	camera_offset += delta
	
	if nodos_container:
		nodos_container.position += delta
	
	if lineas_node:
		lineas_node.position += delta

func _change_zoom(direction: int) -> void:
	var new_zoom = target_zoom + direction * zoom_step
	target_zoom = clamp(new_zoom, zoom_min, zoom_max)

func _apply_smooth_zoom(delta: float) -> void:
	var old_zoom = zoom_factor
	zoom_factor = lerp(zoom_factor, target_zoom, zoom_smooth_speed * delta)
	
	if abs(target_zoom - zoom_factor) < 0.001:
		zoom_factor = target_zoom
	
	_apply_zoom_transform(old_zoom)

func _apply_zoom_transform(old_zoom: float) -> void:
	if nodos_container == null or lineas_node == null:
		return
	
	var zoom_ratio = zoom_factor / old_zoom
	var viewport_center = parent.size / 2.0
	var offset_before = nodos_container.position - viewport_center
	
	# Aplicar zoom
	nodos_container.scale = Vector2.ONE * zoom_factor
	lineas_node.scale = Vector2.ONE * zoom_factor
	
	# Ajustar posición para zoom hacia el centro
	var offset_after = offset_before * zoom_ratio
	nodos_container.position = viewport_center + offset_after
	lineas_node.position = nodos_container.position

func _create_tween() -> Tween:
	if parent and parent.is_inside_tree():
		return parent.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		push_warning("Parent not valid for creating tween")
		return null
