extends Control
class_name PhishingGameUI

## Controlador de UI para el juego de detección de phishing

@export var card_stack: CardStack
@export var score_label: Label
@export var correct_label: Label
@export var incorrect_label: Label
@export var feedback_panel: Panel
@export var feedback_label: Label
@export var explanation_label: Label

func _ready() -> void:
	if card_stack:
		card_stack.card_answered.connect(_on_card_answered)
		card_stack.game_finished.connect(_on_game_finished)
	_update_ui()

func _update_ui() -> void:
	## Actualiza los labels de estadísticas
	if score_label and card_stack:
		score_label.text = "Score: %d" % card_stack.current_score
	
	if correct_label and card_stack:
		correct_label.text = "✓ %d" % card_stack.correct_answers
	
	if incorrect_label and card_stack:
		incorrect_label.text = "✗ %d" % card_stack.incorrect_answers

func _on_card_answered(is_correct: bool, card_data: PhishingCard) -> void:
	## Muestra feedback cuando se responde una carta
	_update_ui()
	_show_feedback(is_correct, card_data)

func _show_feedback(is_correct: bool, card_data: PhishingCard) -> void:
	## Muestra panel de feedback con la explicación
	if not feedback_panel or not feedback_label:
		return
	
	feedback_panel.visible = true
	
	if is_correct:
		feedback_label.text = "¡CORRECTO! +" + str(card_data.points_correct)
		feedback_label.modulate = Color.GREEN
	else:
		feedback_label.text = "INCORRECTO " + str(card_data.points_incorrect)
		feedback_label.modulate = Color.RED
	
	if explanation_label and card_data.explanation:
		explanation_label.text = card_data.explanation
	
	# Auto-ocultar después de unos segundos
	await get_tree().create_timer(3.0).timeout
	if feedback_panel:
		feedback_panel.visible = false

func _on_game_finished(score: int, correct: int, incorrect: int) -> void:
	## Maneja el fin del juego
	print("=== JUEGO TERMINADO ===")
	print("Score Final: %d" % score)
	print("Correctas: %d" % correct)
	print("Incorrectas: %d" % incorrect)
	
	# Aquí puedes mostrar un panel de resultados finales

# ============================================
# BOTONES DE RESPUESTA
# ============================================

func _on_phishing_button_pressed() -> void:
	## Botón: Esta carta ES phishing
	if card_stack:
		card_stack.answer_phishing()

func _on_legitimate_button_pressed() -> void:
	## Botón: Esta carta es LEGÍTIMA
	if card_stack:
		card_stack.answer_legitimate()

func _on_reset_button_pressed() -> void:
	## Botón: Reiniciar juego
	if card_stack:
		card_stack.reset_game()
		_update_ui()
