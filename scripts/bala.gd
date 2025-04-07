extends CharacterBody2D

var SPEED: float = 200.0
var dano: int = 2
var num_colisiones: int = 0

var max_distance: float = 1000.0
var distance_traveled: float = 0.0
var last_position: Vector2
var shooter_id = 0

# Creamos una función para definir la posición de la bala al dispararla
func set_start_position(pos: Vector2) -> void:
	last_position = pos

func get_bala() -> bool:
	return true

func get_shooter_id() -> int:
	return shooter_id

func _ready():
	collision_layer = 2 # Capa 2 para que no colisionen entre sí
	collision_mask = 1 or 3 # Para que colisione con los elementos del mapa y el jugador
	
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

func _on_area_2d_body_entered(body: Node2D) -> void:

	# Si la bala tiene un ID distinto del cuerpo con el que colisiona
	if body.has_method("get_shooter_id") and body.get_shooter_id() != shooter_id:

		# Si se disparan entre enemigos, ignora la colisión
		if shooter_id >= 1000000 and (body.has_method("get_shooter_id") and body.get_shooter_id() >= 1000000):
			self.add_collision_exception_with(body)
			return

		# Si el cuerpo es un jugador con un escudo activo
		if body.has_method("get_escudo_activo") and body.get_escudo_activo():
			# La bala pasa a ser propiedad del jugador
			shooter_id = body.get_shooter_id()
			return

		else:
			# Le hace daño al cuerpo y desaparece
			body.take_damage(dano)
			queue_free()
			return

	# Si la bala colisiona con el objeto que la disparó o con su escudo:
	if (body.has_method("get_shooter_id") and body.get_shooter_id() == self.shooter_id) || (body.has_method("get_escudo_id") and body.get_shooter_id() == shooter_id):
		# Atraviesa al objeto
		self.add_collision_exception_with(body)
		return
