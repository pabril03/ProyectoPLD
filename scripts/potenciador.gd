extends Area2D

@export var tipo_potenciador: String = "health"
@onready var sprite:Sprite2D = $Sprite2D

var spawn_index = -1

func _ready():
	match tipo_potenciador:
		"speed":
			sprite.texture = preload("res://sprites/run.png")
		"health":
			sprite.texture = preload("res://sprites/first-aid-kit.png")
		"damage":
			sprite.texture = preload("res://sprites/bullets.png")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # o si quieres, comprobar el tipo manualmente
		body.aplicar_potenciador(tipo_potenciador)
		#Liberar_spawn es un metodo del main para aplicar un timer para reponer el powerup
		get_parent().liberar_spawn(spawn_index)
		#GameManager.spawn_states[spawn_index] = 0
		queue_free()  # Desaparece el potenciador después de ser recogido
