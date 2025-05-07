extends Control

func _on_opcion_1_pressed() -> void:
	GameManager.num_jugadores = 1
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_2_pressed() -> void:
	GameManager.num_jugadores = 2
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_3_pressed() -> void:
	GameManager.num_jugadores = 3
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_4_pressed() -> void:
	GameManager.num_jugadores = 4
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")
