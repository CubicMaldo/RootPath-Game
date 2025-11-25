extends Control

@export var max_offset: Vector2
@export var smoothing: float = 2.0

@export var parallax : Node
func _process(delta):
	# Ensure parallax node exists
	if parallax == null:
		return

	# Get mouse position relative to this Control to avoid multi-monitor/global bias
	var local_mouse: Vector2 = get_local_mouse_position()

	# Map mouse position into an offset in range [-1, 1], centered on the control
	
	# Protect against zero-size controls
	if size.x == 0 or size.y == 0:
		return

	var center: Vector2 = size / 2.0
	var dist: Vector2 = local_mouse - center

	var offset: Vector2 = Vector2()
	offset.x = clamp(dist.x / center.x, -1.0, 1.0)
	offset.y = clamp(dist.y / center.y, -1.0, 1.0)

	# Invert offset so movement feels natural (mouse right -> parallax left)
	var new_pos: Vector2 = -offset * max_offset

	# Smoothly interpolate the parallax position using a safe vector lerp
	var t: float = clamp(smoothing * delta, 0.0, 1.0)
	parallax.position = parallax.position.lerp(new_pos, t)
