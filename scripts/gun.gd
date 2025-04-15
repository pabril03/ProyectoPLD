extends Node2D

const bala = preload("res://escenas/bala.tscn")

@onready var punta: Marker2D = $Marker2D
var puedoDisparar: bool = true
var en_rafaga = false
var cooldown_rafaga = true

func _process(_delta: float) -> void:
	
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0 ,360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	if Input.is_action_pressed("shoot"):
		disparo()
		
	if Input.is_action_pressed("Alter-shoot"):
		disparo_rafaga()
	

func disparo():
	var player = get_parent()
	#print(player.player_id)
	
	if not puedoDisparar or player.escudo_activo:
		return
	
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		# Capa de la bala: del 6 al 9 según el player_id
		# Para la capa del jugador que dispara
		
		# Colocamos a la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5  # = 32

		# Queremos que colisione con:
		# - el entorno (capa 1 → bit 0 → valor 1)
		# - todos los jugadores excepto el que dispara

		var mask = 1  # siempre incluir el entorno (bit 0)
		#print(player.player_id)
		for i in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
			if i != player.player_id:
				mask |= 1 << i  # activar ese bit
		
		mask |= 1 << 6  # Añadir la capa 7 (bit 6)
		bullet_i.collision_mask = mask
		#print(bullet_i.collision_mask)
		
		# También aplica a su Area2D, si tiene
		var area = bullet_i.get_node("Area2D")
		area.collision_layer = 1 << 5
		area.collision_mask = mask
		
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		var direction = (get_global_mouse_position() - punta.global_position).normalized()
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = rotation
		get_tree().root.add_child(bullet_i)
		#print("Mi id es: " + str(bullet_layer))
		puedoDisparar = false
		

func disparo_rafaga():
	var player = get_parent()
	if en_rafaga or not cooldown_rafaga or player.escudo_activo or not puedoDisparar:
		return

	# Variables de control para el CD de las ráfagas
	en_rafaga = true
	cooldown_rafaga = false

	# Guardamos la posición y dirección de las balas para que sigan las 3 la misma
	# trayectoria
	var posicion_rafaga = punta.global_position
	var direction = (get_global_mouse_position() - posicion_rafaga).normalized()

	for i in range(3):   # Disparara ráfagas de 3 disparos rápidos
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		
		# Colocamos a la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5  # = 32

		# Queremos que colisione con:
		# - el entorno (capa 1 → bit 0 → valor 1)
		# - todos los jugadores excepto el que dispara

		var mask = 1  # siempre incluir el entorno (bit 0)
		#print(player.player_id)
		for j in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
			if j != player.player_id:
				mask |= 1 << j  # activar ese bit
		
		mask |= 1 << 6  # Añadir la capa 7 (bit 6)
		bullet_i.collision_mask = mask
		#print(bullet_i.collision_mask)
		
		# También aplica a su Area2D, si tiene
		var area = bullet_i.get_node("Area2D")
		area.collision_layer = 1 << 5
		area.collision_mask = mask
		
		bullet_i.global_position = posicion_rafaga
		bullet_i.set_start_position(posicion_rafaga)
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = direction.angle()
		get_tree().root.add_child(bullet_i)
		await get_tree().create_timer(0.075).timeout

	en_rafaga = false
	puedoDisparar = true
	await get_tree().create_timer(0.65).timeout   # Creamos un timer entre ráfagas para evitar spam
	cooldown_rafaga = true

func _on_timer_timeout() -> void:
	puedoDisparar = true
	
func capa(n): return pow(2, n - 1)
