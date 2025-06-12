extends "enemigo_generico.gd"

var burn_delay: float = 0.5
var burn_delay_on: float = 1.0
var burn_delay_off: float = 1.0
@export var speed: float = 50.0
@export var explosion_delay: float = 2.0
@export var explosion_damage: int = 100

@onready var detector2: Area2D = $DetectorPlayer
@onready var detector3: Area2D = $DetectorPlayerExt

@onready var damage_timer: Timer = $DamageTimer
@onready var explosion_timer: Timer = $ExplosionTimer
@onready var burn_particles: CPUParticles2D = $BurnParticles

var target: Node2D = null
var target_close: Node2D = null

#Audio
@onready var audio_fuego := AudioStreamPlayer.new()

func _ready() -> void:
	super._ready()
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	damage_timer.start()

	detector2.monitoring = true
	detector2.body_entered.connect(_on_area_body_entered)
	detector2.body_exited.connect(_on_area_body_exited)

	detector3.monitoring = true
	detector3.body_entered.connect(_on_area_2d_body_entered_ext)
	detector3.body_exited.connect(_on_area_2d_body_exited_ext)

	explosion_timer.wait_time = explosion_delay
	explosion_timer.one_shot = true
	explosion_timer.connect("timeout", Callable(self, "_on_explosion_timeout"))
	
	add_child(audio_fuego)
	audio_fuego.stream = preload("res://audio/sonido_fuego.mp3")
	audio_fuego.bus = "SFX"
	audio_fuego.volume_db = -15.0
	

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

func _on_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_close = body
		explosion_timer.start()
	pass
func _on_area_body_exited(body: Node2D) -> void:
	if body == target_close:
		explosion_timer.stop()
		target_close = null
	pass

func _update_weakest_target() -> void:
	var weakest: Node2D = null
	var min_health := INF
	for body in detector3.get_overlapping_bodies():
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

	# 2) Encendemos partículas de "pre-burn"
	burn_particles.emitting = true
	
	# Añadimos audio
	audio_fuego.play()

	# 3) Creamos un temporizador one-shot para el daño inicial
	var t_on = get_tree().create_timer(burn_delay_on)
	await t_on.timeout
	# Si salió antes de tiempo, lo cancelamos
	if not cuerpos_en_contacto.has(body):
		burn_particles.emitting = false
		return

	# 4) Aplicamos el daño por contacto
	if body.has_method("take_damage") and not body.get_escudo_activo():
		body.take_damage(damage_on_touch, 0, tipo_enemigo, "mordisco")

	# 5) Programamos la quemadura retrasada
	_start_burn_delay(body)
	
	

func _on_area_2d_body_entered_ext(body: Node2D) -> void:
	if not body.is_in_group("player") or muriendo:
		return

	# Cada vez que entra uno, reevalúa el de menos vida
	_update_weakest_target()

func _start_burn_delay(body: Node2D) -> void:
	# Crea un timer one-shot y espera a que salte
	var t = get_tree().create_timer(burn_delay)
	# En GDScript 2.0 usamos await
	await t.timeout
	# Al saltar, comprobamos que el cuerpo siga dentro y sea válido
	if not cuerpos_en_contacto.has(body) or not is_instance_valid(body):
		return
	if not body.get_escudo_activo():
		body.aplicar_quemadura()


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 1) Quitamos de la lista al instante (cancela futuros awaits)
		cuerpos_en_contacto.erase(body)
		# 2) Quitamos quemadura
		body.quitar_quemadura()
		# 3) Quitamos las partículas si no quedan players:
		var any_player_left := false
		for b in detector2.get_overlapping_bodies():
			if b.is_in_group("player"):
				any_player_left = true
				break

		if not any_player_left:
			burn_particles.emitting = false
			audio_fuego.stop()

func _on_area_2d_body_exited_ext(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Si el que sale es nuestro objetivo actual, lo descartamos
		if body == target:
			target = null

		# Y aún así podría haber otro jugador dentro, así que:
		_update_weakest_target()

func _on_damage_timer_timeout() -> void:
	# Mantiene daño periódicamente mientras siga en contacto
	for body in cuerpos_en_contacto:
		if is_instance_valid(body) and body.is_in_group("player") and not body.get_escudo_activo():
			body.take_damage(damage_on_touch, 0, tipo_enemigo, "microondas")

func _on_explosion_timeout() -> void:
	# Aquí puedes añadir efectos visuales o eliminar el nodo si es necesario
	var death_FX = DeathAnimation.instantiate()
	death_FX.global_position = global_position
	var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
	world.add_child(death_FX)
	death_FX._play_vfx(2)

	if target_close and target_close.is_inside_tree():
		if target_close.has_method("take_damage"):
			target_close.take_damage(explosion_damage, 0, tipo_enemigo, "explosión")
	queue_free()
