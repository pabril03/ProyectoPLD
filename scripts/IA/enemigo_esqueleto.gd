extends "enemigo_generico.gd"

@export var speed: float = 60.0

@onready var damage_timer: Timer = $DamageTimer
@onready var detector2: Area2D = $DetectorPlayer

var target: Node2D = null
var target_close: Node2D = null

func _ready() -> void:
	super._ready()
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))

	detector2.monitoring = true
	detector2.body_entered.connect(_on_area_2d_body_entered_damage)
	detector2.body_exited.connect(_on_area_2d_body_exited_damage)

func _physics_process(_delta: float) -> void:
	if target:
		# Calcula dirección hacia el objetivo y mueve
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * speed
	else:
		velocity = super.get_velocity()

	move_and_slide()

	if velocity.length() > 0:
		animaciones.play("run")
	else:
		animaciones.play("idle")

func _update_weakest_target() -> void:
	var weakest: Node2D = null
	var min_health := INF
	for body in detector.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage") and body.health > 0:
			if body.health < min_health:
				min_health = body.health
				weakest = body

	target = weakest

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or muriendo:
		return

	# 1) Registramos al jugador inmediatamente, para que una salida posterior cancele TODO
	cuerpos_en_contacto.append(body)

	# Cada vez que entra uno, reevalúa el de menos vida
	_update_weakest_target()

func _on_area_2d_body_entered_damage(body: Node2D) -> void:
	if not body.is_in_group("player") or muriendo:
		return

	damage_timer.start()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		cuerpos_en_contacto.erase(body)
		if body == target:
			target = null

	# Y aún así podría haber otro jugador dentro, así que:
	_update_weakest_target()

func _on_area_2d_body_exited_damage(body: Node2D) -> void:
	if not body.is_in_group("player") or muriendo:
		return

	damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	# Mantiene daño periódicamente mientras siga en contacto
	for body in cuerpos_en_contacto:
		if is_instance_valid(body) and body.is_in_group("player") and not body.get_escudo_activo():
			body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "golpetazo")

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
