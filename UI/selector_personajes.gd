extends Control

@export var personajesDisponibles: Array[CharacterData]

func _ready() -> void:
	var personajes = [$Personaje1, $Personaje2, $Personaje3, $Personaje4]
	for i in range(personajes.size()):
		var personaje = personajes[i]
		personaje.ID = i
		personaje.Personajes = personajesDisponibles
	
	for i in range(GameManager.num_jugadores):
		personajes[i].visible = true

func _on_empezar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/main.tscn")
