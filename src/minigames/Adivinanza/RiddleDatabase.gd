extends Resource
class_name RiddleDatabase

## Base de datos de adivinanzas de ciberseguridad

var riddles: Array[Dictionary] = [
	{
		"question": "Me pescan sin red, me abren sin llave. Si caes en mi trampa, tus datos no valen. ¿Qué soy?",
		"answer": "phishing",
		"hint": "Es una técnica donde se hacen pasar por alguien de confianza, como un 'pescador' de datos."
	},
	{
		"question": "Tengo llaves pero no cerraduras, tengo espacio pero no habitaciones. Puedes entrar pero no salir si no tienes la clave. ¿Qué soy?",
		"answer": "encriptacion",
		"hint": "Es el proceso de codificar información para que solo las personas autorizadas puedan leerla."
	},
	{
		"question": "Soy un muro que no es de ladrillo, protejo tu casa digital de cualquier pillo. ¿Qué soy?",
		"answer": "firewall",
		"hint": "Su nombre en español significa 'cortafuegos'."
	},
	{
		"question": "Entro en tu casa sin invitación, me copio a mí mismo sin tu autorización. ¿Qué soy?",
		"answer": "virus",
		"hint": "Actúo igual que una enfermedad biológica, pero en tu computadora."
	},
	{
		"question": "Soy secreta y única, si me compartes dejo de ser segura. ¿Qué soy?",
		"answer": "contraseña",
		"hint": "Es la llave principal para entrar a tus cuentas."
	}
]

func get_random_riddle() -> Dictionary:
	return riddles.pick_random()
