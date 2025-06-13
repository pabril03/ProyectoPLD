extends Control

@onready var option_button = $MarginContainer/ColorRect/MarginContainer/GridContainer/HBoxContainer/Vidas
@onready var item_list = $MarginContainer/ColorRect/MarginContainer/GridContainer/HBoxContainer2/ItemList
var volver : bool = false

func _ready() -> void:
	GameManager.vidas = 3
	item_list.grab_focus()

func _on_item_list_item_selected(index: int) -> void:
	var mapa_nombre = item_list.get_item_text(index)
	GameManager.mapa = mapa_nombre


func _on_vidas_item_selected(index: int) -> void:
	var texto = option_button.get_item_text(index)
	if texto == "infinitas":
		GameManager.vidas = INF
	else:
		GameManager.vidas = texto.to_int()


func _on_volver_pressed() -> void:
	volver = true


func _on_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/Modelos base (mapas y player)/main.tscn")
