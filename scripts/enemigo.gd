extends StaticBody2D

const DeathAnimation: PackedScene = preload("res://escenas/VFX/death_animation.tscn")

signal health_changed(new_health)
var max_health = 20
var health = 20
const bala = preload("res://escenas/Modelos base (mapas y player)/bala.tscn")
var enemy_id: int
var tipo_enemigo
var damage_on_touch = 2

@onready var punta: Marker2D = $Marker2D
@onready var detector: Area2D = $Detector
@onready var damage_timer: Timer = $DamageTimer
var cuerpos_en_contacto: Array = []

var puedoDisparar: bool = true
var disparando = false
var disparos_realizados = 0
var muriendo = false

func _ready() -> void:
	collision_layer = 1 << 7
	collision_mask = 1
	# Conectar la señal 'health_changed' a la función que actualiza la barra de vida
	connect("health_changed", Callable(self, "_on_health_changed"))
	# Inicializar la barra de vida con el valor máximo de salud
	emit_signal("health_changed", health)
	add_to_group("enemy")
	
	# Hacemos que el detector solo "vea" jugadores
	detector.collision_layer = 1 << 7
	for layer in range(1, 5):
		detector.collision_mask |= 1 << layer
	
	# Conectamos el detector de colisiones
	detector.connect("body_entered", Callable(self, "_on_body_entered"))
	detector.connect("body_exited", Callable(self, "_on_body_exited"))
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	damage_timer.start()

func get_shooter_id() -> int:
	return enemy_id

func _process(_delta: float) -> void:
	if(health <= 0):
		queue_free()
	
	if(health >= 10):
		disparo_libre()
	
	else:
		disparo()


func generar_frase(autor: int, type: String) -> String:
	var frases = [
		"¡Monstruo %s aniquilado! Excelente trabajo, jugador %d." % [type, autor],
		"Has vencido al temible %s, ¡imbatible!." % [type],
		"Jugador %d destrozó al %s sin piedad." % [autor, type],
		"El %s no supo qué le esperaba contra ti, jugador %d." % [type, autor],
		"¡Victoria! El %s ha sido erradicado del reino." % [type],
		"%s eliminado con maestría por el jugador %d." % [type, autor],
		"Otro %s menos en este mundo, cortesía de jugador %d." % [type, autor],
		"El %s cayó ante tu habilidad, jugador %d." % [type, autor],
		"Has sobrevivido a la amenaza %s y la has destruido." % [type],
		"Jugador %d: 1 — %s: 0. Punto para ti." % [ autor, type],
	]

	return frases[randi() % frases.size()]
	
func take_damage(amount: float, autor: int, _aux: String = "Jugador", _aux2: String = "Disparo") -> void:
	if !muriendo:
		health = clamp(health - amount, 0, max_health)
		emit_signal("health_changed", health)
		
		if health <= 0:
			muriendo = true
			emit_signal("died")
			var msj = generar_frase(autor, String(tipo_enemigo))
			print(msj)

			# Mostramos los efectos de muerte
			var death_FX = DeathAnimation.instantiate()
			# La situamos donde estaba el jugador al morir
			death_FX.global_position = global_position
			var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
			world.add_child(death_FX)

			queue_free()
	
func heal(amount: float) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)


func disparo():
	if puedoDisparar:
		$Timer.start()
		var bullet_i = bala.instantiate()
		
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.shooter_id = enemy_id
		
		# Poner la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5
		# Máscara: colisiona con el entorno (bit 0), otros jugadores (bits 1, 3, 4), y escudos (bit 6)
		var mask = 1 << 0  # Entorno

		for i in range(1, 5):  # bits 1 a 4 = capas 2 a 5
			mask |= 1 << i

		mask |= 1 << 6  # Escudos (capa 7)

		bullet_i.collision_mask = mask

		bullet_i.velocity = Vector2.LEFT * bullet_i.SPEED
		bullet_i.rotation_degrees = 180
		bullet_i.tipo_enemigo = tipo_enemigo
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)
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
		
		bullet_i.global_position = punta.global_position
		bullet_i.set_start_position(punta.global_position)
		bullet_i.shooter_id = enemy_id
		# Poner la bala en la capa 6 (bit 5)
		bullet_i.collision_layer = 1 << 5
		# Máscara: colisiona con el entorno (bit 0), otros jugadores (bits 1, 3, 4), y escudos (bit 6)
		var mask = 1 << 0  # Entorno

		for j in range(1, 5):  # bits 1 a 4 = capas 2 a 5
			mask |= 1 << j
		mask |= 1 << 6  # Escudos (capa 7)
		
		bullet_i.collision_mask = mask
		#Ignoramos la colisión de las balas del enemigo
		# Consigo mismo
		bullet_i.velocity = Vector2.LEFT * bullet_i.SPEED
		bullet_i.rotation_degrees = 180
		bullet_i.tipo_enemigo = tipo_enemigo
		var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
		world.add_child(bullet_i)
		# Espera 0.2 segundos antes de disparar la siguiente bala
		await get_tree().create_timer(0.2).timeout

	# Espera 1.5 segundos entre ráfagas
	await get_tree().create_timer(1.5).timeout
	
	disparando = false
	
func set_damage_on_touch(damage: float) -> void:
	damage_on_touch = damage

func _on_body_entered(body: Node) -> void:
	# Si el cuerpo que entra pertenece al grupo "jugador", le hacemos daño
	if body.is_in_group("player") and body.has_method("take_damage"):
		if not cuerpos_en_contacto.has(body):
			cuerpos_en_contacto.append(body)
			if not body.get_escudo_activo():
				body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")

func _on_body_exited(body: Node) -> void:
	if cuerpos_en_contacto.has(body):
		cuerpos_en_contacto.erase(body)
		
func _on_damage_timer_timeout() -> void:
	for body in cuerpos_en_contacto:
		if is_instance_valid(body):
			if body.is_in_group("player") and body.has_method("take_damage"):
				if not body.get_escudo_activo():
					body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")

signal died()
