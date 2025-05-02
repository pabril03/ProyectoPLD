extends Area2D

var escudo_id: int

func _ready() -> void:
	collision_layer = 1 << 6  # Capa 7 (bit 6) 
	collision_mask = 1 << 5  # Establece las capas con las que el escudo debe colisionar.

func get_escudo_id() -> int:
	return escudo_id

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("balas"):
		repeler_bala(body)

#Método para repeler la bala
func repeler_bala(bala: Node2D) -> void:
	var direction = (bala.global_position - global_position).normalized()
	#var direction = (get_global_mouse_position() - bala.global_position).normalized()
	bala.velocity = direction * bala.SPEED * 1.1
	bala.rotation = bala.velocity.angle()
	bala.distance_traveled = 0

	#Para poder reflectar las balas y que se vuelvan de la propiedad del jugador
	var player = get_parent()

	if player.player_id != bala.shooter_id:
		
		bala.shooter_id = player.player_id
		var spriteBala = bala.get_node("Sprite2D")
		match bala.shooter_id:
			1:
				spriteBala.self_modulate = Color(1,0,0)
			2:
				spriteBala.self_modulate = Color(0,1,0)
			3:
				spriteBala.self_modulate = Color(0,1,0)
			4:
				spriteBala.self_modulate = Color(0,1,1)
				
		# Colocamos a la bala en la capa 6 (bit 5)
		bala.collision_layer = 1 << 5  # = 32

		# Queremos que colisione con:
		# - el entorno (capa 1 → bit 0 → valor 1)
		# - todos los jugadores excepto el que dispara

		var mask = 1  # siempre incluir el entorno (bit 0)
		
		for i in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
			if i != bala.shooter_id:
				mask |= 1 << i  # activar ese bit
			
		mask |= 1 << 6  # Añadir la capa 7 (bit 6)
		mask |= 1 << 7
		bala.collision_mask = mask

	else:
		return
