extends Control

class_name FakeUpdateVirus

## Virus que simula una actualización falsa del sistema
## Requiere que el usuario cancele antes de que se "instale"

signal virus_cleared
signal virus_failed

@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var status_label = $VBoxContainer/StatusLabel
@onready var update_text = $VBoxContainer/UpdateText
@onready var btn_cancel = $VBoxContainer/HBoxContainer/BtnCancel
@onready var btn_install = $VBoxContainer/HBoxContainer/BtnInstall
@onready var timer = $Timer

var is_active: bool = false
var progress: float = 0.0
var progress_speed: float = 3.0 # %/segundo

func _ready():
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_install.pressed.connect(_on_install_pressed)
	timer.timeout.connect(_on_timer_timeout)

func start_infection() -> void:
	is_active = true
	progress = 0.0
	status_label.text = "Descargando actualización crítica..."
	update_text.text = "[b]Windows Update Pro Max Ultra[/b]\n\nActualización crítica detectada:\n• Parche de seguridad KB9527\n• Optimizador de rendimiento\n• Antivirus mejorado\n\n[color=#ff4444]⚠️ INSTALACIÓN REQUERIDA⚠️[/color]"
	timer.start()
	set_process(true)

func _process(delta):
	if not is_active:
		return
	
	progress += progress_speed * delta
	progress_bar.value = progress
	
	if progress >= 50:
		status_label.text = "Instalando... ⚠️ NO APAGUES EL EQUIPO"
		status_label.modulate = Color(1, 0.5, 0)
	
	if progress >= 85:
		status_label.text = "INSTALANDO BACKDOOR..."
		status_label.modulate = Color(1, 0, 0)
	
	if progress >= 100:
		_on_install_complete()

func _on_cancel_pressed():
	if not is_active:
		return
	is_active = false
	status_label.text = "✅ ACTUALIZACIÓN FALSA DETENIDA"
	status_label.modulate = Color(0, 1, 0)
	await get_tree().create_timer(1.0).timeout
	virus_cleared.emit()

func _on_install_pressed():
	# Instalar acelera el virus
	progress_speed *= 2
	status_label.text = "⚠️ INSTALACIÓN ACELERADA ⚠️"

func _on_install_complete():
	is_active = false
	status_label.text = "❌ MALWARE INSTALADO"
	status_label.modulate = Color(1, 0, 0)
	await get_tree().create_timer(1.0).timeout
	virus_failed.emit()

func _on_timer_timeout():
	# Cada segundo, pequeño incremento extra
	if is_active:
		progress += 5
