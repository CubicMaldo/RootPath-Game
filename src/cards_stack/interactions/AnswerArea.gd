extends Panel
class_name AnswerArea

## Área de respuesta para el juego de phishing
## Arrastra las cartas aquí para responder si son legítimas o phishing

@export var is_legitimate : bool = true  ## true = "LEGÍTIMO", false = "PHISHING"

func _on_area_2d_area_entered(area: Area2D) -> void:
	# El área debe ser hijo de una Card
	var card = area.get_parent()
	
	if not card is Card:
		return
	if card.was_answered():
		return
	
	# El jugador piensa que es legítimo si arrastra a is_legitimate=true
	var player_thinks_legitimate = is_legitimate
	
	# Verificar respuesta (is_phishing es lo contrario de is_legitimate)
	card.check_answer(not player_thinks_legitimate)
	
	# Animación según el tipo de área
	if is_legitimate:
		card.save_card()  # Guardar si es legítimo
	else:
		card.destroy()  # Destruir si es phishing
