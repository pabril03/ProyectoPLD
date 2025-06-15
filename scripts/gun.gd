extends Node2D

const bala = preload("res://escenas/Modelos base (mapas y player)/bala.tscn")
@export var DANIO = 2
const DEADZONE := 0.2
const TRIGGER_THRESHOLD := 0.5
const MAX_AMMO : float = 20.0
var municion : float = 20.0
const JOY_ID := 0 # Normalmente 0 para el primer mando conectado
var dispositivo: Variant = null # null = teclado/rató, int = joy_id
var x := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_X)
var y := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_Y)
var direccion_disparo = Vector2.RIGHT

@onready var punta: Marker2D = $Marker2D
@onready var sprite: Sprite2D = $Sprite2D

var puedoDisparar: bool = true
var en_rafaga = false
var cooldown_rafaga = true

var tipo_arma: String = "Gun"

@onready var audio_balas := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(audio_balas)
	audio_balas.stream = preload("res://audio/raygun_shot.mp3")
	audio_balas.bus = "SFX"
	audio_balas.volume_db = -20.0
		
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
		disparar_alterno = Input.is_action_just_pressed("alter-shoot")
		direccion_disparo = (get_global_mouse_position() - jugador.global_position).normalized()
	
	else:
		input_vector.x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		input_vector.y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if input_vector.length() > DEADZONE:
			rotation = input_vector.angle()
			direccion_disparo = input_vector.normalized()

		var R2_threshold =  Input.get_joy_axis(dispositivo, JOY_AXIS_TRIGGER_RIGHT)
		if R2_threshold > TRIGGER_THRESHOLD:
			disparar = true

		var L2_threshold =  Input.get_joy_axis(dispositivo, JOY_AXIS_TRIGGER_LEFT)
		if L2_threshold > TRIGGER_THRESHOLD:
			disparar_alterno = true

	rotation_degrees = wrap(rotation_degrees, 0 ,360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
		get_parent().get_node("AnimatedSprite2D").flip_h = true
	else:
		scale.y = 1
		get_parent().get_node("AnimatedSprite2D").flip_h = false
	
	if get_parent().polimorf:
		$Sprite2D.visible = false
	else:
		$Sprite2D.visible = true
		if disparar:
			disparo()
		if disparar_alterno:
			disparo_rafaga()

func disparo():
	var player = get_parent()
	
	if not puedoDisparar or player.escudo_activo:
		return
	
	if municion == 0:
		player.recarga_ammo_label()
		return
	
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		bullet_i.process_mode = Node.PROCESS_MODE_PAUSABLE
		municion -= 1.0
		var spriteBala = bullet_i.get_node("Sprite2D")
		bullet_i.shooter_id = player.player_id
		match bullet_i.shooter_id:
			1:
				spriteBala.self_modulate = Color(1,0,0)
			2:
				spriteBala.self_modulate = Color(0,1,0)
			3:
				spriteBala.self_modulate = Color(0,0,1)
			4:
				spriteBala.self_modulate = Color(0,1,1)

		# Colocamos a la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5  # = 32
		bullet_i.set_dano(DANIO)
		# Queremos que colisione con:
		# - el entorno (capa 1 → bit 0 → valor 1)
		# - todos los jugadores excepto el que dispara

		var mask = 1  # siempre incluir el entorno (bit 0)
		#print(player.player_id)
		for i in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
			if i != player.player_id:
				mask |= 1 << i  # activar ese bit
		
		mask |= 1 << 6  # Añadir la capa 7 (bit 6)
		mask |= 1 << 7  # Añadimos la capa 8, la de los enemigos
		bullet_i.collision_mask = mask

		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)

		bullet_i.velocity = direccion_disparo * bullet_i.SPEED
		bullet_i.rotation = rotation

		# Audio
		audio_balas.play()

		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)
		puedoDisparar = false
		

func disparo_rafaga():
	var player = get_parent()
	if en_rafaga or not cooldown_rafaga or player.escudo_activo or not puedoDisparar:
		return

	if municion == 0:
		player.recarga_ammo_label()
		return

	# Variables de control para el CD de las ráfagas
	en_rafaga = true
	cooldown_rafaga = false

	# Guardamos la posición y dirección de las balas para que sigan las 3 la misma
	# trayectoria
	var posicion_rafaga = punta.global_position

	for i in range(3):   # Disparara ráfagas de 3 disparos rápidos
		if municion == 0.0:
			return
		
		var bullet_i = bala.instantiate()
		bullet_i.process_mode = Node.PROCESS_MODE_PAUSABLE
		municion -= 1.0
		bullet_i.shooter_id = player.player_id
		var spriteBala = bullet_i.get_node("Sprite2D")
		match bullet_i.shooter_id:
			1:
				spriteBala.self_modulate = Color(1,0,0)
			2:
				spriteBala.self_modulate = Color(0,1,0)
			3:
				spriteBala.self_modulate = Color(0,0,1)
			4:
				spriteBala.self_modulate = Color(0,1,1)

		# Colocamos a la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5  # = 32
		bullet_i.set_dano(DANIO)
		# Queremos que colisione con:
		# - el entorno (capa 1 → bit 0 → valor 1)
		# - todos los jugadores excepto el que dispara

		var mask = 1  # siempre incluir el entorno (bit 0)
		#print(player.player_id)
		for j in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
			if j != player.player_id:
				mask |= 1 << j  # activar ese bit
		
		mask |= 1 << 6  # Añadir la capa 7 (bit 6)
		mask |= 1 << 7  # Añadimos la capa 8, la de los enemigos
		bullet_i.collision_mask = mask

		bullet_i.global_position = posicion_rafaga
		bullet_i.set_start_position(posicion_rafaga)
		bullet_i.velocity = direccion_disparo * bullet_i.SPEED
		bullet_i.rotation = direccion_disparo.angle()

		#Audio
		audio_balas.play()

		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)
		await get_tree().create_timer(0.075).timeout

	en_rafaga = false
	puedoDisparar = true
	await get_tree().create_timer(0.65).timeout   # Creamos un timer entre ráfagas para evitar spam
	cooldown_rafaga = true

func _on_timer_timeout() -> void:
	puedoDisparar = true
	
func capa(n): return pow(2, n - 1)

func desaparecer() -> void:
	sprite.visible = false

func aparecer() -> void:
	sprite.visible = true

func set_municion(ammo: float) -> void:
	municion = ammo
