extends "Clase_artillero(player).gd"

@export var Grenade: PackedScene = preload("res://escenas/Modelos base (mapas y player)/granada.tscn")
@export var grenade_cooldown: float = 3.0
@export var max_grenade_distance: float = 200.0
var _can_throw_grenade: bool = true

func _ready() -> void:
	escudo.process_mode = Node.PROCESS_MODE_PAUSABLE
	visibility_layer = 1 << player_id
	SPEED = 75.0
	SPEED_DEFAULT = 75.0
	SPEED_DASH = 200.0
	max_health = 30
	health = 30
	cooldown_escudo = 2.5
	dashCD.wait_time = 3.5
	
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id

	cambiar_arma("shotgun")
	original_gun = "shotgun"
	arma.set_municion(INF)
	weapons.append(original_gun)
	
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

	add_child(audio_polimorf)
	audio_polimorf.stream = preload("res://audio/polimorfed_duck.mp3")
	audio_polimorf.bus = "SFX"
	audio_polimorf.volume_db = +15.0

	add_child(audio_escudo)
	audio_escudo.stream = preload("res://audio/shield.mp3")
	audio_escudo.bus = "SFX"
	audio_escudo.volume_db = -5.0

func _physics_process(_delta: float) -> void:

	var usar_escudo := false
	var usar_dash := false
	var usar_habilidad := false
	var cambiar_arma := false
	actualizar_ammo_label()
	var dispositivo = GameManager.get_device_for_player(player_id)

	if dispositivo == null:
		# JUGADOR CON TECLADO
		var directionX := Input.get_axis("left", "right")
		var directionY := Input.get_axis("up", "down")

		velocity.x = directionX * SPEED
		velocity.y = directionY * SPEED
		
		usar_escudo = Input.is_action_pressed("shield")
		usar_dash = Input.is_action_pressed("dash")
		usar_habilidad = Input.is_action_just_pressed("second_ability")
		cambiar_arma = Input.is_action_just_pressed("switch_weapons")
		
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

		usar_escudo = Input.is_joy_button_pressed(dispositivo, 9)
		usar_dash = Input.is_joy_button_pressed(dispositivo, 2)
		usar_habilidad = Input.is_joy_button_pressed(dispositivo, 10)

		var current := Input.is_joy_button_pressed(dispositivo, 1)
		# Si ahora está presionado y antes no, es “just pressed”
		if current and not last_cambiar_arma:
			cambiar_arma = true
		# Actualizamos historial
		last_cambiar_arma = current

	if polimorf:
		if not en_polimorf:
			cambiar_apariencia(textura)
			$Polimorf.start()
			cuack_timer.start()
		else:
			if velocity.length() > 0:
				animaciones.play("run")
				animaciones.flip_h = velocity.x > 0
			else:
				animaciones.play("idle")

			if dispositivo == null:
				if Input.is_action_just_pressed("shield"):
					explotar()
			else:
				if Input.is_action_just_pressed(dispositivo, 10):
					explotar()
	else:
		# Escudo
		if usar_escudo:
			activar_escudo()
		else:
			desactivar_escudo()
			
		# Animaciones (opcional)
		if velocity.length() > 0:
			animaciones.play("asalto_run")
			animaciones.flip_h = velocity.x < 0
		else:
			animaciones.play("asalto_idle")
			
		if cambiar_arma and (len(weapons) > 1):
			if arma_actual == 0:
				inutilizar_arma(arma)
				recuperar_arma(arma_secundaria)
				arma_actual = 1
			else:
				inutilizar_arma(arma_secundaria)
				recuperar_arma(arma)
				arma_actual = 0
				
	if usar_habilidad and _can_throw_grenade:
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
		grenade.global_position = global_position
		grenade.owner_id = player_id
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(grenade)
		grenade.throw_to(target)
		# cooldown
		_can_throw_grenade = false
		await get_tree().create_timer(grenade_cooldown).timeout
		_can_throw_grenade = true

	# Dash del jugador, le aumenta la velocidad respecto al Timer
	if usar_dash and activar_dash:
		SPEED = SPEED_DASH
		activar_dash = false
		dashTimer.start()
		$ActivarDash.start()

	# Movimiento real
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.1)
	move_and_slide()

func activar_escudo():
	if not puede_activar_escudo:
		return

	escudo_activo = true
	escudo.visible = true #Muestra el Area2D
	escudo_sprite.visible = true #Muestra sprite
	escudo.monitoring = true
	
	# El escudo se activa un lapso de tiempo
	await get_tree().create_timer(1.5).timeout
	desactivar_escudo()
	
	# Evitamos el spam incluyendo un timer
	puede_activar_escudo = false
	
	# Cooldown visual del escudo
	$Panel/HBoxContainer/AbilityButton/Timer.wait_time = cooldown_escudo
	$Panel/HBoxContainer/AbilityButton.abilityUsed()
	
	# Esperamos 2.5 s para recargar el escudo
	await get_tree().create_timer(cooldown_escudo).timeout
	
	puede_activar_escudo = true
	
func aplicar_potenciador(tipo:String):
	match tipo:
		"speed":
			SPEED *= 1.25
			auraSpeed.emitting = true
			speedTimer.start(10.0)
			SPEED = SPEED_DEFAULT

		"health":
			heal(10)
			auraHeal.emitting = true
			healTimer.start(0.65)

		"damage":
			danio_default = arma.DANIO
			arma.DANIO *= 1.5
			auraDamage.emitting = true
			damageTimer.start(10.0)
			arma.DANIO = danio_default
