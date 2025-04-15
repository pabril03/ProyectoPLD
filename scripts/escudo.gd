extends Area2D

var escudo_id: int

func _ready() -> void:
	collision_layer = 1 << 5  # Capa 7 (bit 6) 
	collision_mask = (1 << 0) | (1 << 5)  # Establece las capas con las que el jugador debe colisionar.

func get_escudo_id() -> int:
	return escudo_id

func _on_body_entered(body: Node2D) -> void:
	#if body.has_method("get_shooter_id") and body.get_shooter_id() == escudo_id:
	#	return

	#elif body.is_in_group("balas"):
	#	repeler_bala(body)
	if body.is_in_group("balas"):
		repeler_bala(body)

#Método para repeler la bala
func repeler_bala(bala: Node2D) -> void:
	var direction = (bala.global_position - global_position).normalized()
	bala.velocity = direction * bala.SPEED * 1.1
	bala.rotation = bala.velocity.angle()
	
	#Para poder reflectar las balas y que se vuelvan de la propiedad del jugador
	#print("Bala antes de rebotar: " + str(bala.shooter_id))
	var player = get_parent()
	#print(player.player_id)
	
	if player.player_id != bala.shooter_id:
		
		bala.shooter_id = player.player_id
		#print("Bala despues de rebotar: " + str(bala.shooter_id))
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
		bala.collision_mask = mask
		#print(bala.collision_mask)
		
		# También aplica a su Area2D, si tiene
		var area = bala.get_node("Area2D")
		area.collision_layer = 1 << 5
		area.collision_mask = mask
	else:
		return
