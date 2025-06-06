extends Node

const SAVEFILE := "user://SAVEFILE.save"

var game_data: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVEFILE):
		# Si no existe el archivo, asignamos valores por defecto
		game_data = {
			"full_screen_on": false,
			"master_vol": 1.0,
			"music_vol": 1.0,
			"sfx_vol": 1.0,
			"brightness": 1.0
		}
		save_data()
	else:
		var file := FileAccess.open(SAVEFILE, FileAccess.READ)
		if file:
			game_data = file.get_var()
			file.close()

func save_data() -> void:
	var file := FileAccess.open(SAVEFILE, FileAccess.WRITE)
	if file:
		file.store_var(game_data)
		file.close()
