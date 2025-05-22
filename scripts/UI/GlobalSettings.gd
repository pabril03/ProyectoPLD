extends Node

#VIDEO

func change_displayMode(toggle):
	if toggle:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Save.game_data.full_screen_on = toggle
	Save.save_data()

# AUDIO

func update_master_vol(bus_idx, vol):
	if vol <= -50:
		AudioServer.set_bus_mute(bus_idx, true)
		AudioServer.set_bus_volume_db(bus_idx, -80)  # volumen mínimo absoluto
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, vol)
	
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
		
