extends CharacterBody2D

var SPEED: float = 200.0
var dano: float = 2
var num_colisiones: int = 0
var max_colissions: int = 10

var max_distance: float = 1000.0
var distance_traveled: float = 0.0
var last_position: Vector2
var shooter_id = -1
var tipo_enemigo = null

func set_speed(speed: float) -> void:
	SPEED = speed

func set_dano(dan: float) -> void:
	self.dano = dan

func set_max_colissions(max_cols: int) -> void:
	self.max_colissions = max_cols

func get_dano() -> float:
	return dano

# Creamos una función para definir la posición de la bala al dispararla
func set_start_position(pos: Vector2) -> void:
	last_position = pos

func get_bala() -> bool:
	return true

func get_shooter_id() -> int:
	return shooter_id

func _ready():
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
	
	if num_colisiones >= max_colissions:
		queue_free()
		return
	
	if colision:
		num_colisiones += 1
		var collider = colision.get_collider()

		if collider.has_method("take_damage"):
			if tipo_enemigo != null:
				collider.take_damage(dano, shooter_id, tipo_enemigo)
			else:
				collider.take_damage(dano, shooter_id)
			queue_free()

		# Aumentamos la velocidad tras cada rebote
		velocity *= 1.1
		
		# Rebote en ángulo espejo
		velocity = velocity.bounce(colision.get_normal())
		# Ajustar la rotación para seguir la nueva dirección
		rotation = velocity.angle()
