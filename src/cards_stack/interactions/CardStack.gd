class_name CardStack
extends Control

signal card_answered(is_correct: bool, card_data: PhishingCard)
signal game_finished(score: int, correct: int, incorrect: int)

# Exports
@export var offset: float = 30.0
@export var scale_between_cards: float = 0.05
@export var anim_duration: float = 0.45
@export var anim_duration_offset: float = 0.15

# Phishing Game
@export_group("Phishing Game")
@export var card_database: CardDatabase
@export var cards_per_game: int = 10
@export var use_balanced_cards: bool = true  # Balancear phishing vs legítimos
@export var card_template: PackedScene  # Template de carta para instanciar
@export var spawn_jitter: float = 20.0  # Jitter inicial para evitar colisiones con el eliminador

# State
var first_card : Card
var first_card_pos: Vector2
var first_card_scale: Vector2
var last_card : Card

# Game Stats
var current_score: int = 0
var correct_answers: int = 0
var incorrect_answers: int = 0
var cards_answered: int = 0
var _challenge_result_sent: bool = false
var _rng := RandomNumberGenerator.new()

# Tweens
var tween: Tween
var tween_last_card: Tween
var tween_bg: Tween
var tween_game_over: Tween
var tween_shake: Tween

@onready var game_over_visuals: ColorRect = $CanvasLayer/game_over
@onready var finish_text: Label = $CanvasLayer/game_over/finish_text

# ============================================
# LIFECYCLE
# ============================================


func _ready() -> void:
	_rng.randomize()
	# Orden correcto:
	# 1. Cargar datos de la base de datos primero
	await _cards_setup()
	# 2. Configurar señales de las cartas
	_setup_card_signals()
	# 3. Esperar a que el viewport se inicialice correctamente
	await get_tree().process_frame
	await get_tree().process_frame
	# 4. Cachear propiedades de las cartas
	_cache_card_properties()
	# 5. Configurar animaciones y posiciones iniciales
	await _initial_setup_delay()

func _setup_card_signals() -> void:
	for c in %Cards.get_children():
		var put_back_cb := on_card_put_back.bind(c)
		if put_back_cb != null:
			c.put_back.connect(put_back_cb)
		var destroyed_cb := on_card_destroyed.bind(c)
		if destroyed_cb != null:
			c.destroyed.connect(destroyed_cb)
		c.answered.connect(on_card_answered)

func _cache_card_properties() -> void:  # <-- RENOMBRADO Y EXPANDIDO
	var card_count = _get_card_count()
	if card_count == 0:
		push_error("CardStack: No hay cartas en el contenedor %Cards")
		return
	
	first_card = _get_card_at_index(card_count - 1)
	if first_card == null:
		push_error("CardStack: No se pudo obtener la primera carta")
		return
	
	# Cachear la posición LOCAL de la primera carta (relativa a su padre %Cards)
	first_card_pos = first_card.position
	first_card_scale = first_card.scale
	last_card = _get_card_at_index(0)  # <-- CACHEAR ÚLTIMA CARTA

func _cards_setup() -> void:
	if not card_database:
		return
	await _load_cards_from_database()

func _get_card_count() -> int:
	return %Cards.get_child_count()

func _get_card_at_index(index: int) -> Card:
	return %Cards.get_child(index)

func _initial_setup_delay() -> void:
	await get_tree().create_timer(0.5).timeout
	
	if first_card == null:
		push_error("CardStack: first_card es null en _initial_setup_delay")
		return
	
	tween_bg_color(first_card.color)
	
	update_cards()
	
	if tween:
		await tween.finished
	_save_original_positions()

func _save_original_positions() -> void:
	for c in %Cards.get_children():
		c.original_position = c.global_position

# ============================================
# ANIMATION - BACKGROUND
# ============================================

func tween_bg_color(new_color: Color) -> void:
	new_color = new_color.darkened(0.5)
	
	_kill_tween_if_running(tween_bg)
	tween_bg = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_bg.tween_property($BG, "color", new_color, anim_duration * 2.0)

# ============================================
# ANIMATION - CARDS
# ============================================

func update_cards(_thrown: bool = false, animated: bool = true) -> void:
	_kill_tween_if_running(tween)
	tween = _create_parallel_tween()
	
	var child_count: int = _get_card_count()
	
	# Actualizar referencias de cartas
	first_card = _get_card_at_index(child_count - 1)
	last_card = _get_card_at_index(0)
	
	for i in range(child_count - 1, -1, -1):
		var card: Card = _get_card_at_index(i)
		_update_single_card(card, i, child_count, card == first_card, animated)

func _update_single_card(card: Card, index: int, total_cards: int, is_top: bool, animated: bool) -> void:
	card.disabled = not is_top
	
	var multiplier: float = total_cards - 1 - index
	var card_offset: Vector2 = _calculate_card_offset(multiplier)
	var card_scale: Vector2 = _calculate_card_scale(multiplier)
	
	if animated:
		_animate_card_transform(card, card_offset, card_scale, multiplier)
	else:
		_set_card_transform_immediate(card, card_offset, card_scale)

func _calculate_card_offset(multiplier: float) -> Vector2:
	return Vector2(0, offset * multiplier)

func _calculate_card_scale(multiplier: float) -> Vector2:
	return Vector2(scale_between_cards, scale_between_cards) * multiplier

func _animate_card_transform(card: Card, offset_vec: Vector2, scale_vec: Vector2, multiplier: float) -> void:
	var duration: float = anim_duration + (anim_duration_offset * multiplier)
	# Calcular posición objetivo relativa al padre común
	var target_pos = first_card_pos - offset_vec
	tween.tween_property(card, "position", target_pos, duration)
	tween.tween_property(card, "scale", first_card_scale - scale_vec, duration)

func _set_card_transform_immediate(card: Card, offset_vec: Vector2, scale_vec: Vector2) -> void:
	# Asignar posición relativa al padre común
	card.position = first_card_pos - offset_vec
	card.scale = first_card_scale - scale_vec

# ============================================
# CARD INTERACTIONS
# ============================================

func on_card_put_back(which: Card) -> void:
	print("Put back: ", which.get_name())
	
	_update_bg_for_previous_card()
	_animate_card_return(which)
	_schedule_card_reorder(which)

func _update_bg_for_previous_card() -> void:
	var previous_card: Card = _get_card_at_index(_get_card_count() - 2)
	tween_bg_color(previous_card.color)

func _animate_card_return(card: Card) -> void:
	_kill_tween_if_running(tween_last_card)
	tween_last_card = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var target_pos: Vector2 = $TopPoint.global_position - (card.size / 2.0)
	var target_scale: Vector2 = Vector2(0.8, 0.8)
	
	tween_last_card.tween_property(card, "global_position", target_pos, anim_duration / 2.0)
	tween_last_card.parallel().tween_property(card, "scale", target_scale, anim_duration / 2.0)

func _schedule_card_reorder(card: Card) -> void:
	var move_child_cb := %Cards.move_child.bind(card, 0)
	if move_child_cb != null:
		tween_last_card.tween_callback(move_child_cb)
	var update_cb := update_cards.bind(true)
	if update_cb != null:
		tween_last_card.tween_callback(update_cb)

func on_card_destroyed(which: Card) -> void:
	if %Cards.has_node(which.get_path()):
		%Cards.remove_child(which)

	if %Cards.get_children().is_empty():
		return
	
	update_cards(true)
	tween_bg_color(first_card.color)
# ============================================
# VISUAL SETTINGS
# ============================================

func set_cards_3D(state: bool) -> void:
	for c in %Cards.get_children():
		c.is_3D = state

func _on_check_button_toggled(toggled_on: bool) -> void:
	set_cards_3D(toggled_on)

# ============================================
# HELPERS
# ============================================

func _kill_tween_if_running(tween_ref: Tween) -> void:
	if tween_ref and tween_ref.is_running():
		tween_ref.kill()

func _create_parallel_tween() -> Tween:
	return create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true)

# ============================================
# PHISHING GAME LOGIC
# ============================================

func _load_cards_from_database() -> void:
	## Carga cartas de la base de datos y las instancia dinámicamente
	if not card_database:
		push_warning("CardStack: No hay CardDatabase asignada")
		return
	
	# Obtener datos de cartas
	var card_data_list: Array[PhishingCard] = []
	
	if use_balanced_cards:
		card_data_list = card_database.get_balanced_cards(cards_per_game)
	else:
		card_data_list = card_database.get_random_cards(cards_per_game)
	
	if card_data_list.is_empty():
		push_error("CardStack: No se pudieron cargar cartas de la base de datos. Verifica que CardDatabase tenga cartas.")
		return
	
	# Limpiar cartas existentes
	await _clear_existing_cards()
	
	# Instanciar nuevas cartas
	print("CardStack: Instanciando %d cartas..." % card_data_list.size())
	var cardsContainer := %Cards
	for i in range(card_data_list.size()):
		var new_card: Card = _instantiate_card()
		if new_card:
			cardsContainer.add_child(new_card)
			if spawn_jitter > 0.0:
				var jitter := Vector2(
					_rng.randf_range(-spawn_jitter, spawn_jitter),
					_rng.randf_range(-spawn_jitter, spawn_jitter)
				)
				new_card.position += jitter
			new_card.setup_from_data(card_data_list[i])
			print("  - Carta %d: %s Is phishing: %s" % [i, card_data_list[i].card_title,card_data_list[i].is_phishing])
			await get_tree().process_frame
		else:
			push_error("CardStack: No se pudo instanciar la carta %d" % i)
	
	print("CardStack: Cargadas %d cartas exitosamente" % card_data_list.size())

func _clear_existing_cards() -> void:
	## Elimina todas las cartas existentes en el contenedor
	for card in %Cards.get_children():
		card.queue_free()
	
	# Esperar a que se eliminen
	await get_tree().process_frame

func _instantiate_card() -> Card:
	## Instancia una nueva carta desde el template
	if card_template:
		# Si hay template asignado, usar ese
		var instance = card_template.instantiate()
		if instance is Card:
			return instance
		else:
			push_error("CardStack: card_template no es una Card")
			return null
	else:
		# Si no hay template, buscar una carta existente como referencia
		var existing_cards = %Cards.get_children()
		if existing_cards.size() > 0 and existing_cards[0] is Card:
			# Duplicar la primera carta como template
			var template_card: Card = existing_cards[0]
			return template_card.duplicate() as Card
		else:
			push_error("CardStack: No hay card_template ni cartas existentes para usar como template")
			return null

func on_card_answered(is_correct: bool, card_data_param: PhishingCard) -> void:
	## Maneja cuando el jugador responde una carta
	cards_answered += 1
	
	if is_correct:
		correct_answers += 1
		current_score += card_data_param.points_correct
	else:
		incorrect_answers += 1
		current_score += card_data_param.points_incorrect
		_kill_tween_if_running(tween_shake)
		var _original_pos: Vector2 = position
		var _shake_amount: float = 8.0
		var _shake_duration_short: float = 0.06
		var _shake_duration_long: float = 0.12
		# Create a short sequential tween that moves right, then left, then back
		tween_shake = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_shake.tween_property(self, "position", _original_pos + Vector2(_shake_amount, 0), _shake_duration_short)
		tween_shake.tween_property(self, "position", _original_pos + Vector2(-_shake_amount, 0), _shake_duration_long)
		tween_shake.tween_property(self, "position", _original_pos, _shake_duration_short)

	
	card_answered.emit(is_correct, card_data_param)
	
	# Verificar si terminó el juego
	if cards_answered >= cards_per_game:
		_game_over()

func _game_over() -> void:
	if game_over_visuals == null:
		_finish_game()
		return

	_kill_tween_if_running(tween_game_over)
	tween_game_over = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

	# Preparar color inicial (transparente) y destino (actual)
	var target_color: Color = game_over_visuals.color
	var start_color: Color = target_color
	start_color.a = 0.0
	target_color.a = 0.8

	# Aplicar estado inicial
	game_over_visuals.color = start_color
	game_over_visuals.visible = true

	# Tweenear la propiedad color para un fade-in
	_kill_tween_if_running(tween_shake)
	# Tweenear la propiedad color para un fade-in
	tween_game_over.tween_property(game_over_visuals, "color", target_color, anim_duration)
	
	if finish_text:
		if _get_accurracy() >= 70.0:
			finish_text.text = "YOU WON!!!"
		else:
			finish_text.text = "GAME OVER"
	# Esperar a que termine la animación, luego finalizar el juego
	await tween_game_over.finished

func _finish_game() -> void:
	## Finaliza el juego y emite estadísticas
	game_finished.emit(current_score, correct_answers, incorrect_answers)
	_report_challenge_result(_get_accurracy() >= 70.0)

func _get_accurracy() -> float:
	var accuracy: float = 0.0
	if cards_answered > 0:
		accuracy = (float(correct_answers) / float(cards_answered)) * 100.0
	return accuracy


func reset_game() -> void:
	## Reinicia el juego con nuevas cartas
	current_score = 0
	correct_answers = 0
	incorrect_answers = 0
	cards_answered = 0
	_challenge_result_sent = false
	
	# Limpiar y recargar cartas
	await _clear_existing_cards()
	await _load_cards_from_database()

func answer_phishing() -> void:
	## El jugador indica que la carta ES phishing
	if first_card and first_card.card_data:
		first_card.check_answer(true)
		first_card.destroy()

func answer_legitimate() -> void:
	## El jugador indica que la carta es legítima
	if first_card and first_card.card_data:
		first_card.check_answer(false)
		first_card.destroy()

func _report_challenge_result(win: bool) -> void:
	if _challenge_result_sent:
		return
	_challenge_result_sent = true
	var notifier = null
	if has_meta("tree_challenge_notifier"):
		notifier = get_meta("tree_challenge_notifier")
	if notifier is Callable and notifier.is_valid():
		notifier.call(win)
	elif Global.has_method("report_challenge_result"):
		Global.report_challenge_result(win)


func _on_button_pressed_finish() -> void:
	_finish_game()
