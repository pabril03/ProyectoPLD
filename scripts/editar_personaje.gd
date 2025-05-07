extends Control

@export var Personajes: Array[CharacterData]
@onready var sprite = $Sprite2D
@onready var label = $ColorRect2/Label

var cont:int = 0
var ID:int = 0

func _ready() -> void:
	_update_ui()

func sig() -> void:
	cont = (cont + 1) % Personajes.size()
	_update_ui()

func ant() -> void:
	cont = (cont - 1 + Personajes.size()) % Personajes.size()
	_update_ui()

func _update_ui() -> void:
	sprite.texture = Personajes[cont].img
	label.text     = Personajes[cont].key

func _on_before_pressed() -> void:
	ant()

func _on_next_pressed() -> void:
	sig()

func _on_select_pressed() -> void:
	GameManager.asignarClase(Personajes[cont].key, ID)
	#get_tree().change_scene_to_file("res://escenas/main.tscn")
