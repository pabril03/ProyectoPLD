extends "enemigo_generico.gd"

var burn_delay: float = 0.5
var burn_delay_on: float = 1.0
var burn_delay_off: float = 1.0

@onready var damage_timer: Timer = $DamageTimer
@onready var burn_particles:    CPUParticles2D = $BurnParticles

func _ready() -> void:
	super._ready()
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	damage_timer.start()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or muriendo:
		return

	# 1) Registramos al jugador inmediatamente, para que una salida posterior cancele TODO
	cuerpos_en_contacto.append(body)

	# 2) Encendemos partículas de "pre-burn"
	burn_particles.emitting = true

	# 3) Creamos un temporizador one-shot para el daño inicial
	var t_on = get_tree().create_timer(burn_delay_on)
	await t_on.timeout
	# Si salió antes de tiempo, lo cancelamos
	if not cuerpos_en_contacto.has(body):
		burn_particles.emitting = false
		return

	# 4) Aplicamos el daño por contacto
	if body.has_method("take_damage") and not body.get_escudo_activo():
		body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")

	# 5) Programamos la quemadura retrasada
	_start_burn_delay(body)

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
		# 2) Apagamos partículas y quitamos quemadura
		burn_particles.emitting = false
		body.quitar_quemadura()

func _on_damage_timer_timeout() -> void:
	# Mantiene daño periódicamente mientras siga en contacto
	for body in cuerpos_en_contacto:
		if is_instance_valid(body) and body.is_in_group("player") and not body.get_escudo_activo():
			body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "microondas")

signal died()
