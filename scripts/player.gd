extends CharacterBody2D

@export var SPEED:float = 300.0

func _physics_process(delta: float) -> void:
	
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	
	velocity = direction * SPEED
	
	velocity.normalized()
	
	move_and_slide()
	
