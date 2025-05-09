extends Control

@export var personajesDisponibles: Array[CharacterData]
@onready var play_btn := $VBoxContainer/Empezar

@onready var personajes = [
	$VBoxContainer/HBoxContainer/Personaje1,
	$VBoxContainer/HBoxContainer/Personaje2,
	$VBoxContainer/HBoxContainer/Personaje3,
	$VBoxContainer/HBoxContainer/Personaje4
]

func _ready() -> void:
	for i in range(personajes.size()):
		var personaje = personajes[i]
		personaje.ID = i
		personaje.Personajes = personajesDisponibles

	for i in range(GameManager.num_jugadores):
		personajes[i].visible = true

	play_btn.grab_focus()

func _on_empezar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/Modelos base (mapas y player)/main.tscn")
