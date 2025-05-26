extends CharacterBody2D

const DeathAnimation: PackedScene = preload("res://escenas/VFX/death_animation.tscn")

var SPEED: float = 200.0
var dano: float = 10

var max_distance: float = 300.0
var distance_traveled: float = 0.0
var last_position: Vector2
var max_travel_time = 1.5

# Lanzamiento parabólicoar max_travel_time: float = 1.0
var arc_height: float = 100.0
var _elapsed: float = 0.0
var _thrown: bool = false
var _start_pos: Vector2
var _target_pos: Vector2

var parar: bool = false

# Referencia al área de lanzamiento (dentro de esta escena)
@export var max_distance_zone := 200.0
@onready var launch_area = $LaunchArea as Area2D
@onready var explosion = $ExplosionArea
@onready var cuerpo = $Cuerpo

func _ready():
	# Inicializa posición de partida si no se ha seteado
	if last_position == Vector2.ZERO:
		last_position = global_position
	cuerpo.body_entered.connect(Callable(self, "_on_body_entered"))

# Llamada externa: lanza esta granada hacia raw_target
func throw_to(raw_target: Vector2) -> void:
	_start_pos = global_position
	_target_pos = _clamp_to_launch_area(raw_target)
	_elapsed = 0.0
	_thrown = true
	distance_traveled = 0.0
	last_position = global_position

func _clamp_to_launch_area(point_global: Vector2) -> Vector2:
	var shape_owner = launch_area.get_node("CollisionShape2D") as CollisionShape2D
	var shape = shape_owner.shape
	var p_local = launch_area.to_local(point_global)
	var p_clamped = p_local

	if shape is RectangleShape2D:
		var ext = shape.extents
		p_clamped.x = clamp(p_local.x, -ext.x, ext.x)
		p_clamped.y = clamp(p_local.y, -ext.y, ext.y)
	elif shape is CircleShape2D:
		var r = shape.radius
		if p_local.length() > r:
			p_clamped = p_local.normalized() * r
	else:
		var aabb = shape.get_rect()
		p_clamped.x = clamp(p_local.x, aabb.position.x, aabb.position.x + aabb.size.x)
		p_clamped.y = clamp(p_local.y, aabb.position.y, aabb.position.y + aabb.size.y)

	return launch_area.to_global(p_clamped)

func _physics_process(delta: float) -> void:
	if _thrown:
		_elapsed += delta
		var t = clamp(_elapsed / max_travel_time, 0.0, 1.0)
		# Trayectoria parabólica
		var flat = _start_pos.lerp(_target_pos, t)
		var height = 4.0 * arc_height * t * (1.0 - t)
		global_position = flat + Vector2(0, -height)

		# Distancia para max_distance
		distance_traveled += _start_pos.distance_to(global_position) if t < 1.0 else 0
		if t >= 1.0 or distance_traveled >= max_distance:
			explode()
		return

	# Si no está "lanzada", puede moverse o colisionar como bala normal
	var current_position = global_position
	distance_traveled += current_position.distance_to(last_position)
	last_position = current_position

	if distance_traveled >= max_distance:
		explode()
		return

	var colision = move_and_collide(velocity * delta)
	if colision:
		explode()
		return

	if not parar:
		# Mantenimiento de velocidad
		velocity = velocity.normalized() * SPEED if velocity.length() > 0.1 else Vector2.ZERO
		move_and_slide()

func explode() -> void:
	# Mostramos los efectos de explosion
	var death_FX = DeathAnimation.instantiate()
	# La situamos donde estaba la granada al explotar
	death_FX.global_position = global_position

	# Lógica de daño
	for body in explosion.get_overlapping_bodies():
		if (body.is_in_group("player") or body.has_method("repeler_balas")):
			if body.health > 0 and body.has_method("take_damage") and not body.escudo_activo:
				body.take_damage(dano)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.is_in_group("balas"):
		explode()
