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
	collision_layer = 3  # Establece un valor que no se use para las balas
	collision_mask = 1 | 2   # Establece las capas con las que el jugador debe colisionar.
	emit_signal("health_changed", health)
	escudo.escudo_id = player_id

func get_shooter_id() -> int:
	return player_id
	
func get_escudo_activo() -> bool:
	return escudo_activo

func take_damage(amount: float) -> void:
	health = clamp(health - amount, 0, max_health)
	emit_signal("health_changed", health)
	
	if health <= 0:
		queue_free()
	
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
