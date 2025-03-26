extends StaticBody2D

@export var VIDA:int = 20

func _process(delta: float) -> void:
	if(VIDA <= 0):
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("balas"):  # Asegura que solo las balas bajen la vida
		VIDA -= 2
		print("Vida restante:", VIDA)
		body.queue_free()  # Destruye la bala tras impactar
	
