extends CharacterBody2D

var SPEED: float = 150.0
var dano: int = 2
var num_colisiones: int = 0

var max_distance: float = 1000.0
var distance_traveled: float = 0.0
var last_position: Vector2

# Creamos una función para definir la posición de la bala al dispararla
func set_start_position(pos: Vector2) -> void:
	last_position = pos

func _ready():
	collision_layer = 2 # Capa 2 para que no colisionen entre sí
	collision_mask = 1 # Para que colisione con los elementos del mapa y el jugador
	if last_position == Vector2.ZERO:  # Si no se inicializa la bala desde fuera se utiliza la posición global.
		last_position = global_position

func _physics_process(delta: float) -> void:
	# Actualizamos la distancia recorrida para esta bala
	var current_position = global_position
	var frame_distance = current_position.distance_to(last_position)
	distance_traveled += frame_distance
	last_position = current_position
	
	if distance_traveled >= max_distance:
		queue_free()  # Eliminamos la bala si supera la distancia permitida
		return
	
	# Mueve la bala y detecta colisiones
	var colision = move_and_collide(velocity * delta)
	
	if num_colisiones >= 10:
		queue_free()
		return
	
	if colision:
		num_colisiones += 1
	
		# Aumentamos la velocidad tras cada rebote
		velocity *= 1.1
		
		# Rebote en ángulo espejo
		velocity = velocity.bounce(colision.get_normal())
		# Ajustar la rotación para seguir la nueva dirección
		rotation = velocity.angle()
	

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemigo"):
		body.reducirVida(dano)
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
