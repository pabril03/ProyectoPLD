extends CharacterBody2D

@export var SPEED:float = 100.0
var escudo_activo:bool = false
var puede_activar_escudo = true
var max_health = 20
var health = 20
var player_id: int

signal health_changed(new_health)


@onready var animaciones:AnimatedSprite2D = $AnimatedSprite2D
@onready var escudo = $Escudo
@onready var escudo_sprite = $Escudo/Sprite2D


func _ready():
	#collision_layer = 3  # Establece un valor que no se use para las balas
	#collision_mask = 1 | 2   # Establece las capas con las que el jugador debe colisionar.
	emit_signal("health_changed", health)
	#Nuevas funciones para registrar jugador en el juego (sirve para colisiones)
	GameManager.registrar_jugador(self)
	#print(player_id)
	collision_layer = 2  # Layer 2, 3, 4 o 5
	collision_mask = 1
	escudo.escudo_id = player_id
	

func get_shooter_id() -> int:
	return player_id
	
func get_escudo_activo() -> bool:
	return escudo_activo

func take_damage(amount: float) -> void:
	health = clamp(health - amount, 0, max_health)
	emit_signal("health_changed", health)
	
	if health <= 0:
		# Guardamos el player_id antes de eliminar al jugador
		var id_guardado = player_id
		#print(id_guardado)
		queue_free()
		# Guardamos el player_id en GameManager para que pueda ser utilizado al respawnear
		GameManager.guardar_id_jugador(id_guardado)
	
func heal(amount: float) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)

func _physics_process(_delta: float) -> void:
	
	if get_global_mouse_position().x < global_position.x:
		animaciones.flip_h = true
	else:
		animaciones.flip_h = false
	
	var directionX := Input.get_axis("left", "right")
	var directionY := Input.get_axis("up", "down")
	#Aplicar fuerza
	if directionX:
		velocity.x = directionX * SPEED
		animaciones.play("run")
		if directionX > 0:
			animaciones.flip_h = false
		else:
			animaciones.flip_h = true
			
	else:
		animaciones.play("default")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if directionY:
		velocity.y = directionY * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	velocity.normalized()
	
	move_and_slide()
	
	if Input.is_action_pressed("shield"):
		activar_escudo()
	else:
		desactivar_escudo()
	

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

func configurar_colisiones():
	# Cada jugador se pone en su propia capa: capa = 1 << player_id
	set_collision_layer_value(player_id + 1, true)  # player_id 0 → capa 1, etc.

	# Máscara: colisionar con todas las capas de otros jugadores
	for i in range(4):
		set_collision_mask_value(i + 1, i != player_id)
