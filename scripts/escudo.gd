extends Area2D

func _ready() -> void:
	collision_layer = 1  
	collision_mask = 2   # Establece las capas con las que el jugador debe colisionar.

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("balas"):
		repeler_bala(body)

#Método para repeler la bala
func repeler_bala(bala: Node2D) -> void:
	var direction = (bala.global_position - global_position).normalized()
	bala.velocity = direction * bala.SPEED * 1.1
	bala.rotation = bala.velocity.angle()
