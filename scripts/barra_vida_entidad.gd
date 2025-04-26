extends ProgressBar

func _ready() -> void:
	var player = get_parent()
	
	max_value = player.max_health
	min_value = 0
	
	value = player.health
	
	player.connect("health_changed", Callable(self, "_on_entity_health_changed"))
	
	show()

func _on_entity_health_changed(new_health):
	value = new_health
	
	if new_health < get_parent().max_health:
		show()   # Se muestra si se ha perdido salud
	else:
		hide()   # Se oculta si la salud es completa
