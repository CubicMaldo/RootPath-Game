extends Node2D

## Visual effect that draws a growing and fading tree structure
## Used as background animation for the main menu

@export var tree_depth: int = 5
@export var branch_length: float = 80.0
@export var branch_angle: float = 30.0
@export var length_reduction: float = 0.7
@export var draw_speed: float = 2.0
@export var fade_delay: float = 2.0
@export var fade_speed: float = 1.5

var lines: Array[Line2D] = []
var line_segments: Array[Dictionary] = []
var current_progress: float = 0.0
var is_drawing: bool = true
var fade_timer: float = 0.0

func _ready() -> void:
	_generate_tree_structure()
	_create_line_nodes()

func _process(delta: float) -> void:
	if is_drawing:
		_update_drawing(delta)
	else:
		_update_fading(delta)

func _generate_tree_structure() -> void:
	line_segments.clear()
	var root_pos := Vector2.ZERO
	var root_end := Vector2(0, -branch_length)
	_generate_branches(root_pos, root_end, branch_length, 0)

func _generate_branches(start: Vector2, end: Vector2, length: float, depth: int) -> void:
	if depth >= tree_depth:
		return
	
	# Add current branch segment
	line_segments.append({
		"start": start,
		"end": end,
		"depth": depth
	})
	
	# Calculate child branches
	var direction := (end - start).normalized()
	var new_length := length * length_reduction
	
	# Left branch
	var left_angle := deg_to_rad(branch_angle)
	var left_dir := direction.rotated(-left_angle)
	var left_end := end + left_dir * new_length
	_generate_branches(end, left_end, new_length, depth + 1)
	
	# Right branch
	var right_angle := deg_to_rad(branch_angle)
	var right_dir := direction.rotated(right_angle)
	var right_end := end + right_dir * new_length
	_generate_branches(end, right_end, new_length, depth + 1)

func _create_line_nodes() -> void:
	for segment in line_segments:
		var line := Line2D.new()
		line.width = 3.0 - (segment.depth * 0.3)
		line.default_color = Color(0.8, 0.9, 1.0, 0.6)
		line.antialiased = true
		add_child(line)
		lines.append(line)

func _update_drawing(delta: float) -> void:
	current_progress += delta * draw_speed
	
	var total_segments := line_segments.size()
	var segments_to_draw := int(current_progress * total_segments)
	
	for i in range(min(segments_to_draw, total_segments)):
		var segment = line_segments[i]
		var line = lines[i]
		
		if line.get_point_count() == 0:
			line.add_point(segment.start)
			line.add_point(segment.start)
		
		# Animate the end point growing
		var progress_within_segment := (current_progress * total_segments) - i
		progress_within_segment = clamp(progress_within_segment, 0.0, 1.0)
		
		var current_end: Vector2 = segment.start.lerp(segment.end, progress_within_segment)
		line.set_point_position(1, current_end)
	
	# Check if drawing is complete
	if current_progress >= 1.0:
		is_drawing = false
		fade_timer = 0.0

func _update_fading(delta: float) -> void:
	fade_timer += delta
	
	if fade_timer < fade_delay:
		return
	
	var fade_progress := (fade_timer - fade_delay) * fade_speed
	
	for line in lines:
		var color := line.default_color
		color.a = max(0.0, 0.6 - fade_progress)
		line.default_color = color
	
	# Reset when fully faded
	if fade_progress >= 0.6:
		_reset_animation()

func _reset_animation() -> void:
	current_progress = 0.0
	is_drawing = true
	fade_timer = 0.0
	
	for line in lines:
		line.clear_points()
		line.default_color = Color(0.8, 0.9, 1.0, 0.6)
