extends Control

## Minijuego de ciberseguridad: Email Phishing Detector
## El jugador actúa como filtro de correo, identificando emails de phishing antes de que lleguen a la bandeja

@export var email_database: EmailDatabase
var emails: Array[EmailResource] = []

@onready var sender_label = $Panel/VBoxContainer/EmailHeader/SenderLabel
@onready var subject_label = $Panel/VBoxContainer/EmailHeader/SubjectLabel
@onready var body_display = $Panel/VBoxContainer/BodyContainer/BodyDisplay
@onready var link_container = $Panel/VBoxContainer/LinkContainer
@onready var link_label = $Panel/VBoxContainer/LinkContainer/LinkLabel
@onready var resultado_label = $Panel/VBoxContainer/ResultadoLabel
@onready var hint_label = $Panel/VBoxContainer/HintContainer/HintLabel
@onready var vidas_label = $Panel/VBoxContainer/TopBar/VidasLabel
@onready var puntos_label = $Panel/VBoxContainer/TopBar/PuntosLabel
@onready var progreso_label = $Panel/VBoxContainer/TopBar/ProgresoLabel
@onready var timer_label = $Panel/VBoxContainer/TopBar/TimerLabel

@onready var btn_legitimo = $Panel/VBoxContainer/ButtonContainer/BtnLegitimo
@onready var btn_phishing = $Panel/VBoxContainer/ButtonContainer/BtnPhishing
@onready var btn_pista = $Panel/VBoxContainer/ButtonContainer/BtnPista
@onready var btn_siguiente = $Panel/VBoxContainer/ButtonContainer/BtnSiguiente

var email_actual_index: int = 0
var puntos: int = 0
var vidas: int = 3
var emails_completados: int = 0
var total_emails: int
@export var max_mails : int = 5
var tiempo_restante: float = 600.0  # 10 minutos
var uso_pista: bool = false

func _ready():
	if email_database:
		emails = email_database.get_shuffled_emails()
		total_emails = min(emails.size(), max_mails)
	
	resultado_label.hide()
	hint_label.hide()
	btn_siguiente.hide()
	link_container.hide()
	
	actualizar_ui()
	mostrar_email_actual()
	
	btn_legitimo.pressed.connect(_on_legitimo_pressed)
	btn_phishing.pressed.connect(_on_phishing_pressed)
	btn_pista.pressed.connect(_on_pista_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)

func _process(delta):
	tiempo_restante -= delta
	if tiempo_restante <= 0:
		tiempo_restante = 0
		game_over()
	actualizar_timer()

func actualizar_timer():
	var minutos = floori(tiempo_restante / 60.0)
	var segundos = floori(tiempo_restante) % 60
	timer_label.text = "Tiempo: %02d:%02d" % [minutos, segundos]
	
	if tiempo_restante < 60:
		timer_label.add_theme_color_override("font_color", Color.RED)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func actualizar_ui():
	vidas_label.text = "❤️ Vidas: %d" % vidas
	puntos_label.text = "⭐ Puntos: %d" % puntos
	progreso_label.text = "📧 Email: %d/%d" % [emails_completados + 1, total_emails]

func mostrar_email_actual():
	if email_actual_index >= emails.size() or email_actual_index >= total_emails:
		victoria()
		return
	
	var email: EmailResource = emails[email_actual_index]
	
	sender_label.text = "De: " + email.get_display_sender()
	subject_label.text = "Asunto: " + email.subject
	body_display.text = email.body
	
	if email.has_link and email.link_url != "":
		link_container.show()
		link_label.text = "🔗 Enlace: " + email.link_url
	else:
		link_container.hide()
	
	resultado_label.hide()
	hint_label.hide()
	btn_siguiente.hide()
	uso_pista = false
	
	btn_legitimo.disabled = false
	btn_phishing.disabled = false
	btn_pista.disabled = false

func _on_legitimo_pressed():
	verificar_respuesta(false)

func _on_phishing_pressed():
	verificar_respuesta(true)

func verificar_respuesta(es_phishing: bool):
	var email: EmailResource = emails[email_actual_index]
	var respuesta_correcta = (email.is_phishing == es_phishing)
	
	btn_legitimo.disabled = true
	btn_phishing.disabled = true
	btn_pista.disabled = true
	
	if respuesta_correcta:
		var puntos_ganados = 100
		if not uso_pista:
			puntos_ganados += 50
			resultado_label.text = "✅ ¡CORRECTO! +150 puntos (100 + 50 bonus sin pista)"
		else:
			resultado_label.text = "✅ ¡CORRECTO! +100 puntos"
		
		puntos += puntos_ganados
		resultado_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		vidas -= 1
		resultado_label.text = "❌ INCORRECTO - Perdiste una vida"
		resultado_label.add_theme_color_override("font_color", Color.RED)
		
		if vidas <= 0:
			game_over()
			return
	
	resultado_label.show()
	mostrar_explicacion(email)
	
	actualizar_ui()
	btn_siguiente.show()

func mostrar_explicacion(email: EmailResource):
	var explicacion = "\n\n" + email.explanation
	
	if email.is_phishing:
		var flags = email.get_red_flags()
		if flags.size() > 0:
			explicacion += "\n\n🚩 Señales de alerta detectadas:\n"
			for flag in flags:
				explicacion += "• " + flag + "\n"
	
	resultado_label.text += explicacion

func _on_pista_pressed():
	var email: EmailResource = emails[email_actual_index]
	hint_label.text = "💡 Pista: " + email.hint
	hint_label.show()
	uso_pista = true
	btn_pista.disabled = true

func _on_siguiente_pressed():
	emails_completados += 1
	email_actual_index += 1
	
	if email_actual_index >= total_emails:
		victoria()
	else:
		mostrar_email_actual()

func victoria():
	resultado_label.text = "🎉 ¡VICTORIA! 🎉\n\n"
	resultado_label.text += "Completaste el entrenamiento anti-phishing\n"
	resultado_label.text += "Emails analizados: %d/%d\n" % [emails_completados, total_emails]
	resultado_label.text += "Puntos totales: %d\n" % puntos
	resultado_label.text += "Vidas restantes: %d\n" % vidas
	resultado_label.add_theme_color_override("font_color", Color.GOLD)
	resultado_label.show()
	
	ocultar_controles()
	
	await get_tree().create_timer(3.0).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(true)
	else:
		print("Victoria en Email Phishing Detector - Puntos: ", puntos)

func game_over():
	resultado_label.text = "💀 GAME OVER 💀\n\n"
	if tiempo_restante <= 0:
		resultado_label.text += "Se acabó el tiempo\n"
	else:
		resultado_label.text += "Te quedaste sin vidas\n"
	resultado_label.text += "Emails completados: %d/%d\n" % [emails_completados, total_emails]
	resultado_label.text += "Puntos obtenidos: %d\n" % puntos
	resultado_label.add_theme_color_override("font_color", Color.RED)
	resultado_label.show()
	
	ocultar_controles()
	
	await get_tree().create_timer(3.0).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(false)
	else:
		print("Derrota en Email Phishing Detector")

func ocultar_controles():
	btn_legitimo.hide()
	btn_phishing.hide()
	btn_pista.hide()
	btn_siguiente.hide()
	hint_label.hide()
