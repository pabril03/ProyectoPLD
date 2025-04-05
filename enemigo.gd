extends StaticBody2D

@export var VIDA:int = 20
const bala = preload("res://escenas/bala.tscn")

@onready var punta: Marker2D = $Marker2D
@onready var timer_rafaga = $TimerRafaga

var puedoDisparar: bool = true
var disparando = false
var disparos_realizados = 0

func _ready() -> void:
	collision_layer = 3
	collision_mask = 1

func _process(delta: float) -> void:
	if(VIDA <= 0):
		queue_free()
	
	if(VIDA >= 10):
		disparo_libre()
	
	else:
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

func disparo_libre():
	if disparando:
		return  # Evita iniciar otra ráfaga si ya está en proceso

	disparando = true
	# Dispara 3 balas con un intervalo de 0.2 segundos entre cada una
	for i in range(3):
		var bullet_i = bala.instantiate()
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.velocity = Vector2.LEFT * bullet_i.SPEED
		bullet_i.rotation_degrees = 180
		
		# Espera 0.2 segundos antes de disparar la siguiente bala
		await get_tree().create_timer(0.2).timeout

	# Espera 1.5 segundos entre ráfagas
	await get_tree().create_timer(1.5).timeout
	
	disparando = false
