extends Control

@onready var play_btn    := $Principal/VBoxContainer/Play
@onready var options_btn := $Principal/VBoxContainer/Options
@onready var exit_btn    := $Principal/VBoxContainer/Exit

func _ready() -> void:
	# Al entrar en la escena, el foco cae en “Play”
	play_btn.grab_focus()
	
func _process(_delta: float) -> void:
	if $SettingsMenu.volver:
		$SettingsMenu.visible = false
		$SettingsMenu.volver = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Volver"):
		$SettingsMenu.visible = false

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/numJugadores.tscn")


func _on_options_pressed() -> void:
	$SettingsMenu.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()
