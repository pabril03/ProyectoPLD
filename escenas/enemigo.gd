extends StaticBody2D

@export var VIDA:int = 20

func _process(delta: float) -> void:
	if(VIDA <= 0):
		queue_free()
		
func reducirVida(dano: int):
	VIDA -= dano
	print(VIDA)
