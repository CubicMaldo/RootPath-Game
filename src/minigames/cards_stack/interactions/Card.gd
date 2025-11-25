class_name Card
extends ButtonVisualEffects

signal put_back()
signal destroyed(card: Card)
signal answered(is_correct: bool, card_data: PhishingCard)

@export var color: Color:
	set(value):
		color = value
		%Card.self_modulate = value
	get:
		return color

@export var threshold: float = 100.0
@export var threshold_speed: float = 200.0
@export var use_speed: bool = true
@export var lock_put_back: bool = false

var picked_up: bool = false
var offset: Vector2 = Vector2.ZERO
var is_3D: bool = true
var is_active: bool = false
var last_speed: float = 0.0

# Phishing card data
var card_data: PhishingCard = null
var has_been_answered: bool = false # Prevenir respuestas múltiples

var tween_grab: Tween
var tween_movement: Tween
var tween_destroy: Tween

@onready var original_position: Vector2 = global_position
@onready var viewport_material: ShaderMaterial = $SubViewportContainer.material
@onready var card_sprite = $SubViewportContainer/SubViewport/Card
var dissolve_material: ShaderMaterial

# ============================================================
# LIFECYCLE
# ============================================================

func _ready() -> void:
	set_process(false)
	# Cada carta necesita su propia copia de materiales para evitar compartir parámetros
	_duplicate_card_materials()
	call_deferred("_update_pivot")

func _duplicate_card_materials() -> void:
	# Copiar material de dissolve asignado al botón (self)
	if material:
		dissolve_material = material.duplicate(true)
		dissolve_material.resource_local_to_scene = true
		dissolve_material.set_shader_parameter("dissolve_value", 1.0)
		material = dissolve_material
	if viewport_material:
		viewport_material = viewport_material.duplicate(true)
		viewport_material.resource_local_to_scene = true
		$SubViewportContainer.material = viewport_material
	$SubViewportContainer.use_parent_material = true

func _update_pivot() -> void:
	# Centrar el pivot para que la escala crezca desde el centro
	await get_tree().process_frame # Esperar un frame para que el tamaño esté disponible
	pivot_offset = size * 0.5

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	global_position = get_global_mouse_position() + offset

# ============================================================
# 3D ROTATION HANDLERS
# ============================================================

func set_3D_rotation_x(x: float) -> void:
	viewport_material.set_shader_parameter("x_rot", x)

func set_3D_rotation_y(y: float) -> void:
	viewport_material.set_shader_parameter("y_rot", y)

# ============================================================
# INPUT HANDLING
# ============================================================

func _on_button_down() -> void:
	if Engine.is_editor_hint():
		return
	
	offset = global_position - get_global_mouse_position()
	picked_up = true
	set_process(true)
	_kill_tween(tween_grab)
	
	tween_grab = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_grab.tween_property(self, "scale", Vector2.ONE * 1.1, 0.15)

func _on_button_up() -> void:
	if Engine.is_editor_hint():
		return
	
	picked_up = false
	set_process(false)
	_kill_tween(tween_movement)
	
	var dist: float = abs(original_position.y - global_position.y)
	var should_emit: bool = (use_speed and last_speed <= -threshold_speed) or (not use_speed and dist > threshold)
	
	# 👇 Si está bloqueada, no vuelve atrás ni emite señal
	if lock_put_back:
		_reset_scale()
		return
	
	if should_emit:
		put_back.emit()
	else:
		_reset_position()

func _on_gui_input(event: InputEvent) -> void:
	if picked_up and event is InputEventMouseMotion:
		last_speed = event.velocity.y

# ============================================================
# DESTRUCTION / DISSOLVE
# ============================================================

func destroy() -> void:
	# Prevenir múltiples llamadas y colisiones
	if lock_put_back:
		return
	lock_put_back = true
	disabled = true # Desactivar botón para evitar inputs
	set_process(false) # Detener procesamiento
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignorar eventos del mouse
	
	_kill_tween(tween_destroy)

	# Guardar y normalizar antes de animar para evitar parpadeos del stack
	var current_global_pos: Vector2 = global_position
	var normalize_tween := create_tween().set_parallel(true)
	normalize_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	normalize_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	normalize_tween.tween_property(self, "rotation", 0.0, 0.15)
	normalize_tween.tween_property(self, "modulate", Color(1, 1, 1, modulate.a), 0.15)
	normalize_tween.tween_property(self, "global_position", current_global_pos, 0.15)
	z_index = 200
	await normalize_tween.finished

	# Refrescar material y garantizar dissolve completo visible antes de animar
	var dissolve_target: ShaderMaterial = dissolve_material if dissolve_material else null
	if dissolve_target == null and material and material is ShaderMaterial:
		dissolve_target = material
	if dissolve_target:
		dissolve_target.set_shader_parameter("dissolve_value", 1.0)
	
	# Flash corto para enfatizar el error antes del shake
	var flash_tween := create_tween()
	flash_tween.tween_property(self, "modulate", Color(1.0, 0.75, 0.75, 1.0), 0.08).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.12).set_ease(Tween.EASE_IN)
	await flash_tween.finished

	# Desintegración: escala + rotación + dissolve + fade final en paralelo
	tween_destroy = create_tween().set_parallel(true)
	tween_destroy.tween_property(self, "scale", Vector2(0.85, 0.6), 0.7).set_delay(0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween_destroy.tween_property(self, "rotation_degrees", randf_range(-12.0, 12.0), 0.7).set_delay(0.05).set_ease(Tween.EASE_OUT)
	if dissolve_target:
		tween_destroy.tween_property(dissolve_target, "shader_parameter/dissolve_value", 0.0, 0.9).from(1.0).set_delay(0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tween_destroy.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.7)

	tween_destroy.finished.connect(func():
		destroyed.emit()
		queue_free()
	)

func save_card() -> void:
	## Animación de guardado: la carta se reduce y sale por la derecha
	# Prevenir múltiples llamadas y colisiones
	if lock_put_back:
		return
	lock_put_back = true
	disabled = true # Desactivar botón para evitar inputs
	set_process(false) # Detener procesamiento
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Ignorar eventos del mouse
	
	_kill_tween(tween_destroy)
	# Crear tween con múltiples propiedades
	tween_destroy = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween_destroy.set_parallel(true)
	
	# Mover hacia la derecha y arriba (como guardando en carpeta)
	var target_pos = global_position + Vector2(get_viewport_rect().size.x * 0.6, -50)
	tween_destroy.tween_property(self, "global_position", target_pos, 0.6)
	
	
	# Rotar un poco para efecto de "guardado"
	tween_destroy.tween_property(self, "rotation_degrees", 15, 0.3)
	
	# Desvanecer al final
	tween_destroy.set_parallel(false)
	tween_destroy.tween_property(self, "modulate:a", 0.0, 0.2)
	
	tween_destroy.finished.connect(func():
		destroyed.emit()
		queue_free()
	)

# ============================================================
# HELPERS
# ============================================================

func _kill_tween(tween: Tween) -> void:
	if tween and tween.is_running():
		if is_instance_valid(tween):
			tween.kill()

func _reset_position() -> void:
	_reset_scale()
	tween_movement = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_movement.tween_property(self, "global_position", original_position, 0.3)

func _reset_scale() -> void:
	_kill_tween(tween_grab)
	tween_grab = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_grab.tween_property(self, "scale", Vector2.ONE, 0.15)

# ============================================================
# PHISHING CARD DATA
# ============================================================

func setup_from_data(data: PhishingCard) -> void:
	"""Configura la carta con datos de PhishingCard"""
	if data == null:
		push_error("Card.setup_from_data: data is null")
		return
	
	card_data = data
	color = data.card_color
	
	# Aquí actualizas los elementos visuales de la carta
	# Asumiendo que tienes Labels/TextEdits en la escena
	_update_card_visuals()

func _update_card_visuals() -> void:
	"""Actualiza los elementos visuales con los datos de la carta"""
	if card_data == null:
		return
	
	# Buscar nodos en la carta para actualizar
	# Ajusta estos nombres según tu escena
	if has_node("%Title"):
		get_node("%Title").text = card_data.card_title
	
	if has_node("%Sender"):
		get_node("%Sender").text = "📱 %s" % card_data.app_name
		if has_node("%AppIdentifier") and not card_data.app_identifier.is_empty():
			get_node("%AppIdentifier").text = "(%s)" % card_data.app_identifier
	
	if has_node("%Subject"):
		get_node("%Subject").text = card_data.notification_title
	
	if has_node("%Body"):
		get_node("%Body").text = card_data.notification_message
	
	# Si tienes botones de acción
	if has_node("%AttachmentIcon"):
		get_node("%AttachmentIcon").visible = card_data.has_action_buttons

func get_card_data() -> PhishingCard:
	return card_data

func is_phishing() -> bool:
	return card_data.is_phishing if card_data else false

func was_answered() -> bool:
	return has_been_answered

func check_answer(player_thinks_phishing: bool) -> bool:
	"""Verifica si la respuesta del jugador es correcta"""
	# Prevenir respuestas múltiples
	if has_been_answered:
		push_warning("Card: check_answer() ya fue llamado para esta carta")
		return false
	
	if card_data == null:
		return false
	
	has_been_answered = true
	var is_correct = player_thinks_phishing == card_data.is_phishing
	answered.emit(is_correct, card_data)
	return is_correct
