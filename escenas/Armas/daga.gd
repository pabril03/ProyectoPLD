extends Area2D

var target_position: Vector2
var return_position: Vector2
var speed: float = 250.0
var returning: bool = false
var active: bool = false
var final: bool = false

func _ready() -> void:
	for layer in range(1, 5):
		collision_mask |= 1 << layer

func _process(delta: float) -> void:
	if not active:
		return
	
	if returning:
		global_position = global_position.move_toward(return_position, speed * delta)
		if global_position.distance_to(return_position) < 5:
			active = false
			returning = false
			final = true
	else:
		global_position = global_position.move_toward(target_position, speed * delta)
		if global_position.distance_to(target_position) < 10:
			returning = true
			final = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		if body.afecta_daga:
			body.take_damage(get_parent().damage_on_touch, get_parent().enemy_id, "asesino", "apuñalada")
			body.afecta_daga = false


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.afecta_daga = true
