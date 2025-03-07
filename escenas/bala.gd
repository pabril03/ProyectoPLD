extends Node2D

const SPEED:int = 300

func _process(delta: float) -> void:
	#transform es la dirección en la que va
	position += transform.x * SPEED * delta
