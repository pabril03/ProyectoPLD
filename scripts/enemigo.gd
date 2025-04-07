extends StaticBody2D

signal health_changed(new_health)
var max_health = 20
var health = 20
const bala = preload("res://escenas/bala.tscn")
var enemy_id: int

@onready var punta: Marker2D = $Marker2D

var puedoDisparar: bool = true
var disparando = false
var disparos_realizados = 0

func _ready() -> void:
	collision_layer = 3
	collision_mask = 1
	# Conectar la señal 'health_changed' a la función que actualiza la barra de vida
	connect("health_changed", Callable(self, "_on_health_changed"))
	# Inicializar la barra de vida con el valor máximo de salud
	emit_signal("health_changed", health)

func get_shooter_id() -> int:
	return enemy_id

func _process(_delta: float) -> void:
	if(health <= 0):
		queue_free()
	
	if(health >= 10):
		disparo_libre()
	
	else:
		disparo()
	
func take_damage(amount: float) -> void:
	health = clamp(health - amount, 0, max_health)
	emit_signal("health_changed", health)
	
	if health <= 0:
		queue_free()
	
func heal(amount: float) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)


func disparo():
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		get_tree().root.add_child(bullet_i)
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.shooter_id = enemy_id	# Asignamos un id al shooter que disparó el arma
		
		#bullet_i.set_meta("shooter", self)  # Asignamos el meta shooter
		
		#bullet_i.add_collision_exception_with(self)
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
		bullet_i.shooter_id = enemy_id
		#bullet_i.set_meta("shooter", self)  # Asignamos el meta shooter
		#bullet_i.add_collision_exception_with(self)		#Ignoramos la colisión de las balas del enemigo
															# Consigo mismo
		bullet_i.velocity = Vector2.LEFT * bullet_i.SPEED
		bullet_i.rotation_degrees = 180
		
		# Espera 0.2 segundos antes de disparar la siguiente bala
		await get_tree().create_timer(0.2).timeout

	# Espera 1.5 segundos entre ráfagas
	await get_tree().create_timer(1.5).timeout
	
	disparando = false
