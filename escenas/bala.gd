extends CharacterBody2D

const SPEED:float = 200.0
var dano:int = 2
var num_colisiones:int = 0
var cambia_color:bool = false

func _ready():
	collision_mask = 1  # Ignora la capa del jugador (si el jugador usa una capa 2)

func _physics_process(delta: float) -> void:
	# Mueve la bala y detecta colisiones
	var colision = move_and_collide(velocity * delta)
	
	if num_colisiones >= 4:
		queue_free()
	
	if colision:
		num_colisiones += 1
		# Rebote en ángulo espejo
		velocity = velocity.bounce(colision.get_normal())
		# Ajustar la rotación de la bala para que siga la nueva dirección
		rotation = velocity.angle()

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
