extends Node2D

@export var damage_amount: int = 1
@export var initial_delay: float = 1.0  # espera antes de empezar a chequear

@onready var detector: Area2D = $DetectorEnemigos
@onready var detector2: Area2D = $DetectorPlayer
@onready var sprites := [
	$AnimatedSprite2D,
	$AnimatedSprite2D2,
	$AnimatedSprite2D3,
	$AnimatedSprite2D4,
	$AnimatedSprite2D5,
	$AnimatedSprite2D6,
	$AnimatedSprite2D7,
	$AnimatedSprite2D8,
	$AnimatedSprite2D9
]

@onready var damage_timer: Timer = $DamageTimer
@onready var rearm_timer: Timer = $Rearmado
@onready var init_timer: Timer = $InitTimer

var check_timer: Timer
var is_armed: bool = false

func _ready() -> void:
	for s in sprites:
		s.visible = false
		s.stop()

	detector.monitoring = true                             # activar detección :contentReference[oaicite:2]{index=2}
	detector2.monitoring = true
	rearm_timer.one_shot = false
	damage_timer.one_shot = false
	damage_timer.wait_time = 0.75

	init_timer.one_shot = true
	init_timer.wait_time = 1.0
	init_timer.timeout.connect(_on_init_timeout)

	rearm_timer.timeout.connect(_on_rearm_timeout)
	damage_timer.timeout.connect(_on_damage_timeout)

	pause_physics_for_one_second()

func _physics_process(_delta: float) -> void:
	# Si el Timer está corriendo, _physics_process no debería ejecutarse:
	if init_timer.time_left > 0.0:
		return
		
	# Contar enemigos dentro del área
	var enemies_inside = 0
	for b in detector.get_overlapping_bodies():
		if b.is_in_group("enemy") or b.has_method("set_damage_on_touch"):
			enemies_inside += 1

	# Armar si no hay ninguno y aún no está armada
	if enemies_inside == 0 and not is_armed:
		_activate_trap()

	if is_armed:
		var bodies = detector2.get_overlapping_bodies()
		var has_target = false
		for b in bodies:
			if b.is_in_group("player") or b.has_method("repeler_balas") or b.has_method("activar_escudo"):
				has_target = true
				break

		if has_target:
			if rearm_timer.is_stopped() and damage_timer.is_stopped():
				rearm_timer.start()
		else:
			# Si ya no hay targets y está en modo daño, reproducir defuse
			rearm_timer.stop()

func pause_physics_for_one_second() -> void:
	# Detenemos inmediatamente el _physics_process
	set_physics_process(false)                             
	# Iniciamos el Timer
	init_timer.start() 

func _on_init_timeout() -> void:
	# Vuelto a activar el _physics_process tras 1 s
	set_physics_process(true)   

func _activate_trap() -> void:
	is_armed = true

	# Mostrar animación de armado
	for s in sprites:
		s.visible = true
		s.play("damage")

func _on_rearm_timeout() -> void:
	# al armarse, empezar daño periódico
	if damage_timer.is_stopped():
		damage_timer.start()

func _on_damage_timeout() -> void:
	for body in detector2.get_overlapping_bodies():         # lista siempre fresca :contentReference[oaicite:7]{index=7}
		if (body.is_in_group("player") or body.has_method("repeler_balas")):
			if body.health <= 0:
				continue
			if body.has_method("take_damage"):
				body.take_damage(damage_amount)
