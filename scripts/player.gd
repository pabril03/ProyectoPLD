extends CharacterBody2D

@export var SPEED:float = 50.0

@onready var animaciones:AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	
	var direction := Vector2.ZERO
	
	if get_global_mouse_position().x < global_position.x:
		animaciones.flip_h = true
	else:
		animaciones.flip_h = false
	
	if Input.is_action_pressed("left"):
		direction.x -= 1
		animaciones.flip_h = true
	if Input.is_action_pressed("right"):
		direction.x += 1
		animaciones.flip_h = false
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	
	velocity = direction * SPEED
	
	if direction:
		animaciones.play("run")
	else:
		animaciones.play("default")
	
	velocity.normalized()
	
	move_and_slide()
	
