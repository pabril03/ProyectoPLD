extends Control

func _process(delta: float) -> void:
	if $SettingsMenu.volver:
		$SettingsMenu.visible = false
		$SettingsMenu.volver = false

func _on_opcion_1_pressed() -> void:
	get_tree().paused = false

func _on_opcion_2_pressed() -> void:
	$SettingsMenu.visible = true

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")
	GameManager.resetearStats()
