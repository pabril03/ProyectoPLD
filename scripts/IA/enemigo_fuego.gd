extends "enemigo_generico.gd"

@onready var damage_timer: Timer = $DamageTimer

func _ready() -> void:
	super._ready()
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	damage_timer.start()

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

func _on_damage_timer_timeout() -> void:
	for body in cuerpos_en_contacto:
		if is_instance_valid(body):
			if body.is_in_group("player") and body.has_method("take_damage"):
				if not body.get_escudo_activo():
					body.take_damage(damage_on_touch, enemy_id, tipo_enemigo, "mordisco")
