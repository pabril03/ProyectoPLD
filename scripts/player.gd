extends CharacterBody2D

const DeathAnimation: PackedScene = preload("res://escenas/death_animation.tscn")

@export var SPEED:float = 100.0
var SPEED_DEFAULT = 100.0
var DEADZONE := 0.2
var escudo_activo:bool = false
var puede_activar_escudo = true
var max_health = 20
var health = 20
var player_id: int
var danio_default = 2

var death_sentences_player: Array = [""]
var death_sentences_enemies: Array = [""]
var death_sentences_executions: Array = [""]
var muriendo = false
var is_invulnerable: bool = false
var original_gun: String = "Vacio"

signal health_changed(new_health)

@onready var animaciones:AnimatedSprite2D = $AnimatedSprite2D
@onready var escudo = $Escudo
@onready var escudo_sprite = $Escudo/Sprite2D
@onready var arma = $Gun
@onready var collision: CollisionShape2D = $CollisionShape2D

# Auras de potenciadores
@onready var auraDamage = $AuraDamage
@onready var auraSpeed = $AuraSpeed
@onready var auraHeal = $AuraHeal
@onready var speedTimer  = $SpeedTimer
@onready var damageTimer = $DamageTimer
@onready var healTimer   = $HealTimer


func _ready():
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	collision_mask = 1
	escudo.escudo_id = player_id
	arma.dispositivo = GameManager.get_device_for_player(player_id) # null = teclado/rató, int = joy_id
	
	match GameManager.clases[player_id - 1]:
		"Artillero":
			cambiar_arma("gun")
			original_gun = "gun"
		"Sniper":
			cambiar_arma("francotirador")
			original_gun = "francotirador"
	
	for aura in [auraDamage, auraSpeed, auraHeal]:
		aura.emitting = false
	
	speedTimer.one_shot = true
	damageTimer.one_shot = true
	healTimer.one_shot = true
	speedTimer.timeout.connect(_on_speed_timeout)
	damageTimer.timeout.connect(_on_damage_timeout)
	healTimer.timeout.connect(_on_heal_timeout)

	muriendo = false

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

func take_damage(amount: float, autor: int = 2, tipo_enemigo: String = "Jugador", tipo_muerte: String = "Disparo") -> void:
	if is_invulnerable:
		return

	if !muriendo:
		health = clamp(health - amount, 0, max_health)
		emit_signal("health_changed", health)

		if health <= 0:
			muriendo = true
			emit_signal("died", player_id)

			# Deshabilitamos colisión y sprite
			collision.disabled = true
			animaciones.visible = false

			set_physics_process(false)

			# Guardamos el player_id antes de eliminar al jugador
			var id_guardado = player_id
			# Guardamos el player_id en GameManager para que pueda ser utilizado al respawnear
			GameManager.guardar_id_jugador(id_guardado)
			
			if tipo_enemigo == "Jugador":
				print(generar_frase_pvp(autor, player_id, tipo_muerte))

			elif tipo_enemigo == "Trap":
				print("Trampeado xd")

			else:
				print(generar_frase_muerte(tipo_enemigo, tipo_muerte))
				
			GameManager.jugador_muerto()
			# GameManager.arma_soltada( arma.tipo_arma )

			# Mostramos los efectos de muerte
			var death_FX = DeathAnimation.instantiate()
			# La situamos donde estaba el jugador al morir
			death_FX.global_position = global_position
			var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
			world.add_child(death_FX)

			var rng = RandomNumberGenerator.new()
			rng.randomize()
			if rng.randf() < 0.8:  
				cambiar_arma(original_gun)

			arma.desaparecer()
			arma.set_process(false)

			# Reaparecemos en un lugar
			_respawn_in_place()

func heal(amount: float) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)

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

	# Escudo
	if usar_escudo:
		activar_escudo()
	else:
		desactivar_escudo()

	# Animaciones (opcional)
	if velocity.length() > 0:
		animaciones.play("run")
		animaciones.flip_h = velocity.x < 0
	else:
		animaciones.play("default")
		

func activar_escudo():
	if not puede_activar_escudo:
		return

	escudo_activo = true
	escudo.visible = true #Muestra el Area2D
	escudo_sprite.visible = true #Muestra sprite
	escudo.monitoring = true
	
	# El escudo se activa un lapso de tiempo
	await get_tree().create_timer(0.75).timeout
	desactivar_escudo()
	
	# Evitamos el spam incluyendo un timer
	puede_activar_escudo = false
	
	# Esperamos 1.25s para recargar el escudo
	await get_tree().create_timer(1.0).timeout
	puede_activar_escudo = true

func desactivar_escudo():
	escudo_activo = false
	escudo.visible = false 
	escudo_sprite.visible = false
	escudo.monitoring = false

func cambiar_arma(nuevaArma: String):
	var path = "res://escenas/%s.tscn" % nuevaArma
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
		# GameManager.arma_soltada( tipo_arma.capitalize() )
		arma.queue_free() # Eliminamos el arma anterior
	
	arma = packed.instantiate()  # Asignamos un nuevo arma al jugador
	add_child(arma) # Agregamos el nuevo arma a la escena

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

func _respawn_in_place() -> void:

	await get_tree().create_timer(2.0).timeout
	# Restauramos estado
	health = max_health
	emit_signal("health_changed", health)
	global_position = GameManager.get_spawn_point()  # obtiene Vector2

	is_invulnerable = true
	animaciones.visible = true
	collision.disabled = false
	arma.aparecer()
	arma.set_process(true)
	set_physics_process(true)

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

signal died(player_id)
