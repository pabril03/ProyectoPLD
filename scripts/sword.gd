extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var col_shape: CollisionShape2D = $Espada/CollisionShape2D
@onready var attack_area: Area2D = $Espada
@onready var timer: Timer = $Timer
@onready var alt_timer: Timer = $AltTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var dispositivo: Variant = null # null = teclado/ratón, int = joypad id
const DEADZONE := 0.2
const JOY_ID := 0 # primer mando
const MAX_MUNICION = "INF"
var municion = INF

@export var SPEED := 200
@export var DANIO := 7.5

var hit_targets: Array = []
var tipo_arma: String = "sword"
var listo: bool = true
var listo_alt: bool = true

func _ready() -> void:
	
	timer.one_shot      = true
	alt_timer.one_shot  = true
	
	# Configurar timers
	timer.wait_time = 0.75  # duración del golpe en arco
	alt_timer.wait_time = 0.75  # duracion del ataque hacia delante o estocada
	
	var player = get_parent()
	var mask = 1  # siempre incluir el entorno (bit 0)
		#print(player.player_id)
	for i in range(1, 5):  # ID 1 a 4 → capas 2 a 5 → bits 1 a 4
		if i != player.player_id:
			mask |= 1 << i  # activar ese bit
	
	mask |= 1 << 5
	mask |= 1 << 6  # Añadir la capa 7 (bit 6)
	mask |= 1 << 7  # Añadimos la capa 8, la de los enemigos
	attack_area.collision_mask = mask

func _process(_delta: float) -> void:
	# Rotación hacia cursor o joystick derecho
	var player = get_parent()
	dispositivo = GameManager.get_device_for_player(player.player_id)
	var disparar := false
	var disparar_alterno := false
	
	var input_vec = Vector2.ZERO
	if dispositivo == null:
		look_at(get_global_mouse_position())
		disparar = Input.is_action_just_pressed("shoot")
		disparar_alterno = Input.is_action_just_pressed("alter-shoot")
	else:
		input_vec.x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		input_vec.y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if input_vec.length() > DEADZONE:
			rotation = input_vec.angle()
			
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

	rotation_degrees = wrap(rotation_degrees, 0, 360)
	# Voltear sprite según orientación
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
		get_parent().get_node("AnimatedSprite2D").flip_h = true
	else:
		scale.y = 1
		get_parent().get_node("AnimatedSprite2D").flip_h = false

	if get_parent().polimorf:
		$Sprite2D.visible = false
	else:
		if player.muriendo:
			return
		$Sprite2D.visible = true
		if disparar:
			attack_arc()
		if disparar_alterno:
			attack_thrust()

func attack_arc() -> void:

	if not listo:
		return
	listo = false

	hit_targets.clear()

	# Activar área y reproducir animación de corte en arco
	anim_player.play("arc_hit")
	timer.start()

func attack_thrust() -> void:
	
	if not listo_alt:
		return
	listo_alt = false

	hit_targets.clear()

	# Activar área y reproducir animación de estocada
	anim_player.play("thrust_hit")
	alt_timer.start()

func _on_arc_timeout() -> void:
	listo = true
	# Desactivar área de arco

func _on_thrust_timeout() -> void:
	listo_alt = true
	# Desactivar área de estocada y restaurar posición

func _on_attack_area_body_entered(_body: Node) -> void:
	
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("balas"):
			body.queue_free()
		
		if not hit_targets.has(body):
			if body.has_method("take_damage"):
				hit_targets.append(body)
				var player = get_parent()
				body.take_damage(DANIO, player.player_id, "Jugador", "cuchillazo")

func desaparecer() -> void:
	sprite.visible = false

func aparecer() -> void:
	sprite.visible = true

func conectar() -> void:
# Conecta señales para reactivar el disparo cuando terminen
	timer.timeout.connect(_on_arc_timeout)
	alt_timer.timeout.connect(_on_thrust_timeout)

func set_municion(ammo: float) -> void:
	municion = ammo
