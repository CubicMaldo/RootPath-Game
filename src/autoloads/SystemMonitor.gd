extends Node

signal system_overload
signal usage_updated(cpu: float, ram: float)

# Configuración
const MAX_CPU = 100.0
const MAX_RAM = 100.0
const RECOVERY_RATE = 2.0 # Recuperación por segundo
const CRITICAL_THRESHOLD = 90.0

# Estado actual
var cpu_usage: float = 0.0
var ram_usage: float = 0.0
var is_critical: bool = false

# Fuentes de carga
var active_viruses: int = 0
var open_apps: int = 0

func _ready() -> void:
	# Conectar señales si es necesario
	pass

func _process(delta: float) -> void:
	_update_usage(delta)
	_check_status()

func _update_usage(delta: float) -> void:
	# Cálculo base de carga
	var target_cpu = active_viruses * 15.0 # Cada virus añade 15% de carga base
	var target_ram = open_apps * 5.0 # Cada app añade 5% de RAM
	
	# Fluctuación aleatoria pequeña para realismo
	target_cpu += randf_range(-2.0, 2.0)
	
	# Interpolación suave hacia el objetivo
	cpu_usage = move_toward(cpu_usage, target_cpu, delta * 5.0)
	ram_usage = move_toward(ram_usage, target_ram, delta * 10.0)
	
	# Clamping
	cpu_usage = clamp(cpu_usage, 0.0, MAX_CPU)
	ram_usage = clamp(ram_usage, 0.0, MAX_RAM)
	
	usage_updated.emit(cpu_usage, ram_usage)

func _check_status() -> void:
	if cpu_usage >= MAX_CPU or ram_usage >= MAX_RAM:
		DebugLogger.system_monitor("CRITICAL: System Overload! CPU: %.1f%%, RAM: %.1f%%", [cpu_usage, ram_usage])
		system_overload.emit()
	
	var currently_critical = (cpu_usage > CRITICAL_THRESHOLD or ram_usage > CRITICAL_THRESHOLD)
	if currently_critical and not is_critical:
		is_critical = true
		# Podríamos emitir una señal de advertencia aquí
	elif not currently_critical and is_critical:
		is_critical = false

# API Pública
func register_virus_start() -> void:
	active_viruses += 1
	DebugLogger.system_monitor("Virus started. Active viruses: %d", [active_viruses])

func register_virus_end() -> void:
	active_viruses = max(0, active_viruses - 1)
	DebugLogger.system_monitor("Virus ended. Active viruses: %d", [active_viruses])

func register_app_opened() -> void:
	open_apps += 1
	DebugLogger.system_monitor("App opened. Open apps: %d", [open_apps])

func register_app_closed() -> void:
	open_apps = max(0, open_apps - 1)
	DebugLogger.system_monitor("App closed. Open apps: %d", [open_apps])

func add_spike(amount: float) -> void:
	cpu_usage = min(cpu_usage + amount, MAX_CPU)
	DebugLogger.system_monitor("CPU Spike added: %.1f%%", [amount])
