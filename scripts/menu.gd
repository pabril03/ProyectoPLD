extends Control

@onready var play_btn    := $Principal/VBoxContainer/Play
@onready var options_btn := $Principal/VBoxContainer/Options
@onready var exit_btn    := $Principal/VBoxContainer/Exit

func _ready() -> void:
	# Al entrar en la escena, el foco cae en “Play”
	play_btn.grab_focus()
	GlobalSettings.set_music_enabled(true)
	TranslationServer.set_locale(Save.game_data.language)
	GameManager.spawn_markers.clear()
	
func _process(_delta: float) -> void:
	if $SettingsMenu.volver:
		$SettingsMenu.visible = false
		$SettingsMenu.volver = false
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Volver"):
		$SettingsMenu.visible = false

func _on_play_pressed() -> void:
	var joypads = Input.get_connected_joypads()
	if joypads.size() == 0:
		GameManager.soloplay = true
		GameManager.num_jugadores = 1 

	GameManager.num_jugadores = joypads.size() + 1
	GameManager.configurar_dispositivos()
	get_tree().change_scene_to_file("res://UI/selectorPersonajes.tscn")

func _on_options_pressed() -> void:
	$SettingsMenu.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()
