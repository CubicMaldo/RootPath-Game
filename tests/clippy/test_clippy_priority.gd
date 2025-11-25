extends GutTest

var controller: ClippyController
var resources: ClippyResources

func before_each():
	controller = ClippyController.new()
	add_child_autofree(controller)
	
	# Mock resources to avoid file system dependency
	resources = ClippyResources.new()
	controller._resources = resources
	controller.add_child(resources)

func test_priority_sorting():
	# Create events with different priorities
	var low_event = ClippyEvent.new()
	low_event.event_type = ClippyEvent.EventType.TREE_NODE_ENTERED
	low_event.context_id = "low"
	low_event.priority = ClippyEvent.Priority.LOW
	
	var high_event = ClippyEvent.new()
	high_event.event_type = ClippyEvent.EventType.MINI_GAME_START
	high_event.context_id = "high"
	high_event.priority = ClippyEvent.Priority.HIGH
	high_event.payload = {"game_type": "test"}
	
	var normal_event = ClippyEvent.new()
	normal_event.event_type = ClippyEvent.EventType.TUTORIAL_START
	normal_event.context_id = "normal"
	normal_event.priority = ClippyEvent.Priority.NORMAL
	
	# Add in random order
	controller._event_queue.append(low_event)
	controller._event_queue.append(high_event)
	controller._event_queue.append(normal_event)
	
	# Sort
	controller._sort_queue()
	
	# Verify order: HIGH, NORMAL, LOW
	assert_eq(controller._event_queue[0], high_event, "High priority should be first")
	assert_eq(controller._event_queue[1], normal_event, "Normal priority should be second")
	assert_eq(controller._event_queue[2], low_event, "Low priority should be last")

func test_expiration():
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TREE_NODE_ENTERED
	event.context_id = "expired"
	event.expiration_time = 0.1 # Short expiration
	event.timestamp = (Time.get_ticks_msec() / 1000.0) - 1.0 # Created 1 second ago
	
	controller._event_queue.append(event)
	
	controller._remove_expired_events()
	
	assert_true(controller._event_queue.is_empty(), "Expired event should be removed")

func test_no_expiration():
	var event = ClippyEvent.new()
	event.event_type = ClippyEvent.EventType.TREE_NODE_ENTERED
	event.context_id = "valid"
	event.expiration_time = 10.0 # Long expiration
	event.timestamp = Time.get_ticks_msec() / 1000.0
	
	controller._event_queue.append(event)
	
	controller._remove_expired_events()
	
	assert_false(controller._event_queue.is_empty(), "Valid event should not be removed")
