extends Node2D

const bala = preload("res://escenas/Modelos base (mapas y player)/bala.tscn")

@onready var punta: Marker2D = $Marker2D
@onready var laser: Line2D = $Line2D
@onready var sprite: Sprite2D = $Sprite2D
var puedoDisparar: bool = true
@onready var shoot_timer: Timer = $Timer
@onready var alt_timer: Timer = $AltTimer
const MAX_AMMO = 10
var municion = 10
const DEADZONE := 0.2
const JOY_ID := 0 # Normalmente 0 para el primer mando conectado
var dispositivo: Variant = null # null = teclado/rató, int = joy_id
var x := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_X)
var y := Input.get_joy_axis(JOY_ID, JOY_AXIS_RIGHT_Y)
var direccion_disparo = Vector2.ZERO

@export var SPEED := 400
@export var BOUNCES := 1
@export var DANIO := 7
@export var PELLETS := 1

var tipo_arma: String = "Sniper"

const LAYER_DEFAULT = 1 << 0       # capa 1: visibilidad normal
var LAYER_INVIS = 0
var _my_viewport_idx: int
var _original_vp_masks := []

# Audio
@onready var audio_balas := AudioStreamPlayer.new()


func _ready() -> void:
	await get_tree().create_timer(0.05).timeout
	var player = get_parent()
	var split = get_tree().current_scene.get_node("SplitScreen2D") as SplitScreen2D
	_my_viewport_idx = split.players.find(player)
	if _my_viewport_idx == -1:
		push_warning("Jugador no registrado en SplitScreen2D.players")
		return

	# Para volver invisible solo el laser
	LAYER_INVIS = 1 << (5 + _my_viewport_idx)

	# Guarda máscara original de todos los viewports
	_original_vp_masks.clear()
	for vp in GameManager.player_viewports:
		_original_vp_masks.append(vp.canvas_cull_mask)
		vp.canvas_cull_mask |= LAYER_DEFAULT | LAYER_INVIS
		
	shoot_timer.wait_time = 1.5
	alt_timer.wait_time = 2.25

	visibility_layer = get_parent().player_id + 5
	activar_invisibilidad()
	
	add_child(audio_balas)
	audio_balas.stream = preload("res://audio/disparo_sniper.mp3")
	audio_balas.bus = "SFX"
	audio_balas.volume_db = 5.0

func _process(_delta: float) -> void:
	
	var player = get_parent()
	dispositivo = GameManager.get_device_for_player(player.player_id)
	var disparar := false
	var disparar_alterno := false
	
	var input_vector = Vector2.ZERO
	if dispositivo == null:
		var jugador = get_parent()
		look_at(get_global_mouse_position())
		disparar = Input.is_action_just_pressed("shoot")
		disparar_alterno = Input.is_action_just_pressed("alter-shoot")
		direccion_disparo = (get_global_mouse_position() - jugador.global_position).normalized()

	else:
		input_vector.x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		input_vector.y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if input_vector.length() > DEADZONE:
			rotation = input_vector.angle()
			direccion_disparo = input_vector.normalized()
		
		# Solo activar escudo si ese jugador pulsa su botón (ej: botón L1 → ID 4 en la mayoría)
		if dispositivo == 0:
			disparar = Input.is_action_pressed("shoot_p1") # o el que definas
			disparar_alterno = Input.is_action_pressed("alter-shoot_p1") # o el que definas
		if dispositivo == 1:
			disparar = Input.is_action_pressed("shoot_p2") # o el que definas
			disparar_alterno = Input.is_action_pressed("alter-shoot_p2") # o el que definas
		if dispositivo == 2:
			disparar = Input.is_action_pressed("shoot_p3") # o el que definas
			disparar_alterno = Input.is_action_pressed("alter-shoot_p3") # o el que definas
		if dispositivo == 3:
			disparar = Input.is_action_pressed("shoot_p4") # o el que definas
			disparar_alterno = Input.is_action_pressed("alter-shoot_p4") # o el que definas

	rotation_degrees = wrap(rotation_degrees, 0 ,360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	if get_parent().polimorf:
		$Sprite2D.visible = false
	else:
		$Sprite2D.visible = true
		if disparar:
			disparo()
		if disparar_alterno:
			disparo_largo()

func disparo():
	var player = get_parent()

	if not puedoDisparar or player.escudo_activo:
		return

	if municion == 0:
		player.recarga_ammo_label()
		return

	puedoDisparar = false
	shoot_timer.start()

	for j in range(PELLETS):

		var bullet_i = bala.instantiate()
		bullet_i.process_mode = Node.PROCESS_MODE_PAUSABLE
		municion -= 1
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
		bullet_i.set_max_distance(225)

		bullet_i.velocity = direccion_disparo * bullet_i.SPEED
		bullet_i.rotation = direccion_disparo.angle()
		
		audio_balas.play()
		
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)

func disparo_largo():
	var player = get_parent()
	if not puedoDisparar or player.escudo_activo:
		return

	if municion == 0:
		player.recarga_ammo_label()
		return

	puedoDisparar = false
	alt_timer.start()

	for j in range(PELLETS):

		var bullet_i = bala.instantiate()
		bullet_i.process_mode = Node.PROCESS_MODE_PAUSABLE
		municion -= 1
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
		bullet_i.set_dano(DANIO*2)
		bullet_i.set_speed(SPEED)
		bullet_i.set_max_colissions(BOUNCES)
		bullet_i.set_max_distance(300)

		bullet_i.velocity = direccion_disparo * bullet_i.SPEED
		bullet_i.rotation = direccion_disparo.angle()
		
		audio_balas.stream = preload("res://audio/disparo_sniper.mp3")
		audio_balas.bus = "SFX"
		
		audio_balas.play()
		
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

func activar_invisibilidad():

	# 1) Cambia tu layer a la capa de invisibilidad
	laser.visibility_layer = LAYER_INVIS

	# 2) Quita esa capa de los demás viewports
	for i in GameManager.player_viewports.size():
		if i == _my_viewport_idx:
			continue
		var vp: SubViewport = GameManager.player_viewports[i]
		vp.canvas_cull_mask = _original_vp_masks[i] & ~LAYER_INVIS

func set_municion(ammo: float) -> void:
	municion = ammo
