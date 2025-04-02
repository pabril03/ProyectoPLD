extends StaticBody2D

@export var VIDA:int = 20
const bala = preload("res://escenas/bala.tscn")

@onready var punta: Marker2D = $Marker2D
var puedoDisparar: bool = true

func _ready() -> void:
	collision_layer = 3
	collision_mask = 1

func _process(delta: float) -> void:
	if(VIDA <= 0):
		queue_free()
		
	disparo()
		
func reducirVida(dano: int):
	VIDA -= dano
	print(VIDA)


func disparo():
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		
		bullet_i.velocity = Vector2.LEFT * bullet_i.SPEED
		bullet_i.rotation_degrees = 180
		puedoDisparar = false


func _on_timer_timeout() -> void:
	puedoDisparar = true
