extends CharacterBody2D

@export var SPEED:float = 100.0
var SPEED_DEFAULT = 100.0
var DEADZONE := 0.2
var escudo_activo:bool = false
var puede_activar_escudo = true
var max_health = 20
var health = 20
var player_id: int
var danio_default = 2
@onready var animaciones:AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:

	var usar_escudo := false
	var dispositivo = GameManager.get_device_for_player(player_id)

	if dispositivo == null:
		# JUGADOR CON TECLADO
		var directionX := Input.get_axis("left", "right")
		var directionY := Input.get_axis("up", "down")

		velocity.x = directionX * SPEED
		velocity.y = directionY * SPEED
		
	else:
		# JUGADOR CON MANDO
		var directionX := Input.get_joy_axis(dispositivo, JOY_AXIS_LEFT_X)
		var directionY := Input.get_joy_axis(dispositivo, JOY_AXIS_LEFT_Y)

		if abs(directionX) > DEADZONE:
			velocity.x = directionX * SPEED
		else:
			velocity.x = 0

		if abs(directionY) > DEADZONE:
			velocity.y = directionY * SPEED
		else:
			velocity.y = 0

	# Movimiento real
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.1)
	

	# Animaciones (opcional)
	if velocity.length() > 0:
		animaciones.play("run")
		animaciones.flip_h = velocity.x < 0
	else:
		animaciones.play("idle")
	
	move_and_slide()
