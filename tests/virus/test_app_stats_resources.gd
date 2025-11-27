extends GutTest

const RESOURCES_DIR := "res://src/virus/resources"

func test_app_stats_from_definitions_instantiate() -> void:
	var definitions := _load_definitions_with_app_stats()
	assert_gt(definitions.size(), 0, "At least one virus definition should provide AppStats")
	for definition in definitions:
		var app_stats: AppStats = definition.app_stats
		assert_not_null(app_stats, "Definition %s must expose AppStats" % definition.identifier)
		assert_not_null(app_stats.scene, "%s AppStats must define a scene" % definition.identifier)
		assert_true(app_stats.scene is PackedScene, "%s scene needs to be a PackedScene" % definition.identifier)
		var instance := app_stats.scene.instantiate()
		assert_true(instance is Node, "%s scene should instantiate into a Node" % definition.identifier)
		instance.queue_free()

func _load_definitions_with_app_stats() -> Array[VirusDefinition]:
	var gathered: Array[VirusDefinition] = []
	var dir := DirAccess.open(RESOURCES_DIR)
	assert_not_null(dir, "Virus resources directory must exist")
	if dir == null:
		return gathered
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.to_lower().ends_with(".tres"):
			var path := "%s/%s" % [RESOURCES_DIR, entry]
			var resource := ResourceLoader.load(path)
			if resource is VirusDefinition and resource.app_stats is AppStats:
				gathered.append(resource)
		entry = dir.get_next()
	dir.list_dir_end()
	return gathered
