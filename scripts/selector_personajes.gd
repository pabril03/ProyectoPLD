extends Control

@export var personajesDisponibles: Array[CharacterData]
@onready var play_btn := $MarginContainer/VBoxContainer/Empezar

@onready var personajes = [
	$MarginContainer/VBoxContainer/HBoxContainer/Personaje1,
	$MarginContainer/VBoxContainer/HBoxContainer/Personaje2,
	$MarginContainer/VBoxContainer/HBoxContainer/Personaje3,
	$MarginContainer/VBoxContainer/HBoxContainer/Personaje4
]

func _ready() -> void:
	for i in range(personajes.size()):
		var personaje = personajes[i]
		personaje.ID = i
		personaje.Personajes = personajesDisponibles

	for i in range(GameManager.num_jugadores):
		personajes[i].visible = true

	play_btn.grab_focus()

func _process(_delta: float) -> void:
	if $SeleccionJuego.volver:
		$SeleccionJuego.visible = false
		$SeleccionJuego.volver = false
		$MarginContainer/VBoxContainer.visible = true
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Volver"):
		$SeleccionJuego.visible = false
		$MarginContainer/VBoxContainer.visible = true

func _on_empezar_pressed() -> void:
	$SeleccionJuego.visible = true
	$MarginContainer/VBoxContainer.visible = false


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/numJugadores.tscn")
