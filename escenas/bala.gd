extends RigidBody2D

const SPEED:int = 300
var dano:int = 2
var direction: Vector2 = Vector2.ZERO

func _ready():
	pass

func _process(delta: float) -> void:
	#transform es la dirección en la que va
	position += transform.x * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigo"):
		body.reducirVida(2)
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
