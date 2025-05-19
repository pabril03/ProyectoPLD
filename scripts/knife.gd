extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $Sprite2D/Knife
@onready var col_shape: CollisionShape2D = $Sprite2D/Knife/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var alt_timer: Timer = $AltTimer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var dispositivo: Variant = null # null = teclado/ratón, int = joypad id
const DEADZONE := 0.2
const JOY_ID := 0 # primer mando

@export var SPEED := 200
@export var DANIO := 10
@export var ARC_COLLISION: Shape2D
@export var THRUST_COLLISION: Shape2D

var tipo_arma: String = "Knife"

func _ready() -> void:
	
	timer.one_shot      = true
	alt_timer.one_shot  = true
	
	# Configurar timers
	timer.wait_time = 0.5  # duración del golpe en arco
	alt_timer.wait_time = 0.75  # duracion del ataque hacia delante o estocada

	# Desactivar área inicialmente
	attack_area.monitoring = false
	attack_area.visible = false
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_body_entered"))

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
		disparar_alterno = Input.is_action_just_pressed("Alter-shoot")
	else:
		input_vec.x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		input_vec.y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if input_vec.length() > DEADZONE:
			rotation = input_vec.angle()
			
		disparar = Input.is_action_just_pressed("shoot_pad") # o el que definas
		disparar_alterno = Input.is_action_just_pressed("alter-shoot_pad") # o el que definas

	rotation_degrees = wrap(rotation_degrees, 0, 360)
	# Voltear sprite según orientación
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
		get_parent().get_node("AnimatedSprite2D").flip_h = true
	else:
		scale.y = 1
		get_parent().get_node("AnimatedSprite2D").flip_h = false

	# Controles de ataque
	if disparar:
		attack_arc()
		
	if disparar_alterno:
		attack_thrust()

func attack_arc() -> void:
	
	 # Configurar colisión y posición del área
	col_shape.shape = ARC_COLLISION
	# Activar área y reproducir animación de corte en arco
	attack_area.visible = true
	attack_area.monitoring = true
	anim_player.play("arc_hit")
	timer.start()

func attack_thrust() -> void:
	# Configurar colisión y posición del área
	col_shape.shape = THRUST_COLLISION
	# Activar área y reproducir animación de estocada
	attack_area.visible = true
	attack_area.monitoring = true
	anim_player.play("thrust_hit")
	alt_timer.start()

func _on_arc_timeout() -> void:
	# Desactivar área de arco
	attack_area.monitoring = false
	attack_area.visible = false

func _on_thrust_timeout() -> void:
	# Desactivar área de estocada y restaurar posición
	attack_area.monitoring = false
	attack_area.visible = false

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("balas"):
		body.queue_free()
	elif body.has_method("take_damage"):
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
