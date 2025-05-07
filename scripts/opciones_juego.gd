extends VBoxContainer


func _on_opcion_1_pressed() -> void:
	get_tree().paused = false

func _on_opcion_2_pressed() -> void:
	pass # Replace with function body.

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")
	GameManager.resetearStats()
