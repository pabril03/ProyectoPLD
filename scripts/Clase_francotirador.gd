extends "Clase_artillero(player).gd"

func _ready() -> void:
	SPEED = 120.0
	SPEED_DEFAULT = 120.0
	max_health = 15
	health = 15
	cooldown_escudo = 1.25
	
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id
	
	cambiar_arma("sniper")
	original_gun = "sniper"
	
	for aura in [auraDamage, auraSpeed, auraHeal]:
		aura.emitting = false
	
	speedTimer.one_shot = true
	damageTimer.one_shot = true
	healTimer.one_shot = true
	speedTimer.timeout.connect(_on_speed_timeout)
	damageTimer.timeout.connect(_on_damage_timeout)
	healTimer.timeout.connect(_on_heal_timeout)

	muriendo = false
	original_frames = animaciones.sprite_frames

func _physics_process(_delta: float) -> void:

	var usar_escudo := false
	var dispositivo = GameManager.get_device_for_player(player_id)

	if dispositivo == null:
		# JUGADOR CON TECLADO
		var directionX := Input.get_axis("left", "right")
		var directionY := Input.get_axis("up", "down")

		velocity.x = directionX * SPEED
		velocity.y = directionY * SPEED
		
		usar_escudo = Input.is_action_pressed("shield")
		
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

		# Solo activar escudo si ese jugador pulsa su botón (ej: botón L1 → ID 4 en la mayoría)
		usar_escudo = Input.is_action_pressed("shield_pad")

	# Movimiento real
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.1)
	move_and_slide()

	if polimorf:
		if not en_polimorf:
			cambiar_apariencia(textura)
			$Polimorf.start()
		else:
			if velocity.length() > 0:
				animaciones.play("run")
				animaciones.flip_h = velocity.x > 0
			else:
				animaciones.play("idle")
	else:
		# Escudo
		if usar_escudo:
			activar_escudo()
		else:
			desactivar_escudo()
			
		# Animaciones (opcional)
		if velocity.length() > 0:
			animaciones.play("francotirador_run")
			animaciones.flip_h = velocity.x < 0
		else:
			animaciones.play("francotirador_idle")
		
	

func activar_escudo():
	if not puede_activar_escudo:
		return

	escudo_activo = true
	escudo.visible = true #Muestra el Area2D
	escudo_sprite.visible = true #Muestra sprite
	escudo.monitoring = true
	
	# El escudo se activa un lapso de tiempo
	await get_tree().create_timer(0.5).timeout
	desactivar_escudo()
	
	# Evitamos el spam incluyendo un timer
	puede_activar_escudo = false
	
	# Cooldown visual del escudo
	$Panel/HBoxContainer/AbilityButton/Timer.wait_time = cooldown_escudo
	$Panel/HBoxContainer/AbilityButton.abilityUsed()
	
	# Esperamos 1.25 s para recargar el escudo
	await get_tree().create_timer(cooldown_escudo).timeout
	
	puede_activar_escudo = true
