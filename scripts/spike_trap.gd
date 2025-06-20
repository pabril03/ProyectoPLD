extends "fire_trap.gd"

func _ready() -> void:
	damage_amount = 10
	detector.monitoring = true                             # activar detección :contentReference[oaicite:2]{index=2}
	anim.play("idle")                                      # estado inicial
	rearm_timer.one_shot = true
	damage_timer.one_shot = false
	damage_timer.wait_time = 1.0
	rearm_timer.timeout.connect(_on_rearm_timeout)
	damage_timer.timeout.connect(_on_damage_timeout)

func _physics_process(_delta: float) -> void:
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
		# Si ya no hay targets y está en modo daño, reproducir defuse
		if is_dealing_damage:
			damage_timer.stop()
			is_dealing_damage = false
			anim.play("defuse")
		# Si aún no se armó, parar rearm
		elif not rearm_timer.is_stopped():
			rearm_timer.stop()
			anim.play("idle")

func _on_rearm_timeout() -> void:
	# al armarse, empezar daño periódico
	if damage_timer.is_stopped():
		damage_timer.start()                               # daño cada 1.0 s :contentReference[oaicite:6]{index=6}

func _on_damage_timeout() -> void:
	var did_damage = false
	for body in detector.get_overlapping_bodies():         # lista siempre fresca :contentReference[oaicite:7]{index=7}
		if (body.is_in_group("player") or body.has_method("repeler_balas")):
			if body.health <= 0:
				continue
			if body.has_method("take_damage") and not body.escudo_activo:
				body.take_damage(damage_amount, 5)
				body.slow_for(1.5,0.3)
				did_damage = true
	if did_damage:
		anim.play("damage")
	else:
		damage_timer.stop()
		anim.play("idle")
