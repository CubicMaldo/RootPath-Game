extends Resource
class_name CardDatabase

## Base de datos de cartas de phishing

@export var cards: Array[PhishingCard] = []
@export var database_name: String = "Default Database"

func get_random_card() -> PhishingCard:
	if cards.is_empty():
		push_warning("CardDatabase está vacía")
		return null
	return cards[randi() % cards.size()]

func get_cards_by_difficulty(difficulty: int) -> Array[PhishingCard]:
	var filtered: Array[PhishingCard] = []
	for card in cards:
		if card.difficulty == difficulty:
			filtered.append(card)
	return filtered

func get_cards_by_category(category: String) -> Array[PhishingCard]:
	var filtered: Array[PhishingCard] = []
	for card in cards:
		if card.category == category:
			filtered.append(card)
	return filtered

func get_card_by_id(card_id: String) -> PhishingCard:
	for card in cards:
		if card.card_id == card_id:
			return card
	return null

func get_random_cards(count: int) -> Array[PhishingCard]:
	var shuffled = cards.duplicate()
	shuffled.shuffle()
	var result: Array[PhishingCard] = []
	for i in range(min(count, shuffled.size())):
		result.append(shuffled[i])
	return result

func get_balanced_cards(count: int) -> Array[PhishingCard]:
	"""Retorna cartas balanceadas entre phishing y legítimas"""
	var phishing_cards: Array[PhishingCard] = []
	var legit_cards: Array[PhishingCard] = []
	
	for card in cards:
		if card.is_phishing:
			phishing_cards.append(card)
		else:
			legit_cards.append(card)
	
	phishing_cards.shuffle()
	legit_cards.shuffle()
	
	var result: Array[PhishingCard] = []
	var desired_phishing: int = int(ceil(float(count) / 2.0))
	var desired_legit: int = count - desired_phishing

	var picked_phishing: int = min(desired_phishing, phishing_cards.size())
	var picked_legit: int = min(desired_legit, legit_cards.size())

	for i in range(picked_phishing):
		result.append(phishing_cards[i])
	for i in range(picked_legit):
		result.append(legit_cards[i])

	var remaining := count - result.size()
	if remaining > 0:
		var leftovers: Array[PhishingCard] = []
		if phishing_cards.size() > picked_phishing:
			leftovers.append_array(phishing_cards.slice(picked_phishing))
		if legit_cards.size() > picked_legit:
			leftovers.append_array(legit_cards.slice(picked_legit))
		leftovers.shuffle()
		for i in range(min(remaining, leftovers.size())):
			result.append(leftovers[i])

	result.shuffle()
	return result
