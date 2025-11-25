extends ButtonVisualEffects
class_name AppButton

## Botón de aplicación con drag & drop y sistema de doble click
## Hereda todos los efectos visuales de ButtonVisualEffects

@export_category("Oscillator")
@export var spring: float = 150.0
@export var damp: float = 10.0
@export var velocity_multiplier: float = 2.0

@export_category("Drag Settings")
@export var drag_threshold: float = 20.0
@export var enable_drag: bool = true:
	set(value):
		enable_drag = value
		if not enable_drag:
			_reset_drag_state()
	get:
		return enable_drag

@export_category("App Settings")
@export var appStats : AppStats

signal open_app(app_ref: PackedScene,app_stats : AppStats)

var displacement: float = 0.0 
var oscillator_velocity: float = 0.0
var tween_handle: Tween

var following_mouse: bool = false
var last_pos: Vector2
var velocity: Vector2

# Variables para el threshold del drag
var mouse_pressed: bool = false
var press_position: Vector2
var drag_started: bool = false

var clicked_times_on_focus: int = 0

@onready var collision_shape = $DestroyArea/CollisionShape2D

func _ready() -> void:
	super._ready()
	if appStats != null:
		$AppTexture.texture = appStats.icon
	
	collision_shape.set_deferred("disabled", true)
	
	# Conectar señales adicionales
	pressed.connect(_on_button_pressed)
	focus_exited.connect(_on_button_focus_exited)

func _process(_delta: float) -> void:
	super._process(_delta)
	if enable_drag:
		_rotate_velocity(_delta)
		_follow_mouse(_delta)
		_check_drag_threshold()

func _check_drag_threshold() -> void:
	if not enable_drag:
		return
	if mouse_pressed and not drag_started:
		var current_mouse_pos = get_global_mouse_position()
		var distance = press_position.distance_to(current_mouse_pos)
		
		if distance >= drag_threshold:
			drag_started = true
			following_mouse = true
			last_pos = position

func _rotate_velocity(_delta: float) -> void:
	if not following_mouse: return
	
	# Calcular velocidad
	velocity = (position - last_pos) / _delta
	last_pos = position
	
	oscillator_velocity += velocity.normalized().x * velocity_multiplier
	
	# Oscilador
	var force = -spring * displacement - damp * oscillator_velocity
	oscillator_velocity += force * _delta
	displacement += oscillator_velocity * _delta
	
	rotation = displacement

func _follow_mouse(_delta: float) -> void:
	if not enable_drag:
		return
	if not following_mouse: return
	var mouse_pos: Vector2 = get_global_mouse_position()
	global_position = mouse_pos - (size / 2.0)

func _on_gui_input(event: InputEvent) -> void:
	super._on_gui_input(event)
	_handle_mouse_click(event)

func _handle_mouse_click(event: InputEvent) -> void:
	if not enable_drag:
		return
	if not event is InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	
	if event.is_pressed():
		mouse_pressed = true
		press_position = get_global_mouse_position()
		drag_started = false
	else:
		mouse_pressed = false
		
		if drag_started:
			_drop_card()

func _drop_card() -> void:
	following_mouse = false
	drag_started = false
	collision_shape.set_deferred("disabled", false)
	
	if tween_handle and tween_handle.is_running():
		tween_handle.kill()
	tween_handle = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_handle.tween_property(self, "rotation", 0.0, 0.3)

func _on_button_pressed() -> void:
	clicked_times_on_focus += 1
	if clicked_times_on_focus < 2:
		return
	_clicked_twice()
	clicked_times_on_focus = 0

func _on_button_focus_exited() -> void:
	_reset_drag_state()
	clicked_times_on_focus = 0

func _clicked_twice() -> void:
	open_app.emit(appStats.scene,appStats)	
	animate_scale(Vector2(1.2, 1.2), 0.5)

## Método heredado y personalizado para destruir el botón
func destroy() -> void:
	apply_dissolve_effect(2.0)

func _reset_drag_state() -> void:
	following_mouse = false
	drag_started = false
	mouse_pressed = false
	if not is_inside_tree():
		return
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
