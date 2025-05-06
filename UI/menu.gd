extends Control

@onready var play_btn    := $Principal/VBoxContainer/Play
@onready var options_btn := $Principal/VBoxContainer/Options
@onready var exit_btn    := $Principal/VBoxContainer/Exit

func _ready() -> void:
	# Al entrar en la escena, el foco cae en “Play”
	play_btn.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")


func _on_options_pressed() -> void:
	#$Principal.visible = false
	#$Opciones.visible = true
	print("¡Temporalmente deshabilitado!")


func _on_exit_pressed() -> void:
	get_tree().quit()
