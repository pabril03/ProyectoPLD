extends "Clase_artillero(player).gd"

@onready var invisibilidad = $Invisibilidad
const LAYER_DEFAULT = 1 << 0       # capa 1: visibilidad normal
var LAYER_INVIS = 0

var _my_viewport_idx: int
var _original_vp_masks := []

func _ready() -> void:
	await get_tree().create_timer(0.05).timeout
	var split = get_tree().current_scene.get_node("SplitScreen2D") as SplitScreen2D
	_my_viewport_idx = split.players.find(self)
	if _my_viewport_idx == -1:
		push_warning("Jugador no registrado en SplitScreen2D.players")
		return

	LAYER_INVIS = 1 << (1 + _my_viewport_idx)

	# Guarda máscara original de todos los viewports
	_original_vp_masks.clear()
	for vp in GameManager.player_viewports:
		_original_vp_masks.append(vp.canvas_cull_mask)
		# Asegúrate de que TU viewport vea ambas capas
		# (default + tu capa invis)
		vp.canvas_cull_mask |= LAYER_DEFAULT | LAYER_INVIS

	SPEED = 150.0
	SPEED_DEFAULT = 150.0
	max_health = 15
	health = 15
	cooldown_escudo = 0.85
	invisibilidad.visible = false
	
	
	# El jugador se ve siempre a sí mismo aunque sea invisible
	var player_viewport = get_parent().get_parent()
	player_viewport.canvas_cull_mask |= (1 << player_id)
	
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id

	cambiar_arma("sword")
	original_gun = "sword"
	
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
			animaciones.play("rogue_run")
			animaciones.flip_h = velocity.x < 0
		else:
			animaciones.play("rogue_idle")
		
		if cambiar_arma and (len(weapons) > 1):
			if arma_actual == 0:
				inutilizar_arma(arma)
				recuperar_arma(arma_secundaria)
				arma_actual = 1
			else:
				inutilizar_arma(arma_secundaria)
				recuperar_arma(arma)
				arma_actual = 0
		
	if usar_habilidad:
		activar_invisibilidad()
		

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
	await get_tree().create_timer(1.0).timeout
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

func activar_invisibilidad():
	# 1) Activa tu efecto visual
	invisibilidad.visible = true

	# 2) Cambia tu layer a la capa de invisibilidad
	visibility_layer = LAYER_INVIS

	# 3) Quita esa capa de los demás viewports
	for i in GameManager.player_viewports.size():
		if i == _my_viewport_idx:
			continue
		var vp: SubViewport = GameManager.player_viewports[i]
		vp.canvas_cull_mask = _original_vp_masks[i] & ~LAYER_INVIS

	# 4) Espera
	await get_tree().create_timer(1.5).timeout

	# 5) Desactiva tu efecto
	invisibilidad.visible = false

	# 6) Vuelve a la capa default
	visibility_layer = LAYER_DEFAULT

	# 7) Restaura todas las máscaras originales
	for i in GameManager.player_viewports.size():
		GameManager.player_viewports[i].canvas_cull_mask = _original_vp_masks[i]
