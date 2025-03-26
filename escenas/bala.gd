extends RigidBody2D

const SPEED:int = 300

func _ready():
	add_to_group("balas")

func _process(delta: float) -> void:
	#transform es la dirección en la que va
	position += transform.x * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()



#func _physics_process(delta: float) -> void:
#	var colision:KinematicCollision2D
#	var movimiento = dir * velocidad * delta
#	colision = move_and_collide(dir * velocidad * delta)
	
#	while colision:
#		movimiento = colision.get_remainder().bounce(colision.get_normal())
#		dir = dir.bounce(colision.get_normal())
		#rotation = dir.angle()
#		colision = move_and_collide(movimiento)
