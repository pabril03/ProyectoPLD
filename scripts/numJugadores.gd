extends Control

@onready var play_btn    := $MarginContainer/VBoxContainer/HBoxContainer/Opcion1

func _ready() -> void:
	# Al entrar en la escena, el foco cae en “Play”
	play_btn.grab_focus()

func _on_opcion_1_pressed() -> void:
	GameManager.resetearStats()
	GameManager.num_jugadores = 1
	GameManager.soloplay = true
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_2_pressed() -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() == 0:
		print("IMPOSIBLE, hay menos de 2 dispositivos conectados.")
		return

	GameManager.resetearStats()
	GameManager.num_jugadores = 2
	GameManager.soloplay = false
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_3_pressed() -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() < 2:
		print("IMPOSIBLE, hay menos de 3 dispositivos conectados.")
		return

	GameManager.resetearStats()
	GameManager.num_jugadores = 3
	GameManager.soloplay = false
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_opcion_4_pressed() -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() < 3:
		print("IMPOSIBLE, hay menos de 4 dispositivos conectados.")
		return
		
	GameManager.resetearStats()
	GameManager.num_jugadores = 4
	GameManager.soloplay = false
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")
