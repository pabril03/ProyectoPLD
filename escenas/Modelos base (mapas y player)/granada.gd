extends CharacterBody2D

const DeathAnimation: PackedScene = preload("res://escenas/VFX/death_animation.tscn")

@onready var sprite = $Sprite2D

var SPEED: float = 200.0
var dano: float = 15
var owner_id: int = 0

var max_distance: float = 300.0
var distance_traveled: float = 0.0
var last_position: Vector2
var max_travel_time = 1.0

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

var hit_bodies = []

func _ready():
	# Inicializa posición de partida si no se ha seteado
	if last_position == Vector2.ZERO:
		last_position = global_position
	collision_layer = 1 << 9  # = 32

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
		
		# Movimiento lineal plano (como en Enter the Gungeon)
		global_position = _start_pos.lerp(_target_pos, t)
		
		# Simulación de altura (2.5D visual) usando offset del sprite
		var height = 4.0 * arc_height * t * (1.0 - t)
		sprite.position.y = -height  # Solo modifica la posición relativa del sprite
		#sombra.scale = Vector2(1.0 - 0.5 * t, 1.0 - 0.5 * t)  # Sombra se hace más chica al elevarse
		#sombra.modulate.a = 1.0 - t * 0.5  # Sombra se desvanece un poco

		# Final de la trayectoria
		if t >= 1.0:
			# La situamos donde estaba la granada al explotar
			var animacion = DeathAnimation.instantiate()
			animacion.global_position = global_position
			var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
			world.add_child(animacion)
			animacion._play_vfx(1)
			explode()
		return

func explode() -> void:

	# Lógica de daño
	for body in explosion.get_overlapping_bodies():
		if body.has_method("take_damage") and not hit_bodies.has(body):
			if body.health > 0 and not body.is_in_group("player"):
				hit_bodies.append(body)
				body.take_damage(dano, owner_id, "Jugador" ,"Bombazo")
				
			if body.health > 0 and body.is_in_group("player") and not (owner_id == body.player_id) and not body.escudo_activo():
				hit_bodies.append(body)
				body.take_damage(dano)

	queue_free()
