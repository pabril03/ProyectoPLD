extends CharacterBody2D

@export var speed := 200.0

var direction := Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	update_direction()
	
	if direction.length() > 0.1:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
func update_direction():
	var mouse_target = get_global_mouse_position()
	direction = mouse_target - global_position


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("teletransportar"):
		body.tepear = true
