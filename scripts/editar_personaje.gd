extends Control

@export var Personajes: Array[CharacterData]
@onready var sprite = $MarginContainer/Sprite2D
@onready var label = $MarginContainer/ColorRect2/Label

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
	match Personajes[cont].key:
		"Artillero":
			label.text = "nom_artillero"
		"Francotirador":
			label.text = "nom_francotirador"
		"Asalto":
			label.text = "nom_asalto"
		"Rogue":
			label.text = "nom_melee"

func _on_before_pressed() -> void:
	ant()

func _on_next_pressed() -> void:
	sig()

func _on_select_pressed() -> void:
	GameManager.asignarClase(Personajes[cont].key, ID)
