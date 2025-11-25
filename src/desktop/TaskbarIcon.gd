extends AppButton

func _ready():
	
	super._ready()
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pivot_offset = Vector2(32, 32)
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -32.0
	offset_top = -32.0
	offset_right = 32.0
	offset_bottom = 32.0
	
	self.position = Vector2.ZERO

func _clicked_twice() -> void:
	pass
