extends "Clase_artillero(player).gd"

@onready var teleport = preload("res://escenas/Trampas/teletransportador.tscn")

var tp_activo : bool = false
var tepear : bool = false
var id_tp : int = -1
var colocados : bool = false

var teleport1: Node2D = null
var teleport2: Node2D = null
var cd_tp : bool = false
@onready var timer_teleport = $Cd_teleport

func _ready() -> void:
	escudo.process_mode = Node.PROCESS_MODE_PAUSABLE
	visibility_layer = 1 << player_id
	SPEED = 120.0
	SPEED_DEFAULT = 120.0
	SPEED_DASH = 350.0
	max_health = 15
	health = 15
	cooldown_escudo = 1.25
	dashCD.wait_time = 1.5
	
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id
	
	cambiar_arma("sniper")
	original_gun = "sniper"
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

		usar_escudo = Input.is_joy_button_pressed(dispositivo, 10)
		usar_dash = Input.is_joy_button_pressed(dispositivo, 2)
		usar_habilidad = Input.is_joy_button_pressed(dispositivo, 3)

		var current := Input.is_joy_button_pressed(dispositivo, 1)
		# Si ahora está presionado y antes no, es “just pressed”
		if current and not last_cambiar_arma:
			cambiar_arma = true
		# Actualizamos historial
		last_cambiar_arma = current

	# Movimiento real
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.1)
	move_and_slide()
	

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
			animaciones.play("francotirador_run")
			animaciones.flip_h = velocity.x < 0
		else:
			animaciones.play("francotirador_idle")
		
		#Funcion para cambiar arma
		if cambiar_arma and (len(weapons) > 1):
			if arma_actual == 0:
				inutilizar_arma(arma)
				recuperar_arma(arma_secundaria)
				arma_actual = 1
			else:
				inutilizar_arma(arma_secundaria)
				recuperar_arma(arma)
				arma_actual = 0
		
		# Habilidad de teletransporte (Tecla E)
		if usar_habilidad and not cd_tp:
			# Condición de teleport, cada 2 segundos. Tepear se pone a true dentro de teletransportador.gd
			if tepear:
				#print("ENTRO")
				teletransportar()
				tepear = false
				cd_tp = true
				teleport1.queue_free()
				timer_teleport.start()
				
			else:
				teleport1 = teleport.instantiate()
				teleport1.global_position = global_position
				#teleport1.parar = true
				var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
				world.add_child(teleport1)
				tepear = true
		
		# Dash del jugador, le aumenta la velocidad respecto al Timer
		if usar_dash and activar_dash:
			SPEED = SPEED_DASH
			activar_dash = false
			dashTimer.start()
			$ActivarDash.start()

func activar_escudo():
	if not puede_activar_escudo:
		return

	audio_escudo.play()

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

func teletransportar():
	global_position = teleport1.global_position
	


func _on_cd_teleport_timeout() -> void:
	cd_tp = false
