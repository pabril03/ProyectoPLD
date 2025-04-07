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
	
	if not puedoDisparar or player.escudo_activo:
		return
		
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		var direction = (get_global_mouse_position() - punta.global_position).normalized()
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = rotation
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
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = posicion_rafaga
		bullet_i.set_start_position(posicion_rafaga)
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = direction.angle()
		await get_tree().create_timer(0.075).timeout

	en_rafaga = false
	puedoDisparar = true
	await get_tree().create_timer(0.65).timeout   # Creamos un timer entre ráfagas para evitar spam
	cooldown_rafaga = true

func _on_timer_timeout() -> void:
	puedoDisparar = true
