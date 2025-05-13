extends "enemigo_generico.gd"

const daga = preload("res://escenas/Armas/daga.tscn")

const SPEED : float = 100.0
var puedo_lanzar : bool = true

@onready var spawn_dagas : Array = [
	$Proyectiles/Daga1,
	$Proyectiles/Daga2,
	$Proyectiles/Daga3,
	$Proyectiles/Daga4,
	$Proyectiles/Daga5
]

var dagas_instanciadas: Array = []

@onready var damage_timer: Timer = $DamageTimer

func _ready() -> void:
	super._ready()
	
	damage_timer.connect("timeout", Callable(self, "_on_damage_timer_timeout"))
	
	_instanciar_dagas()
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if not dagas_instanciadas[0].active:
		damage_timer.start()

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			if not cuerpos_en_contacto.has(body):
				cuerpos_en_contacto.append(body)

		if dagas_instanciadas[0].active:
			lanzar_dagas_a(body)

		cuerpo_dentro = true

func _instanciar_dagas() -> void:
	for i in range(spawn_dagas.size()):
		var daga_inst = daga.instantiate()
		daga_inst.global_position = spawn_dagas[i].position
		daga_inst.return_position = spawn_dagas[i].global_position  # ← posición fija global
		add_child(daga_inst)
		dagas_instanciadas.append(daga_inst)

func lanzar_dagas_a(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	
	for proyectil in dagas_instanciadas:
		var direction = (body.global_position - proyectil.global_position).normalized()
		proyectil.target_position = proyectil.global_position + direction * 150.0
		proyectil.active = true
		proyectil.returning = false

func _on_area_2d_body_exited(body: Node2D) -> void:
	if cuerpos_en_contacto.has(body):
		cuerpos_en_contacto.erase(body)

func _on_damage_timer_timeout() -> void:
	if cuerpo_dentro and cuerpos_en_contacto.size() > 0:
		lanzar_dagas_a(cuerpos_en_contacto[0])
