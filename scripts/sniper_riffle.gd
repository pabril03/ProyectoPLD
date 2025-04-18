extends Node2D

const bala = preload("res://escenas/bala.tscn")

@onready var punta: Marker2D = $Marker2D
var puedoDisparar: bool = true
@onready var shoot_timer: Timer = $Timer
@onready var alt_timer: Timer = $Timer

func _ready() -> void:
	shoot_timer.wait_time = 0.75
	alt_timer.wait_time = 1.5

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
		disparo_preciso()

func disparo():
	var player = get_parent()
	if not puedoDisparar or player.escudo_activo:
		return
	if puedoDisparar:
		shoot_timer.start()
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		bullet_i.collision_layer = 1 << 5
		var mask = 1
		for i in range(1, 5):
			if i != player.player_id:
				mask |= 1 << i
		mask |= 1 << 6
		mask |= 1 << 7  # Añadimos la capa 8, la de los enemigos
		bullet_i.collision_mask = mask
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.set_dano(5)
		bullet_i.set_speed(400)
		bullet_i.set_max_colissions(3)
		var direction = (get_global_mouse_position() - punta.global_position).normalized()
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = rotation
		get_tree().root.add_child(bullet_i)
		puedoDisparar = false

func disparo_preciso():
	var player = get_parent()
	if not puedoDisparar or player.escudo_activo:
		return
	if puedoDisparar:
		alt_timer.start()
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		bullet_i.collision_layer = 1 << 5
		var mask = 1
		for i in range(1, 5):
			if i != player.player_id:
				mask |= 1 << i
		mask |= 1 << 6
		mask |= 1 << 7  # Añadimos la capa 8, la de los enemigos
		bullet_i.collision_mask = mask
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.set_dano(10)
		bullet_i.set_speed(600)
		bullet_i.set_max_colissions(2)
		var direction = (get_global_mouse_position() - punta.global_position).normalized()
		bullet_i.velocity = direction * bullet_i.SPEED
		bullet_i.rotation = rotation
		get_tree().root.add_child(bullet_i)
		puedoDisparar = false

func _on_timer_timeout() -> void:
	puedoDisparar = true
