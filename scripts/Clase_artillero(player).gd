extends CharacterBody2D

const DeathAnimation: PackedScene = preload("res://escenas/VFX/death_animation.tscn")
const BearTrapScene = preload("res://escenas/Trampas/bear_trap.tscn")

@export var SPEED:float = 100.0
@export var SPEED_DEFAULT = 100.0
@export var SPEED_DASH = 300.0
@export var active_slows: Array = []
@export var remainingHP = GameManager.vidas

var DEADZONE := 0.2
var escudo_activo:bool = false
var puede_activar_escudo = true
var activar_dash: bool = true
var max_health = 20
var health = 20
var player_id: int
var danio_default = 2
var traps_used = []

var death_sentences_player: Array = [""]
var death_sentences_enemies: Array = [""]
var death_sentences_executions: Array = [""]
var muriendo = false
var is_invulnerable: bool = false
var original_gun: String = "Vacio"

var cooldown_escudo: float = 1.25
var eliminado = false

var afecta_daga = true
var original_frames: SpriteFrames

# Gestión de armas
var arma_secundaria
var weapons: Array[String] = []
var arma_actual: int = 0
var last_cambiar_arma = false

var polimorf: bool = false
var en_polimorf: bool = false
@export var textura: SpriteFrames

signal health_changed(new_health)

@onready var animaciones:AnimatedSprite2D = $AnimatedSprite2D
@onready var escudo = $Escudo
@onready var escudo_sprite = $Escudo/Sprite2D
@onready var arma = $Gun
@onready var ammolabel = $AmmoLabel
@onready var reloadlabel = $ReloadLabel
@onready var liveslabel = $RemainingHP
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var detector: Area2D = $PolimorfExplosion

# Auras de potenciadores
@onready var auraDamage = $AuraDamage
@onready var auraSpeed = $AuraSpeed
@onready var auraHeal = $AuraHeal
@onready var speedTimer  = $SpeedTimer
@onready var damageTimer = $DamageTimer
@onready var healTimer   = $HealTimer
@onready var dashTimer = $DashTimer
@onready var dashCD = $ActivarDash
@onready var timer_trap = $Timer_trap
@onready var cuack_timer = $Cuack_timer

var cd_trap : bool = false

@onready var audio_polimorf := AudioStreamPlayer.new()
@onready var audio_escudo := AudioStreamPlayer.new()

func _ready():
	escudo.process_mode = Node.PROCESS_MODE_PAUSABLE
	visibility_layer = 1 << player_id
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id

	cambiar_arma("gun")
	original_gun = "gun"
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

	#print("Vidas" + str(GameManager.vidas))


func get_shooter_id() -> int:
	return player_id
	
func get_escudo_activo() -> bool:
	return escudo_activo

func generar_frase_pvp(asesino_id: int, victima_id: int, tipo_muerte: String) -> String:
	var frases = [
		"Jugador %d humilló al jugador %d con un %s." % [asesino_id, victima_id, tipo_muerte],
		"%s letal de jugador %d a jugador %d. ¡Sin misericordia!" % [tipo_muerte.capitalize(), asesino_id, victima_id],
		"Jugador %d le enseñó a %d quién manda en el campo de batalla (usando un %s)." % [asesino_id, victima_id, tipo_muerte],
		"%s brutal por parte de jugador %d. Jugador %d ha caído." % [tipo_muerte.capitalize(), asesino_id, victima_id],
		"Jugador %d borró a %d del mapa con un %s." % [asesino_id, victima_id, tipo_muerte],
		"%d no tuvo oportunidad ante el ataque de %d (%s)." % [victima_id, asesino_id, tipo_muerte],
		"Jugador %d: 1 — Jugador %d: 0. Causa: %s." % [asesino_id, victima_id, tipo_muerte],
	]

	return frases[randi() % frases.size()]

func generar_frase_muerte(tipo_enemigo: String, tipo_muerte: String) -> String:
	var frases = [
		"Jugador con ID: %d fue derrotado por un %s (%s fatal)." % [player_id, tipo_enemigo, tipo_muerte],
		"¡El jugador %d fue eliminado sin piedad por un %s con un %s!" % [player_id, tipo_enemigo, tipo_muerte],
		"Un %s ha acabado con el jugador %d usando un %s." % [tipo_enemigo, player_id, tipo_muerte],
		"%s mortal de un %s al jugador %d. ¡Descanse en paz!" % [tipo_muerte.capitalize(), tipo_enemigo, player_id],
		"Jugador %d cayó ante un %s. Causa: %s." % [player_id, tipo_enemigo, tipo_muerte],
		"Fin del juego para el jugador %d... cortesía de un %s (%s)." % [player_id, tipo_enemigo, tipo_muerte],
	]

	return frases[randi() % frases.size()]

func take_damage(amount: float, autor: int = 0, tipo_enemigo: String = "Jugador", tipo_muerte: String = "Disparo") -> void:

	if is_invulnerable:
		return

	if muriendo:
		return

	if !muriendo:
		health = clamp(health - amount, 0, max_health)
		
		animaciones.modulate = Color(1,0,0)
		# Espera 0.05 segundos
		await get_tree().create_timer(0.05).timeout
		# Vuelve al color normal
		animaciones.modulate = Color(1, 1, 1)
		
		emit_signal("health_changed", health)

		if health <= 0:
			muriendo = true

			# Deshabilitamos colisión y sprite
			collision.call_deferred("set_disabled", true)
			animaciones.visible = false

			set_physics_process(false)

			# Guardamos el player_id antes de eliminar al jugador
			var id_guardado = player_id
			# Guardamos el player_id en GameManager para que pueda ser utilizado al respawnear
			GameManager.guardar_id_jugador(id_guardado)
			
			if autor != 0 and autor != 5:
				print(generar_frase_pvp(autor, player_id, tipo_muerte))

			elif autor == 5:
				print("Trampeado xd")

			else:
				print(generar_frase_muerte(tipo_enemigo, tipo_muerte))

			if not eliminado:
				GameManager.register_kill(autor,player_id)
				eliminado = true
			GameManager.jugador_muerto()

			# Mostramos los efectos de muerte
			var death_FX = DeathAnimation.instantiate()
			# La situamos donde estaba el jugador al morir
			death_FX.global_position = global_position
			var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
			world.add_child(death_FX)

			if weapons.size() > 1:
				arma_secundaria.desaparecer()
				arma_secundaria.set_process(false)
			arma.desaparecer()
			arma.set_process(false)
			await get_tree().create_timer(2.0).timeout

			# Reaparecemos en un lugar
			_respawn_in_place()

func heal(amount: float) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)

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
				if Input.is_joy_button_pressed(dispositivo, 9):
					explotar()
	else:
		# Escudo
		if usar_escudo:
			activar_escudo()
		else:
			desactivar_escudo()
			
		# Animaciones (opcional)
		if velocity.length() > 0:
			animaciones.play("artillero_run")
			animaciones.flip_h = velocity.x < 0
		else:
			animaciones.play("artillero_idle")
		
		# Falta modificar todavia !!!!
		if cambiar_arma and (len(weapons) > 1):
			if arma_actual == 0:
				inutilizar_arma(arma)
				recuperar_arma(arma_secundaria)
				arma_actual = 1
			else:
				inutilizar_arma(arma_secundaria)
				recuperar_arma(arma)
				arma_actual = 0
		
		for idx in range(traps_used.size() - 1, -1, -1):
			var trap = traps_used[idx]
			if not is_instance_valid(trap):
				traps_used.remove(idx)
		
		if usar_habilidad:
			if traps_used.size() > 3:
				traps_used.front().queue_free()
				traps_used.pop_front()

			if traps_used.size() <= 3 and not cd_trap:
				var new_trap = BearTrapScene.instantiate()
				new_trap.owner_id = player_id
				new_trap.global_position = global_position
				traps_used.append(new_trap)
				var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
				world.add_child(new_trap)
				cd_trap = true
				timer_trap.start()
		
		# Dash del jugador, le aumenta la velocidad respecto al Timer
		if usar_dash and activar_dash:
			SPEED = SPEED_DASH
			activar_dash = false
			dashTimer.start()
			dashCD.start()

func activar_escudo():
	if not puede_activar_escudo:
		return

	audio_escudo.play()
	escudo_activo = true
	escudo.visible = true #Muestra el Area2D
	escudo_sprite.visible = true #Muestra sprite
	escudo.monitoring = true
	
	# El escudo se activa un lapso de tiempo
	await get_tree().create_timer(0.75).timeout
	desactivar_escudo()
	
	# Evitamos el spam incluyendo un timer
	puede_activar_escudo = false
	
	# Cooldown visual del escudo
	$Panel/HBoxContainer/AbilityButton/Timer.wait_time = cooldown_escudo
	$Panel/HBoxContainer/AbilityButton.abilityUsed()
	
	# Esperamos 1.25s para recargar el escudo
	await get_tree().create_timer(cooldown_escudo).timeout
	
	puede_activar_escudo = true
	
	

func desactivar_escudo():
	escudo_activo = false
	escudo.visible = false 
	escudo_sprite.visible = false
	escudo.monitoring = false

func cambiar_arma(nuevaArma: String):
	var path = "res://escenas/Armas/%s.tscn" % nuevaArma
	var packed = load(path) as PackedScene # Cargamos la escena en tiempo de ejecución
	if not packed:
		push_error("No se puede cargar la escena: %s" % path)
		return
	
	# Si ya tiene el arma no la coge otra vez
	if nuevaArma == arma.tipo_arma.capitalize():
		return

	var tipo_arma

	if arma:
		tipo_arma = arma.tipo_arma
		arma.queue_free() # Eliminamos el arma anterior
	
	arma = packed.instantiate()  # Asignamos un nuevo arma al jugador
	call_deferred("add_child", arma)


# Función para que se le añada una segunda arma al jugador
func add_weapon(nuevaArma: String) -> void:
	var path = "res://escenas/Armas/%s.tscn" % nuevaArma
	var packed = load(path) as PackedScene # Cargamos la escena en tiempo de ejecución
	if not packed:
		push_error("No se puede cargar la escena: %s" % path)
		return
	
	# Si ya tiene el arma no la coge otra vez
	if nuevaArma == arma.tipo_arma.capitalize():
		return

	if len(weapons) <= 1:
		arma_secundaria = packed.instantiate() # Añadimos un nuevo arma al jugador
		call_deferred("add_child", arma_secundaria)
		inutilizar_arma(arma)
		arma_actual = 1
		weapons.append(nuevaArma)
	else:
		arma_secundaria.queue_free()
		arma_secundaria = packed.instantiate()
		call_deferred("add_child", arma_secundaria)
		inutilizar_arma(arma)
		arma_actual = 1
		weapons.pop_back()
		weapons.append(nuevaArma)
	
		
# Funciones para ocultar el arma secundaria
func inutilizar_arma(weapon: Node2D) -> void:
	weapon.set_process(false)
	
	if weapon.has_node("Sprite2D"):
		weapon.get_node("Sprite2D").visible = false

	if weapon.tipo_arma == "Sniper" and weapon.has_node("Line2D"):
		weapon.get_node("Line2D").visible = false

	if weapon.has_node("AnimationPlayer"):
		var anim_player := weapon.get_node("AnimationPlayer") as AnimationPlayer
		anim_player.stop()
		anim_player.set_process(false)

	if weapon.has_node("Espada"):
		var espada := weapon.get_node("Espada") as Area2D
		# DEFERRED para no interferir con el flush de física
		espada.call_deferred("set_monitoring", false)
		espada.call_deferred("set_process", false)
		espada.call_deferred("set_visible", false)

		if espada.has_node("CollisionShape2D"):
			var col_shape := espada.get_node("CollisionShape2D") as CollisionShape2D
			# desactivar la forma de colisión deferred
			col_shape.call_deferred("set_disabled", true)

	# Si tienes timers o más nodos hijos, haz lo mismo:
	if weapon.has_node("Timer"):
		var timer := weapon.get_node("Timer") as Timer
		timer.stop()
		timer.call_deferred("set_process", false)

	if weapon.has_node("AltTimer"):
		var alt_timer := weapon.get_node("AltTimer") as Timer
		alt_timer.stop()
		alt_timer.call_deferred("set_process", false)

func recuperar_arma(weapon: Node2D) -> void:
	# 1) Reactiva el processing del nodo principal
	weapon.set_process(true)

	# 2) Reactivamos la capacidad de disparo
	if weapon.tipo_arma == "Gun" or weapon.tipo_arma == "Sniper" or weapon.tipo_arma == "Shotgun" or weapon.tipo_arma == "polimorf":
		weapon.puedoDisparar = true
	
	if weapon.tipo_arma == "grenade_launcher":
		weapon.can_throw_grenade = true
		weapon.can_throw_grenade_disperse = true

	# 3) Vuelve a mostrar el sprite
	if weapon.has_node("Sprite2D"):
		weapon.get_node("Sprite2D").visible = true

	# 4) Reactiva la línea del sniper si la hubiera
	if weapon.tipo_arma == "Sniper" and weapon.has_node("Line2D"):
		weapon.get_node("Line2D").visible = true

	# 5) Reactiva el AnimationPlayer del arma
	if weapon.has_node("AnimationPlayer"):
		var anim_player := weapon.get_node("AnimationPlayer") as AnimationPlayer
		anim_player.call_deferred("set_process", true)
		# (Opcional) Reproducir animación de idle
		if anim_player.has_animation("Idle"):
			anim_player.call_deferred("play", "Idle")
	
	# 6) Reactiva la parte de la espada
	if weapon.has_node("Espada"):
		var espada := weapon.get_node("Espada") as Area2D

		# Reactiva colisiones y visibilidad del área
		espada.call_deferred("set_monitoring", true)
		espada.call_deferred("set_process", true)
		espada.call_deferred("set_visible", true)

		# Habilita de nuevo la forma de colisión
		if espada.has_node("CollisionShape2D"):
			var col_shape := espada.get_node("CollisionShape2D") as CollisionShape2D
			col_shape.call_deferred("set_disabled", false)

		# 7) Reactiva los timers y resetea los flags
		if weapon.has_node("Timer"):
			var timer := weapon.get_node("Timer") as Timer
			timer.stop()  # para asegurar
			timer.call_deferred("set_process", true)
		if weapon.has_node("AltTimer"):
			var alt_timer := weapon.get_node("AltTimer") as Timer
			alt_timer.stop()
			alt_timer.call_deferred("set_process", true)

		# 8) Reset de los flags de disponibilidad de ataque
		if weapon.has_method("reset_attack_flags"):
			weapon.call_deferred("reset_attack_flags")
		else:
			# Si no tienes un método, por ejemplo reasignamos directamente:
			weapon.set("listo", true)
			weapon.set("listo_alt", true)

func aplicar_potenciador(tipo:String):
	match tipo:
		"speed":
			SPEED *= 1.25
			auraSpeed.emitting = true
			speedTimer.start(10.0)
			SPEED = SPEED_DEFAULT

		"health":
			heal(5)
			auraHeal.emitting = true
			healTimer.start(0.65)

		"damage":
			danio_default = arma.DANIO
			arma.DANIO *= 1.5
			auraDamage.emitting = true
			damageTimer.start(10.0)
			arma.DANIO = danio_default

#Funciones para cuando entramos en el area del enemigo de fuego
func aplicar_quemadura() -> void:
	auraDamage.emitting = true

func quitar_quemadura() -> void:
	auraDamage.emitting = false

# Funcion para el arma de polimorf
func cambiar_apariencia(_textura: SpriteFrames) -> void:
	if not en_polimorf:
		animaciones.sprite_frames = textura
		animaciones.play("idle")
		en_polimorf = true
		SPEED = 50
	
func revertir_apariencia() -> void:
	animaciones.sprite_frames = original_frames
	polimorf = false
	en_polimorf = false
	SPEED = SPEED_DEFAULT

func _respawn_in_place() -> void:
	remainingHP -= 1
	if remainingHP == 0:
		GameManager.dead_player()
		emit_signal("perma_death", player_id)
		return
	remaining_hp()
	eliminado = false
	# Restauramos estado
	health = max_health
	emit_signal("health_changed", health)
	global_position = GameManager.get_spawn_point()  # obtiene Vector2
	active_slows.clear()
	_update_speed()

	is_invulnerable = true
	animaciones.visible = true
	collision.disabled = false
	
	if weapons.size() > 1:
		arma_secundaria.aparecer()
		arma_secundaria.set_process(true)
	arma.aparecer()
	arma.set_process(true)
	set_physics_process(true)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < 0.8 and weapons.size() > 1:  
		arma_actual = 0
		weapons.pop_back()
		arma_secundaria.queue_free()
		# add_weapon(original_gun)

	await get_tree().create_timer(2.0).timeout
	is_invulnerable = false
	muriendo = false

# Al expirar cada timer, apagamos la correspondiente aura
func _on_speed_timeout():
	auraSpeed.emitting = false

func _on_damage_timeout():
	auraDamage.emitting = false

func _on_heal_timeout():
	auraHeal.emitting = false

func _on_polimorf_timeout() -> void:
	revertir_apariencia()

func slow_for(duration: float, slow_amount: float) -> void:
	var slow_effect = {
		"duration": duration,
		"amount": slow_amount
	}
	active_slows.append(slow_effect)
	_update_speed()
	# Crear un temporizador independiente para remover el efecto después de su duración
	var slow_timer := Timer.new()
	slow_timer.one_shot = true
	slow_timer.wait_time = duration
	add_child(slow_timer)
	slow_timer.timeout.connect(func():
		active_slows.erase(slow_effect)
		_update_speed()
		slow_timer.queue_free()
	)
	slow_timer.start()

func _update_speed() -> void:

	var speed_factor := 1.0
	for s in active_slows:
		speed_factor *= (1.0 - s.amount)

	speed_factor = clamp(speed_factor, 0.1, 1.0)  # mínimo 10% de la velocidad
	SPEED = SPEED_DEFAULT * speed_factor

# Timers para el dash
func _on_dash_timer_timeout() -> void:
	# SPEED = SPEED_DEFAULT
	_update_speed()

func _on_activar_dash_timeout() -> void:
	activar_dash = true

func actualizar_ammo_label() -> void:
	# Cambia "Munición: %d" por el texto que prefieras.
	if arma_actual == 0:
		if arma.municion == INF:
			ammolabel.text = "INF"
		else:
			ammolabel.text = "%d/%d" % [arma.municion, arma.MAX_AMMO]
	else: 
		if arma_secundaria.tipo_arma != "sword":
			ammolabel.text = "%d/%d" % [arma_secundaria.municion, arma_secundaria.MAX_AMMO]
		else:
			ammolabel.text = "INF"

func recarga_ammo_label() -> void:
	ammolabel.visible = false
	reloadlabel.visible = true
	await get_tree().create_timer(2.0).timeout
	ammolabel.visible = true
	reloadlabel.visible = false

func remaining_hp()-> void:
	if remainingHP > 10:
		return
	
	liveslabel.visible = true
	liveslabel.text = "%d" % remainingHP
	await get_tree().create_timer(2.0).timeout
	liveslabel.visible = false

signal perma_death(player_id)

func _on_cd_trap_timeout() -> void:
	cd_trap = false

func _on_cuack_timer_timeout() -> void:
	audio_polimorf.play()


func explotar() -> void:
	if muriendo:
		return

	# Aquí puedes añadir efectos visuales o eliminar el nodo si es necesario
	var death_FX = DeathAnimation.instantiate()
	death_FX.global_position = global_position
	var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
	world.add_child(death_FX)
	death_FX._play_vfx(2)

	for body in detector.get_overlapping_bodies():
		if body.has_method("take_damage"):
			if body.is_in_group("player") and body.player_id != player_id:
				body.take_damage(20, player_id, "jugador", "explosión")
				print("Hola")
			if !body.is_in_group("player"):
				body.take_damage(20, player_id, "jugador", "explosión")
	
	take_damage(max_health, player_id, "jugador", "explosion")
	polimorf = false
