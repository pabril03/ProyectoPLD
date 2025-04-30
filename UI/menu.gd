extends Control


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/main.tscn")


func _on_options_pressed() -> void:
	$Principal.visible = false
	$Opciones.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_opcion_1_pressed() -> void:
	pass # Replace with function body.


func _on_opcion_2_pressed() -> void:
	pass # Replace with function body.


func _on_atras_pressed() -> void:
	$Principal.visible = true
	$Opciones.visible = false
