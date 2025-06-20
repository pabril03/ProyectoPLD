extends Control

var volver : bool = false

# Video settings
@onready var display_options = $ColorRect/TabContainer/Video/MarginContainer/VideoSettings/OptionButton

# Audio settings
@onready var master_slider = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/MasterVbox/SliderMasterVol
@onready var master_label = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/MasterVbox/Label
@onready var music_slider = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/MusicVbox/SliderMusicVol
@onready var music_label = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/MusicVbox/Label
@onready var SFX_slider = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/SfxVbox/SliderSFXVol
@onready var SFX_label = $ColorRect/TabContainer/Audio/MarginContainer/GridContainer/SfxVbox/Label
@onready var brillo_slider = $ColorRect/TabContainer/accesibilidad_tab/MarginContainer/GridContainer/BrilloVbox/SliderBrillo
@onready var label_brillo = $ColorRect/TabContainer/accesibilidad_tab/MarginContainer/GridContainer/BrilloVbox/Label

@onready var optionIdioma = $ColorRect/TabContainer/accesibilidad_tab/MarginContainer/GridContainer/OptionButtonIdioma

# Aqui se cargan los datos del diccionario de Save
func _ready() -> void:
	display_options.select(1 if Save.game_data.full_screen_on else 0)
	GlobalSettings.change_displayMode(Save.game_data.full_screen_on)
	brillo_slider.value = Save.game_data.brightness
	
	#Sliders value
	master_slider.value = Save.game_data.master_vol
	music_slider.value = Save.game_data.music_vol
	SFX_slider.value = Save.game_data.sfx_vol
	
	# Etiquetas en dB aproximado
	master_label.text = str(round(master_slider.value * 100))
	music_label.text = str(round(music_slider.value * 100))
	SFX_label.text = str(round(SFX_slider.value * 100))
	label_brillo.text = str(round((brillo_slider.value - 0.2) / 0.8 * 100))
	
	if Save.game_data.language == "es":
		optionIdioma.select(0)
	else:
		optionIdioma.select(1)

# Video

func _on_option_button_item_selected(index: int) -> void:
	GlobalSettings.change_displayMode(index)

# Audio
# Ver minuto 47:37 del video "https://www.youtube.com/watch?v=BI2dYgOU_wM&ab_channel=LukifahTRES"

func _on_slider_master_vol_value_changed(value: float) -> void:
	GlobalSettings.update_master_vol(0, value)
	master_label.text = str(round(value * 100))


func _on_slider_music_vol_value_changed(value: float) -> void:
	GlobalSettings.update_master_vol(1, value)
	music_label.text = str(round(value * 100))


func _on_slider_sfx_vol_value_changed(value: float) -> void:
	GlobalSettings.update_master_vol(2, value)
	SFX_label.text = str(round(value * 100))


func _on_button_pressed() -> void:
	volver = true


func _on_slider_brillo_value_changed(value: float) -> void:
	GlobalSettings.update_brightness(value)
	label_brillo.text = str(round((value - 0.2) / 0.8 * 100))

# Testing
func _on_option_button_idioma_item_selected(index: int) -> void:
	var idioma = optionIdioma.get_item_text(index)
	
	if idioma == "idiom_es":
		if TranslationServer.get_locale() != "es":
			TranslationServer.set_locale("es")
			Save.game_data.language = "es"
			Save.save_data()
	else:
		if TranslationServer.get_locale() != "en":
			TranslationServer.set_locale("en")
			Save.game_data.language = "en"
			Save.save_data()
		
