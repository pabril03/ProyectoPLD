extends "Clase_artillero(player).gd"

@onready var teleport = preload("res://escenas/Trampas/teletransportador.tscn")

var tp_activo : bool = false
var tepear : bool = false
var id_tp : int = -1
var colocados : bool = false

var teleport1: Node2D = null
var teleport2: Node2D = null
var tp_timer


func _ready() -> void:
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

func _physics_process(_delta: float) -> void:

	var usar_escudo := false
	var usar_dash := false
	var usar_habilidad := false
	var cambiar_arma := false
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
		cambiar_arma = Input.is_action_just_pressed("switch_weapons_p1")
		
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
		usar_dash = Input.is_action_pressed("dash_pad")
		usar_habilidad = Input.is_action_just_pressed("second_ability_pad")
		cambiar_arma = Input.is_action_just_pressed("switch_weapons_p2")

	# Movimiento real
	velocity = velocity.move_toward(Vector2.ZERO, SPEED * 0.1)
	move_and_slide()
	
	# Condición de teleport, cada 2 segundos. Tepear se pone a true dentro de teletransportador.gd
	if tepear and id_tp != -1 and colocados:
		#print("ENTRO")
		teletransportar()
		tepear = false
		# Si ya existe un timer previo, lo eliminamos
		if tp_timer and tp_timer.is_inside_tree():
			tp_timer.queue_free()
			tp_timer = null

		# Crear nuevo timer
		tp_timer = Timer.new()
		tp_timer.wait_time = 2.0
		tp_timer.one_shot = true
		tp_timer.connect("timeout", Callable(self, "_on_tp_timer_timeout"))
		add_child(tp_timer)
		tp_timer.start()

		# Mientras tanto, impedir nuevo teletransporte
		teleport1.tp_cooldown = true
		teleport2.tp_cooldown = true

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
		if usar_habilidad:
			if tp_activo and teleport1 and teleport2:
				if teleport1.parar and teleport2.parar:
					teleport1.queue_free()
					teleport2.queue_free()
					tp_activo = false
					colocados = false
					if tp_timer:
						tp_timer.queue_free()
			
			# Si no hay teleports activos, se crean
			if not tp_activo:
				teleport1 = teleport.instantiate()
				teleport2 = teleport.instantiate()
				teleport1.global_position = global_position
				teleport1.id = 1
				teleport2.global_position = global_position
				teleport2.id = 2
				var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
				world.add_child(teleport1)
				world.add_child(teleport2)
				
				teleport1.parar = true
				tp_activo = true
			# Cuando se coloca el segundo teleport con la E, fija la posicion del segundo teleport
			else:
				teleport2.parar = true
				colocados = true
		
		# Dash del jugador, le aumenta la velocidad respecto al Timer
		if usar_dash and activar_dash:
			SPEED = SPEED_DASH
			activar_dash = false
			dashTimer.start()
			$ActivarDash.start()

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

func teletransportar():
	if id_tp == 1:
		global_position = teleport2.global_position
	else:
		global_position = teleport1.global_position
	teleport1.tp_cooldown = true
	teleport2.tp_cooldown = true

# Cooldown del timer del teleport
func _on_tp_timer_timeout():
	# Cooldown finalizado, permitir nuevo teletransporte
	teleport1.tp_cooldown = false
	teleport2.tp_cooldown = false

	# Eliminar el timer
	if tp_timer and tp_timer.is_inside_tree():
		tp_timer.queue_free()
		tp_timer = null
