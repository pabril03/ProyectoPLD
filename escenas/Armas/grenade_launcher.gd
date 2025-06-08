extends Node2D

@export var Grenade: PackedScene = preload("res://escenas/Modelos base (mapas y player)/granada.tscn")
@export var disperse_grenade_cooldown: float = 5.0
@export var normal_grenade_cooldown: float = 3.0
@export var max_grenade_distance: float = 200.0
var can_throw_grenade: bool = true
var can_throw_grenade_disperse: bool = true

const MAX_AMMO = 10
var municion = 10
const DEADZONE := 0.2
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
var racimo_shots = 5 # granadas lanzadas
var max_spread_radius := 50.0 # grados de dispersión en el racimo

var tipo_arma: String = "grenade_launcher"

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
	
	if player.escudo_activo:
		return
	
	if municion == 0:
		player.recarga_ammo_label()
		return
	
	if can_throw_grenade:
		var target: Vector2
		if dispositivo == null:
			target = get_global_mouse_position()
		else:
			# joystick derecho
			var rx := Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
			var ry := Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
			var dir := Vector2(rx, ry)
			if dir.length() < DEADZONE:
				target = global_position
			else:
				var strength = clamp((dir.length() - DEADZONE) / (1.0 - DEADZONE), 0.0, 1.0)
				target = global_position + dir.normalized() * (max_grenade_distance * strength)
		# instanciar y lanzar
		var grenade = Grenade.instantiate()
		grenade.process_mode = Node.PROCESS_MODE_PAUSABLE
		municion -= 1
		grenade.global_position = global_position
		grenade.owner_id = player.player_id
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(grenade)
		grenade.throw_to(target)
		# cooldown
		can_throw_grenade = false
		await get_tree().create_timer(normal_grenade_cooldown).timeout
		can_throw_grenade = true
		

func disparo_rafaga():
	var player = get_parent()
	
	if player.escudo_activo:
		return
	
	if municion == 0:
		player.recarga_ammo_label()
		return
	
	if can_throw_grenade_disperse:
		var target: Vector2
		if dispositivo == null:
			target = get_global_mouse_position()
		else:
			# joystick derecho
			var rx := Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
			var ry := Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
			var dir := Vector2(rx, ry)
			if dir.length() < DEADZONE:
				target = global_position
			else:
				var strength = clamp((dir.length() - DEADZONE) / (1.0 - DEADZONE), 0.0, 1.0)
				target = global_position + dir.normalized() * (max_grenade_distance * strength)
		
		# instanciar y lanzar
		for i in range(racimo_shots):
			if municion == 0:
				return
			var grenade = Grenade.instantiate()
			grenade.process_mode = Node.PROCESS_MODE_PAUSABLE
			municion -= 1
			grenade.dano = 3
			grenade.global_position = punta.global_position
			grenade.owner_id = player.player_id
			
			# Offset circular aleatorio alrededor del target
			var angle = randf() * TAU # TAU = 2π, ángulo aleatorio
			var radius = randf() * max_spread_radius # distancia aleatoria dentro del radio
			var offset = Vector2(cos(angle), sin(angle)) * radius
			var offset_target = target + offset
			
			var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
			world.add_child(grenade)
			grenade.throw_to(offset_target)
		
		# cooldown
		can_throw_grenade_disperse = false
		await get_tree().create_timer(disperse_grenade_cooldown).timeout
		can_throw_grenade_disperse = true

func _on_timer_timeout() -> void:
	puedoDisparar = true
	
func capa(n): return pow(2, n - 1)

func desaparecer() -> void:
	sprite.visible = false

func aparecer() -> void:
	sprite.visible = true
