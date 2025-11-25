class_name ResourceService
extends RefCounted

## Servicio para carga y gestión de recursos del juego
## Centraliza la lógica de carga con caché y manejo de errores

const APP_DATABASE_PATH := "res://src/desktop/resources/TreeAppsDatabase.tres"
const APPS_DIR_PATH := "res://src/desktop/resources"

var _cache: Dictionary = {}
var _app_database: AppDatabase = null

func _init():
	print("[ResourceService] Inicializado")

## Carga la base de datos de aplicaciones
func load_app_database() -> AppDatabase:
	if _app_database != null:
		#print("[ResourceService] Usando AppDatabase cacheada")
		return _app_database
	
	if _cache.has("database"):
		#print("[ResourceService] AppDatabase encontrada en caché")
		_app_database = _cache["database"]
		return _app_database
	
	var resource := ResourceLoader.load(APP_DATABASE_PATH)
	if resource is AppDatabase:
		#print("[ResourceService] AppDatabase cargada correctamente desde %s" % APP_DATABASE_PATH)
		_app_database = resource
		_cache["database"] = resource
		EventBus.app_database_ready.emit(resource)
		return resource
	
	if resource != null:
		push_error("[ResourceService] El recurso en %s no es AppDatabase" % APP_DATABASE_PATH)
	else:
		push_error("[ResourceService] No se pudo cargar AppDatabase desde %s" % APP_DATABASE_PATH)
	
	EventBus.resources_loaded.emit(false)
	return null

## Carga recursos de aplicaciones por defecto desde el directorio
func load_default_app_resources() -> Array[AppStats]:
	if _cache.has("app_resources"):
		print("[ResourceService] Usando app_resources cacheados")
		return _cache["app_resources"]
	
	var results: Array[AppStats] = []
	var dir := DirAccess.open(APPS_DIR_PATH)
	
	if dir == null:
		push_error("[ResourceService] No se pudo abrir directorio %s" % APPS_DIR_PATH)
		EventBus.resources_loaded.emit(false)
		return results
	
	var files: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	
	while entry != "":
		if not entry.begins_with(".") and not dir.current_is_dir() and entry.to_lower().ends_with(".tres"):
			files.append(entry)
		entry = dir.get_next()
	
	dir.list_dir_end()
	files.sort()
	
	print("[ResourceService] Encontrados %d archivos .tres en %s" % [files.size(), APPS_DIR_PATH])
	
	for file_name in files:
		var full_path := "%s/%s" % [APPS_DIR_PATH, file_name]
		var resource := ResourceLoader.load(full_path)
		
		if resource is AppStats:
			results.append(resource)
		else:
			push_warning("[ResourceService] El archivo %s no es AppStats" % file_name)
	
	print("[ResourceService] Cargados %d AppStats correctamente" % results.size())
	_cache["app_resources"] = results
	EventBus.resources_loaded.emit(true)
	
	return results

## Limpia la caché de recursos
func clear_cache() -> void:
	_cache.clear()
	_app_database = null
	print("[ResourceService] Caché limpiada")

## Precarga recursos críticos
func preload_critical_resources() -> void:
	print("[ResourceService] Precargando recursos críticos...")
	load_app_database()
