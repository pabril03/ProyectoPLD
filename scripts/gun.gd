extends Node2D

const bala = preload("res://escenas/bala.tscn")

@onready var punta: Marker2D = $Marker2D
var puedoDisparar: bool = true

func _process(delta: float) -> void:
	
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0 ,360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	if Input.is_action_pressed("shoot"):
		disparo()
	

func disparo():
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		var direction = (get_global_mouse_position() - punta.global_position).normalized()
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = rotation
		puedoDisparar = false


func _on_timer_timeout() -> void:
	puedoDisparar = true
