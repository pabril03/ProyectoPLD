extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/enemigo.tscn")

@onready var punto_respawn = $PuntoRespawn  # Un marcador para el punto de respawn
@onready var punto_respawn_enemigo = $PuntoRespawnEnemigo

var jugador: CharacterBody2D  # Referencia al jugador
var enemy: StaticBody2D # Referencia al dummy

var player_respawning = false # Flag para evitar múltiples respawns
var enemy_respawning = false

const PLAYER_ID_START = 0
const ENEMY_ID_START = 1000000
var next_player_id = PLAYER_ID_START
var next_enemy_id = ENEMY_ID_START

func get_next_player_id() -> int:
	next_player_id += 1
	return next_player_id

func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id

func spawnear_jugador() -> void:
	# Comprobar si hay un ID guardado
	var id_a_usar = GameManager.obtener_id_jugador_eliminado()
	#print("Id guardado: " + str(id_a_usar))
	if id_a_usar != -1:
		# Si existe un ID guardado, lo usamos para el nuevo jugador
		jugador = JugadorEscena.instantiate()
		jugador.player_id = id_a_usar
		jugador.collision_layer = 1 << (jugador.player_id)
		
		# Limpiamos el ID guardado para no usarlo en un futuro
		GameManager.guardar_id_jugador(-1)
	else:
		# Si no hay ID guardado, asignamos un nuevo ID
		jugador = JugadorEscena.instantiate()
		jugador.player_id = get_next_player_id()
		jugador.collision_layer = 1 << (jugador.player_id)
	
	#print("Id del jugador actual: " + str(jugador.player_id))
	
	# Asignamos la posición global del respawn y le añadimos un pequeño offset vertical
	# para que no se solape con el suelo.
	jugador.global_position = punto_respawn.global_position + Vector2(0, -10)
	add_child(jugador)
	
func spawnear_dummy():
	enemy = EnemigoEscena.instantiate()
	enemy.enemy_id = get_next_enemy_id()
	
	# Asigna la posición global del spawn, con un pequeño offset si lo necesitas.
	enemy.global_position = punto_respawn_enemigo.global_position + Vector2(0, -10)
	add_child(enemy)
	

func _ready():
	spawnear_jugador()
	spawnear_dummy()

func _process(_delta: float) -> void:
	if not is_instance_valid(jugador) and not player_respawning:
		player_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_jugador()
		player_respawning = false
		
	if not is_instance_valid(enemy) and not enemy_respawning:
		enemy_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_dummy()
		enemy_respawning = false

	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
