extends Control

## Minijuego educativo: Password Strength Trainer
## Enseña a crear contraseñas seguras con análisis en tiempo real y consejos prácticos

@onready var password_input = $MarginContainer/Panel/VBoxContainer/InputContainer/PasswordInput
@onready var strength_bar = $MarginContainer/Panel/VBoxContainer/StrengthContainer/StrengthBar
@onready var strength_label = $MarginContainer/Panel/VBoxContainer/StrengthContainer/StrengthLabel
@onready var score_label = $MarginContainer/Panel/VBoxContainer/TopBar/ScoreLabel
@onready var nivel_label = $MarginContainer/Panel/VBoxContainer/TopBar/NivelLabel
@onready var feedback_container = $MarginContainer/Panel/VBoxContainer/FeedbackContainer/FeedbackScroll/FeedbackList
@onready var tips_container = $MarginContainer/Panel/VBoxContainer/TipsContainer/TipsScroll/TipsList
@onready var btn_check = $MarginContainer/Panel/VBoxContainer/ButtonContainer/BtnCheck
@onready var btn_generate = $MarginContainer/Panel/VBoxContainer/ButtonContainer/BtnGenerate
@onready var btn_siguiente = $MarginContainer/Panel/VBoxContainer/ButtonContainer/BtnSiguiente
@onready var challenge_label = $MarginContainer/Panel/VBoxContainer/ChallengeContainer/ChallengeLabel
@onready var resultado_label = $MarginContainer/Panel/VBoxContainer/ResultadoContainer/ResultadoLabel

var nivel_actual: int = 1
var puntos_totales: int = 0
var desafios_completados: int = 0

# Desafíos progresivos
var desafios = [
	{"nivel": 1, "objetivo": "Crea una contraseña con al menos 8 caracteres", "min_score": 30},
	{"nivel": 2, "objetivo": "Incluye mayúsculas y minúsculas (mín. 10 caracteres)", "min_score": 50},
	{"nivel": 3, "objetivo": "Añade números a tu contraseña (mín. 12 caracteres)", "min_score": 70},
	{"nivel": 4, "objetivo": "Incluye símbolos especiales (!@#$%)", "min_score": 85},
	{"nivel": 5, "objetivo": "Crea una contraseña EXCELENTE (15+ caracteres)", "min_score": 100}
]

# Listas de palabras comunes a evitar
var palabras_debiles = [
	"password", "contraseña", "123456", "qwerty", "admin", "usuario",
	"letmein", "welcome", "monkey", "dragon", "master", "abc123",
	"iloveyou", "password1", "123123", "12345678"
]

func _ready():
	btn_check.pressed.connect(_on_check_pressed)
	btn_generate.pressed.connect(_on_generate_pressed)
	btn_siguiente.pressed.connect(_on_siguiente_pressed)
	password_input.text_changed.connect(_on_password_changed)
	
	resultado_label.hide()
	btn_siguiente.hide()
	
	actualizar_ui()
	mostrar_desafio_actual()
	mostrar_tips_generales()

func actualizar_ui():
	score_label.text = "⭐ Puntos: %d" % puntos_totales
	nivel_label.text = "📊 Nivel: %d/5" % nivel_actual

func mostrar_desafio_actual():
	if nivel_actual > desafios.size():
		victoria()
		return
	
	var desafio = desafios[nivel_actual - 1]
	challenge_label.text = "🎯 DESAFÍO %d: %s" % [desafio["nivel"], desafio["objetivo"]]
	password_input.text = ""
	password_input.editable = true
	resultado_label.hide()
	btn_siguiente.hide()
	btn_check.disabled = false
	actualizar_analisis("")

func _on_password_changed(new_text: String):
	actualizar_analisis(new_text)

func actualizar_analisis(password: String):
	if password.length() == 0:
		strength_bar.value = 0
		strength_label.text = "Escribe una contraseña..."
		strength_label.add_theme_color_override("font_color", Color.GRAY)
		limpiar_feedback()
		return
	
	var score = calcular_puntuacion(password)
	strength_bar.value = score
	
	# Actualizar etiqueta de fortaleza
	if score < 30:
		strength_label.text = "MUY DÉBIL 😱"
		strength_label.add_theme_color_override("font_color", Color.RED)
	elif score < 50:
		strength_label.text = "DÉBIL 😟"
		strength_label.add_theme_color_override("font_color", Color.ORANGE)
	elif score < 70:
		strength_label.text = "REGULAR 😐"
		strength_label.add_theme_color_override("font_color", Color.YELLOW)
	elif score < 85:
		strength_label.text = "BUENA 😊"
		strength_label.add_theme_color_override("font_color", Color.GREEN_YELLOW)
	elif score < 100:
		strength_label.text = "FUERTE 💪"
		strength_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		strength_label.text = "EXCELENTE! 🔥"
		strength_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Mostrar feedback en tiempo real
	mostrar_feedback(password, score)

func calcular_puntuacion(password: String) -> int:
	var score = 0
	
	# Longitud (hasta 40 puntos)
	score += min(password.length() * 2, 40)
	
	# Mayúsculas (10 puntos)
	if tiene_mayusculas(password):
		score += 10
	
	# Minúsculas (10 puntos)
	if tiene_minusculas(password):
		score += 10
	
	# Números (10 puntos)
	if tiene_numeros(password):
		score += 10
	
	# Símbolos especiales (15 puntos)
	if tiene_simbolos(password):
		score += 15
	
	# Bonus por diversidad (15 puntos)
	var tipos = 0
	if tiene_mayusculas(password): tipos += 1
	if tiene_minusculas(password): tipos += 1
	if tiene_numeros(password): tipos += 1
	if tiene_simbolos(password): tipos += 1
	score += tipos * 3
	
	# Penalizaciones
	if contiene_palabra_comun(password):
		score -= 30
	if tiene_secuencia_repetitiva(password):
		score -= 15
	if tiene_patron_teclado(password):
		score -= 20
	
	return clamp(score, 0, 100)

func tiene_mayusculas(text: String) -> bool:
	return text != text.to_lower()

func tiene_minusculas(text: String) -> bool:
	return text != text.to_upper()

func tiene_numeros(text: String) -> bool:
	for c in text:
		if c.is_valid_int():
			return true
	return false

func tiene_simbolos(text: String) -> bool:
	var simbolos = "!@#$%^&*()_+-=[]{}|;:',.<>?/~`"
	for c in text:
		if c in simbolos:
			return true
	return false

func contiene_palabra_comun(text: String) -> bool:
	var lower_text = text.to_lower()
	for palabra in palabras_debiles:
		if palabra in lower_text:
			return true
	return false

func tiene_secuencia_repetitiva(text: String) -> bool:
	if text.length() < 3:
		return false
	
	for i in range(text.length() - 2):
		if text[i] == text[i+1] and text[i] == text[i+2]:
			return true
	return false

func tiene_patron_teclado(text: String) -> bool:
	var patrones = ["qwerty", "asdfgh", "zxcvbn", "123456", "abcdef"]
	var lower_text = text.to_lower()
	for patron in patrones:
		if patron in lower_text:
			return true
	return false

func mostrar_feedback(password: String, _score: int):
	limpiar_feedback()
	
	var feedbacks: Array[String] = []
	
	# Análisis positivo
	if password.length() >= 12:
		feedbacks.append("✅ Buena longitud (%d caracteres)" % password.length())
	elif password.length() >= 8:
		feedbacks.append("⚠️ Longitud aceptable, pero podrías usar más caracteres")
	else:
		feedbacks.append("❌ Muy corta - usa al menos 12 caracteres")
	
	if tiene_mayusculas(password):
		feedbacks.append("✅ Incluye mayúsculas")
	else:
		feedbacks.append("❌ Falta incluir mayúsculas (A-Z)")
	
	if tiene_minusculas(password):
		feedbacks.append("✅ Incluye minúsculas")
	else:
		feedbacks.append("❌ Falta incluir minúsculas (a-z)")
	
	if tiene_numeros(password):
		feedbacks.append("✅ Incluye números")
	else:
		feedbacks.append("❌ Falta incluir números (0-9)")
	
	if tiene_simbolos(password):
		feedbacks.append("✅ Incluye símbolos especiales")
	else:
		feedbacks.append("❌ Falta incluir símbolos (!@#$%)")
	
	# Advertencias
	if contiene_palabra_comun(password):
		feedbacks.append("⚠️ Contiene palabra común - evítalas")
	
	if tiene_secuencia_repetitiva(password):
		feedbacks.append("⚠️ Tiene caracteres repetidos consecutivos")
	
	if tiene_patron_teclado(password):
		feedbacks.append("⚠️ Contiene patrón de teclado predecible")
	
	# Mostrar feedbacks
	for fb in feedbacks:
		var label = Label.new()
		label.text = fb
		
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		feedback_container.add_child(label)

func limpiar_feedback():
	for child in feedback_container.get_children():
		child.queue_free()

func mostrar_tips_generales():
	var tips = [
		"💡 Usa al menos 12 caracteres (idealmente 15+)",
		"🔤 Mezcla mayúsculas y minúsculas",
		"🔢 Incluye números en posiciones aleatorias",
		"🔣 Añade símbolos especiales (!@#$%^&*)",
		"🚫 Evita palabras del diccionario",
		"🔄 No reutilices contraseñas",
		"📝 Usa frases memorables: 'M3Gu$t@L33r!'",
		"🎲 Considera un gestor de contraseñas",
		"❌ Nunca uses: 123456, password, qwerty",
		"🔐 Activa autenticación de dos factores"
	]
	
	for tip in tips:
		var label = Label.new()
		label.text = tip
		label.add_theme_font_size_override("",28)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		tips_container.add_child(label)

func _on_check_pressed():
	var password = password_input.text
	var score = calcular_puntuacion(password)
	var desafio = desafios[nivel_actual - 1]
	
	if score >= desafio["min_score"]:
		# ¡Desafío completado!
		var puntos_ganados = score + (nivel_actual * 10)
		puntos_totales += puntos_ganados
		desafios_completados += 1
		
		resultado_label.text = "🎉 ¡DESAFÍO COMPLETADO!\n\n"
		resultado_label.text += "Contraseña: %s\n" % password
		resultado_label.text += "Puntuación: %d/100\n" % score
		resultado_label.text += "Puntos ganados: +%d\n\n" % puntos_ganados
		resultado_label.text += "Análisis de seguridad:\n"
		resultado_label.text += obtener_analisis_detallado(password, score)
		resultado_label.add_theme_color_override("font_color", Color.GREEN)
		resultado_label.show()
		
		password_input.editable = false
		btn_check.disabled = true
		btn_siguiente.show()
		
		actualizar_ui()
	else:
		resultado_label.text = "😕 Casi lo logras...\n\n"
		resultado_label.text += "Puntuación: %d/100\n" % score
		resultado_label.text += "Necesitas: %d puntos mínimo\n\n" % desafio["min_score"]
		resultado_label.text += "💡 Sugerencias:\n"
		resultado_label.text += obtener_sugerencias(password, score)
		resultado_label.add_theme_color_override("font_color", Color.ORANGE)
		resultado_label.show()

func obtener_analisis_detallado(password: String, _score: int) -> String:
	var analisis = ""
	
	analisis += "• Longitud: %d caracteres " % password.length()
	if password.length() >= 15:
		analisis += "⭐ EXCELENTE\n"
	elif password.length() >= 12:
		analisis += "✅ BUENA\n"
	else:
		analisis += "⚠️ MEJORABLE\n"
	
	analisis += "• Mayúsculas: %s\n" % ("✅ Sí" if tiene_mayusculas(password) else "❌ No")
	analisis += "• Minúsculas: %s\n" % ("✅ Sí" if tiene_minusculas(password) else "❌ No")
	analisis += "• Números: %s\n" % ("✅ Sí" if tiene_numeros(password) else "❌ No")
	analisis += "• Símbolos: %s\n" % ("✅ Sí" if tiene_simbolos(password) else "❌ No")
	
	if not contiene_palabra_comun(password):
		analisis += "• Sin palabras comunes ✅\n"
	else:
		analisis += "• Contiene palabra común ⚠️\n"
	
	if not tiene_secuencia_repetitiva(password):
		analisis += "• Sin repeticiones ✅\n"
	
	if not tiene_patron_teclado(password):
		analisis += "• Sin patrones predecibles ✅\n"
	
	return analisis

func obtener_sugerencias(password: String, _score: int) -> String:
	var sugerencias = ""
	
	if password.length() < 12:
		sugerencias += "• Añade más caracteres (mín. 12)\n"
	
	if not tiene_mayusculas(password):
		sugerencias += "• Incluye letras MAYÚSCULAS\n"
	
	if not tiene_minusculas(password):
		sugerencias += "• Incluye letras minúsculas\n"
	
	if not tiene_numeros(password):
		sugerencias += "• Añade números (0-9)\n"
	
	if not tiene_simbolos(password):
		sugerencias += "• Incluye símbolos (!@#$%)\n"
	
	if contiene_palabra_comun(password):
		sugerencias += "• Evita palabras comunes\n"
	
	if sugerencias == "":
		sugerencias = "• Solo necesitas un poco más de fortaleza!"
	
	return sugerencias

func _on_generate_pressed():
	# Generar contraseña segura de ejemplo
	var chars_mayus = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var chars_minus = "abcdefghijklmnopqrstuvwxyz"
	var chars_nums = "0123456789"
	var chars_simbolos = "!@#$%^&*()_+-=[]{}|"
	
	var password = ""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Asegurar al menos uno de cada tipo
	password += chars_mayus[rng.randi() % chars_mayus.length()]
	password += chars_minus[rng.randi() % chars_minus.length()]
	password += chars_nums[rng.randi() % chars_nums.length()]
	password += chars_simbolos[rng.randi() % chars_simbolos.length()]
	
	# Llenar el resto (hasta 16 caracteres)
	var all_chars = chars_mayus + chars_minus + chars_nums + chars_simbolos
	for i in range(12):
		password += all_chars[rng.randi() % all_chars.length()]
	
	# Mezclar caracteres
	var chars_array = password.split("")
	chars_array.shuffle()
	password = "".join(chars_array)
	
	password_input.text = password
	actualizar_analisis(password)

func _on_siguiente_pressed():
	nivel_actual += 1
	if nivel_actual > desafios.size():
		victoria()
	else:
		mostrar_desafio_actual()

func victoria():
	resultado_label.text = "🏆 ¡ENTRENAMIENTO COMPLETADO! 🏆\n\n"
	resultado_label.text += "Has dominado el arte de las contraseñas seguras\n\n"
	resultado_label.text += "📊 Estadísticas finales:\n"
	resultado_label.text += "• Desafíos completados: %d/5\n" % desafios_completados
	resultado_label.text += "• Puntos totales: %d\n\n" % puntos_totales
	resultado_label.text += "🎓 Lecciones aprendidas:\n"
	resultado_label.text += "✅ Longitud mínima 12+ caracteres\n"
	resultado_label.text += "✅ Mezclar tipos de caracteres\n"
	resultado_label.text += "✅ Evitar palabras comunes\n"
	resultado_label.text += "✅ No usar patrones predecibles\n"
	resultado_label.text += "✅ Usar gestor de contraseñas\n\n"
	resultado_label.text += "¡Ahora puedes crear contraseñas ultra seguras! 🔐"
	resultado_label.add_theme_color_override("font_color", Color.GOLD)
	resultado_label.show()
	
	password_input.hide()
	btn_check.hide()
	btn_generate.hide()
	btn_siguiente.hide()
	challenge_label.hide()
	
	await get_tree().create_timer(1.5).timeout
	
	if Global.has_method("report_challenge_result"):
		Global.report_challenge_result(true)
	else:
		print("Victoria en Password Strength Trainer - Puntos: ", puntos_totales)
