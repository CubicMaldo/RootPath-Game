extends CanvasLayer

class_name VirusOverlay

const DEFAULT_TITLE := "ALERTA DE VIRUS"
const DEFAULT_SUBTITLE := "Se ha detectado actividad sospechosa."

@onready var container: Control = $VirusContainer
@onready var background: ColorRect = $Background
@onready var header: VBoxContainer = $Header
@onready var accent_bar: ColorRect = $Header/AccentBar
@onready var title_label: Label = $Header/TitleLabel
@onready var subtitle_label: Label = $Header/SubtitleLabel

var _background_target_color: Color
var _header_target_modulate: Color
var _container_target_modulate: Color
var _active_tween: Tween

func _ready():
	visible = false
	_background_target_color = background.color
	_header_target_modulate = header.modulate
	_container_target_modulate = container.modulate

func show_overlay(title: String = DEFAULT_TITLE, subtitle: String = DEFAULT_SUBTITLE, accent_color: Color = Color(0.94, 0.35, 0.2, 1)) -> void:
	_clear_container()
	_update_header(title, subtitle, accent_color)
	visible = true
	background.color = Color(_background_target_color.r, _background_target_color.g, _background_target_color.b, 0.0)
	header.modulate = Color(_header_target_modulate.r, _header_target_modulate.g, _header_target_modulate.b, 0.0)
	container.modulate = Color(_container_target_modulate.r, _container_target_modulate.g, _container_target_modulate.b, 0.0)
	_start_tween(
		background, "color", _background_target_color,
		header, container
	)

func hide_overlay() -> void:
	if not visible:
		_clear_container()
		return
	var target_color := Color(_background_target_color.r, _background_target_color.g, _background_target_color.b, 0.0)
	var hidden_modulate := Color(_header_target_modulate.r, _header_target_modulate.g, _header_target_modulate.b, 0.0)
	_stop_tween()
	_active_tween = create_tween()
	_active_tween.tween_property(background, "color", target_color, 0.2)
	_active_tween.parallel().tween_property(header, "modulate", hidden_modulate, 0.18)
	_active_tween.parallel().tween_property(container, "modulate", hidden_modulate, 0.18)
	_active_tween.finished.connect(_on_hide_animation_finished)

func add_virus(virus_scene: PackedScene) -> BaseVirus:
	var virus_instance = virus_scene.instantiate()
	if not virus_instance is BaseVirus:
		push_error("VirusOverlay: La escena instanciada no hereda de BaseVirus")
		return null
	
	container.add_child(virus_instance)
	virus_instance.hide_buttons()
	return virus_instance

func _update_header(title: String, subtitle: String, accent_color: Color) -> void:
	var parsed_title := title.strip_edges()
	var parsed_subtitle := subtitle.strip_edges()
	var final_title := parsed_title if parsed_title != "" else DEFAULT_TITLE
	var final_subtitle := parsed_subtitle if parsed_subtitle != "" else DEFAULT_SUBTITLE
	title_label.text = final_title
	subtitle_label.text = final_subtitle
	subtitle_label.visible = final_subtitle != ""
	accent_bar.color = accent_color

func _start_tween(bg_node: ColorRect, property_name: String, target_color: Color, header_node: Control, content_node: Control) -> void:
	_stop_tween()
	_active_tween = create_tween()
	_active_tween.tween_property(bg_node, property_name, target_color, 0.25)
	_active_tween.parallel().tween_property(header_node, "modulate", _header_target_modulate, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(content_node, "modulate", _container_target_modulate, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.finished.connect(func():
		_active_tween = null
	)

func _on_hide_animation_finished() -> void:
	_stop_tween()
	_clear_container()
	visible = false
	background.color = _background_target_color
	header.modulate = _header_target_modulate
	container.modulate = _container_target_modulate

func _clear_container() -> void:
	for child in container.get_children():
		child.queue_free()

func _stop_tween() -> void:
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()
	_active_tween = null
