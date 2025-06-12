extends Node

@onready var audio := AudioStreamPlayer.new()

var play_music : bool = true
signal brightness_updated(value)

func _ready():
	
	audio.stream = preload("res://audio/default_song.mp3")
	audio.bus = "Music"
	if play_music:
		audio.play()
	
	add_child(audio)

# Función para desactivar la música del menú
func set_music_enabled(enabled: bool) -> void:
	play_music = enabled
	if play_music:
		audio.play()
	else:
		audio.stop()

#VIDEO

func change_displayMode(toggle):
	if toggle:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Save.game_data.full_screen_on = toggle
	Save.save_data()

func update_brightness(value):
	emit_signal("brightness_updated",value)
	Save.game_data.brightness = value
	Save.save_data()

# AUDIO

func update_master_vol(bus_idx, vol):
	var db_vol = linear_to_db(vol)
	
	if vol <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, db_vol)
	
	match bus_idx:
		0:
			Save.game_data.master_vol = vol
			Save.save_data()
		1:
			Save.game_data.music_vol = vol
			Save.save_data()
		2:
			Save.game_data.sfx_vol = vol
			Save.save_data()
		
