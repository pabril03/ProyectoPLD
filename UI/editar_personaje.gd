extends Control

@export var Personajes: Array[CharacterData]
@onready var sprite = $Sprite2D
@onready var label = $ColorRect2/Label
var cont:int = 0

func _ready() -> void:
	sprite.texture = Personajes[0].img
	label.text = Personajes[0].key

func sig() -> void:
	if cont < Personajes.size() - 1:
		cont += 1
		sprite.texture = Personajes[cont].img
		label.text = Personajes[cont].key


func ant() -> void:
	if cont > 0:
		cont -= 1
		sprite.texture = Personajes[cont].img
		label.text = Personajes[cont].key


func _on_before_pressed() -> void:
	ant()


func _on_next_pressed() -> void:
	sig()


func _on_select_pressed() -> void:
	GameManager.asignarClase(label.text, 0)
