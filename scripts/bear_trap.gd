extends "fire_trap.gd"

var target_to_follow: Node2D = null
var follow_timer: Timer
var trap_used: bool = false
var player_speed: int = 0

func _ready() -> void:
	damage_amount = 3
	detector.monitoring = true
	anim.play("defuse")
	rearm_timer.one_shot = true
	damage_timer.one_shot = false
	damage_timer.wait_time = 0.1

	rearm_timer.timeout.connect(_on_rearm_timeout)
	damage_timer.timeout.connect(_on_damage_timeout)

	# Crear un temporizador para seguir al jugador durante 5 segundos
	follow_timer = Timer.new()
	follow_timer.one_shot = true
	follow_timer.wait_time = 5.0
	follow_timer.timeout.connect(_on_follow_timeout)
	add_child(follow_timer)

func _physics_process(_delta: float) -> void:
	# Si hay un objetivo a seguir
	if target_to_follow and follow_timer.time_left > 0:
		var offset_target = target_to_follow.global_position + Vector2(0, 10)
		player_speed = target_to_follow.SPEED
		global_position = global_position.move_toward(offset_target, player_speed)
	
	# Si el objetivo a seguir está muerto no lo sigue
	if target_to_follow and target_to_follow.muriendo:
		target_to_follow = null

	if trap_used:
		return  # no hacer nada si la trampa ya fue usada

	var bodies = detector.get_overlapping_bodies()
	var has_target = false

	for b in bodies:
		if b.is_in_group("player") or b.has_method("repeler_balas"):
			has_target = true
			break

	if has_target:
		if rearm_timer.is_stopped() and damage_timer.is_stopped():
			rearm_timer.start()
			anim.play("damage")
	else:
		if is_dealing_damage:
			damage_timer.stop()
			is_dealing_damage = false
			anim.play("defuse")
		elif not rearm_timer.is_stopped():
			rearm_timer.stop()
			anim.play("defuse")

func _on_rearm_timeout() -> void:
	if damage_timer.is_stopped():
		damage_timer.start()

func _on_damage_timeout() -> void:
	var did_damage = false

	if trap_used:
		return

	for body in detector.get_overlapping_bodies():
		if (body.is_in_group("player") or body.has_method("repeler_balas")):
			if body.health <= 0:
				continue
			if body.has_method("take_damage") and not body.escudo_activo:
				body.take_damage(damage_amount)
				body.slow_for(5.0, 0.4)  # ralentizar durante 5 segundos
				did_damage = true
				target_to_follow = body  # guardar referencia para seguir
				follow_timer.start()    # empezar a seguir al jugador

	if did_damage:
		anim.play("damage")
		anim.play("following")
		damage_timer.stop()
		trap_used = true
		await get_tree().create_timer(5.0).timeout
		
		_disable_trap()  # desactivar trampa permanentemente
	else:
		damage_timer.stop()
		anim.play("defuse")

func _on_follow_timeout() -> void:
	target_to_follow = null  # dejar de seguir al jugador

func _disable_trap() -> void:
	detector.monitoring = false
	rearm_timer.stop()
	damage_timer.stop()
	anim.visible = false
