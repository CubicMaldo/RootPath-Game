extends GutTest

const VirusControllerScript := preload("res://src/autoloads/VirusController.gd")
const VirusDefinitionResource := preload("res://src/virus/resources/VirusDefinition.gd")

class MockSystemMonitor:
	extends Node
	var start_calls := 0
	var end_calls := 0
	var spikes: Array = []
	func register_virus_start() -> void:
		start_calls += 1
	func register_virus_end() -> void:
		end_calls += 1
	func add_spike(amount: float) -> void:
		spikes.append(amount)

class DummyVirus:
	extends BaseVirus
	var started := false
	func start_infection() -> void:
		started = true

var _monitor: MockSystemMonitor
var _cleanup_nodes: Array = []

func before_each() -> void:
	_cleanup_nodes.clear()
	_install_mock_system_monitor()

func after_each() -> void:
	for node in _cleanup_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_cleanup_nodes.clear()

func test_trigger_infection_uses_requested_definition() -> void:
	var controller := _build_controller("unit_full")
	await _wait_for_initialization()
	controller.trigger_infection("unit_full")
	await _wait_until(func(): return controller.is_infected)
	assert_eq(str(controller.current_definition.identifier), "unit_full", "Controller should keep requested definition active")
	assert_true(controller.overlay_instance.visible, "Overlay must be visible during infection")

func test_failed_infection_updates_state_and_monitor() -> void:
	var controller := _build_controller("unit_fail")
	await _wait_for_initialization()
	controller.trigger_infection("unit_fail")
	await _wait_until(func(): return controller.is_infected)
	var virus := await _get_active_virus(controller)
	virus._on_virus_failed()
	await _wait_until(func(): return not controller.is_infected)
	assert_eq(controller.failed_virus_count, 1, "Failure counter should increment after virus_failed")
	assert_eq(_monitor.start_calls, 1, "SystemMonitor must be notified on start")
	assert_eq(_monitor.end_calls, 1, "SystemMonitor must be notified on end")
	assert_gt(_monitor.spikes.size(), 0, "Monitor spike should be recorded")

func test_success_resets_overlay_and_state() -> void:
	var controller := _build_controller("unit_clear")
	await _wait_for_initialization()
	controller.trigger_infection("unit_clear")
	await _wait_until(func(): return controller.is_infected)
	var virus := await _get_active_virus(controller)
	virus._on_virus_cleared()
	await _wait_until(func(): return not controller.is_infected)
	assert_false(controller.overlay_instance.visible, "Overlay should hide after cleaning")
	assert_eq(_monitor.end_calls, 1, "SystemMonitor end should run once on success")

func _build_controller(identifier: String) -> VirusController:
	var controller: VirusController = VirusControllerScript.new()
	controller.fullscreen_definitions = [_make_definition(identifier)]
	controller.app_definitions = []
	add_child_autofree(controller)
	return controller

func _make_definition(identifier: String) -> VirusDefinition:
	var scene := PackedScene.new()
	var root := DummyVirus.new()
	root.name = identifier
	var pack_result := scene.pack(root)
	assert_eq(pack_result, OK, "Dummy virus scene should pack correctly")
	var definition: VirusDefinition = VirusDefinitionResource.new()
	definition.identifier = identifier
	definition.display_name = identifier.capitalize()
	definition.category = VirusDefinition.VirusCategory.FULLSCREEN
	definition.virus_scene = scene
	definition.alert_message = "Unit Test"
	definition.monitor_spike = 5.0
	definition.clippy_hint = "Mantén la calma"
	return definition

func _install_mock_system_monitor() -> void:
	var root := get_tree().root
	var existing := root.get_node_or_null("SystemMonitor")
	if existing:
		existing.queue_free()
	_monitor = MockSystemMonitor.new()
	_monitor.name = "SystemMonitor"
	root.add_child(_monitor)
	_cleanup_nodes.append(_monitor)

func _wait_for_initialization() -> void:
	await get_tree().create_timer(0.65).timeout

func _get_active_virus(controller: VirusController) -> BaseVirus:
	assert_not_null(controller.overlay_instance, "Overlay instance should exist")
	await _wait_until(func(): return controller.overlay_instance.container.get_child_count() > 0)
	return controller.overlay_instance.container.get_child(0)

func _wait_until(predicate: Callable, timeout: float = 2.0) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if predicate.call():
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return false
