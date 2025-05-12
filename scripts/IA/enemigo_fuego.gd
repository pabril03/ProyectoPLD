extends CharacterBody2D

@onready var animaciones: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $ProgressBar
var cuerpo_dentro : bool = false
const DeathAnimation: PackedScene = preload("res://escenas/VFX/death_animation.tscn")

signal health_changed(new_health)
var max_health = 20
var health = 20
var enemy_id: int
var tipo_enemigo
var damage_on_touch = 2
var muriendo = false
var cuerpos_en_contacto: Array = []

var player_game : CharacterBody2D

@onready var detector: Area2D = $Detector
@onready var damage_timer: Timer = $DamageTimer


func _physics_process(delta: float) -> void:
	move_and_slide()
	
	if velocity.length() > 0:
		animaciones.play("run")
	
	if velocity.x > 0:
		animaciones.flip_h = false
	else:
		animaciones.flip_h = true
		

func _ready() -> void:
	
	# El enemigo colisiona con el resto de jugadores
	collision_layer = 1 << 7
	
	for layer in range(1, 5):
		collision_mask |= 1 << layer
		
	# Conectar la señal 'health_changed' a la función que actualiza la barra de vida
	connect("health_changed", Callable(self, "_on_health_changed"))
	# Inicializar la barra de vida con el valor máximo de salud
	emit_signal("health_changed", health)
	
	# Hacemos que el detector solo "vea" jugadores
	detector.collision_layer = 1 << 7
	for layer in range(1, 5):
		detector.collision_mask |= 1 << layer
	
	# Conectamos el detector de colisiones
	detector.connect("body_entered", Callable(self, "_on_body_entered"))
	detector.connect("body_exited", Callable(self, "_on_body_exited"))
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	damage_timer.start()
	
	#Barra de vida
	
	barra_vida.max_value = max_health
	barra_vida.min_value = 0
	
	barra_vida.value = health
	
	connect("health_changed", Callable(self, "_on_entity_health_changed"))
	

func get_shooter_id() -> int:
	return enemy_id

func _process(_delta: float) -> void:
	if(health <= 0):
		queue_free()


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

func set_damage_on_touch(damage: float) -> void:
	damage_on_touch = damage

func take_damage(amount: float, autor: int, _aux: String = "Jugador", _aux2: String = "Disparo") -> void:
	if !muriendo:
		health = clamp(health - amount, 0, max_health)
		emit_signal("health_changed", health)
		
		if health <= 0:
			muriendo = true
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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		cuerpo_dentro = true
		player_game = body
		if body.has_method("take_damage"):
			if not cuerpos_en_contacto.has(body):
				cuerpos_en_contacto.append(body)
				if not body.get_escudo_activo():
					body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")
					body.aplicar_quemadura()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		cuerpo_dentro = false
		player_game = null
		body.quitar_quemadura()
	if cuerpos_en_contacto.has(body):
		cuerpos_en_contacto.erase(body)

func _on_entity_health_changed(new_health):
	barra_vida.value = new_health
	
	if new_health < max_health:
		barra_vida.show()   # Se muestra si se ha perdido salud
	else:
		barra_vida.hide()   # Se oculta si la salud es completa

func _on_damage_timer_timeout() -> void:
	for body in cuerpos_en_contacto:
		if is_instance_valid(body):
			if body.is_in_group("player") and body.has_method("take_damage"):
				if not body.get_escudo_activo():
					body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")
