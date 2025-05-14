extends Node2D

const bala = preload("res://escenas/Modelos base (mapas y player)/bala.tscn")

@onready var punta: Marker2D = $Marker2D
@onready var sprite: Sprite2D = $Sprite2D
var puedoDisparar: bool = true
@onready var shoot_timer: Timer = $Timer
@onready var alt_timer: Timer = $AltTimer
const DEADZONE := 0.2
const JOY_ID := 0 # Normalmente 0 para el primer mando conectado
var dispositivo: Variant = null # null = teclado/rató, int = joy_id
var x := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_X)
var y := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_Y)
var direccion_disparo = Vector2.ZERO

@export var SPEED := 200
@export var BOUNCES := 1
@export var SPREAD_DEGREES := 45.0
@export var ALT_SPREAD_DEGREES := 22.5
@export var DANIO := 1.25
@export var PELLETS := 7

var tipo_arma: String = "Shotgun"

func _ready() -> void:
	shoot_timer.wait_time = 1.5
	alt_timer.wait_time = 2.25

	visibility_layer = get_parent().player_id + 1

func _process(_delta: float) -> void:
	
	var player = get_parent()
	dispositivo = GameManager.get_device_for_player(player.player_id)
	var disparar := false
	var disparar_alterno := false
	
	var input_vector = Vector2.ZERO
	if dispositivo == null:
		var jugador = get_parent()
		look_at(get_global_mouse_position())
		disparar = Input.is_action_pressed("shoot")
		disparar_alterno = Input.is_action_pressed("Alter-shoot")
		direccion_disparo = (get_global_mouse_position() - jugador.global_position).normalized()

	else:
		input_vector.x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		input_vector.y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if input_vector.length() > DEADZONE:
			rotation = input_vector.angle()
			direccion_disparo = input_vector.normalized()
		
		disparar = Input.is_action_pressed("shoot_pad") # o el que definas
		disparar_alterno = Input.is_action_pressed("alter-shoot_pad") # o el que definas

	rotation_degrees = wrap(rotation_degrees, 0 ,360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
		get_parent().get_node("AnimatedSprite2D").flip_h = true
	else:
		scale.y = 1
		get_parent().get_node("AnimatedSprite2D").flip_h = false
	
	if disparar:
		disparo()
		
	if disparar_alterno:
		disparo_largo()

func disparo():
	var player = get_parent()

	if not puedoDisparar or player.escudo_activo:
		return

	puedoDisparar = false
	shoot_timer.start()
	
	var half_spread = deg_to_rad(SPREAD_DEGREES) * 0.5
	for j in range(PELLETS):
		var angle_offset = randf_range(-half_spread, half_spread)
		var dir = direccion_disparo.rotated(angle_offset)
	
		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		var spriteBala = bullet_i.get_node("Sprite2D")
		match bullet_i.shooter_id:
			1:
				spriteBala.self_modulate = Color(1,0,0)
			2:
				spriteBala.self_modulate = Color(0,1,0)
			3:
				spriteBala.self_modulate = Color(0,1,0)
			4:
				spriteBala.self_modulate = Color(0,1,1)

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
		bullet_i.set_dano(DANIO)
		bullet_i.set_speed(SPEED)
		bullet_i.set_max_colissions(BOUNCES)
		bullet_i.set_max_distance(75)

		bullet_i.velocity = dir * bullet_i.SPEED
		bullet_i.rotation = dir.angle()
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)

func disparo_largo():
	var player = get_parent()
	if not puedoDisparar or player.escudo_activo:
		return

	puedoDisparar = false
	alt_timer.start()

	var half_spread = deg_to_rad(ALT_SPREAD_DEGREES) * 0.5

	for j in range(PELLETS):
		var angle_offset = randf_range(-half_spread, half_spread)
		var dir = direccion_disparo.rotated(angle_offset)

		var bullet_i = bala.instantiate()
		bullet_i.shooter_id = player.player_id
		var spriteBala = bullet_i.get_node("Sprite2D")
		match bullet_i.shooter_id:
			1:
				spriteBala.self_modulate = Color(1,0,0)
			2:
				spriteBala.self_modulate = Color(0,1,0)
			3:
				spriteBala.self_modulate = Color(0,1,0)
			4:
				spriteBala.self_modulate = Color(0,1,1)

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
		bullet_i.set_dano(DANIO)
		bullet_i.set_speed(SPEED)
		bullet_i.set_max_colissions(BOUNCES)
		bullet_i.set_max_distance(100)

		bullet_i.velocity = dir * bullet_i.SPEED
		bullet_i.rotation = dir.angle()
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)

func _on_timer_timeout() -> void:
	puedoDisparar = true

func _on_alt_timer_timeout() -> void:
	puedoDisparar = true

func desaparecer() -> void:
	sprite.visible = false

func aparecer() -> void:
	sprite.visible = true

func conectar() -> void:
# Conecta señales para reactivar el disparo cuando terminen
	shoot_timer.timeout.connect(_on_timer_timeout)
	alt_timer.timeout.connect(_on_alt_timer_timeout)
