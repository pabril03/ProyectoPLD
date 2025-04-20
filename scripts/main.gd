extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/enemigo.tscn")
const SniperEscena = preload("res://escenas/sniper.tscn")

@onready var punto_respawn = $PuntoRespawn  # Un marcador para el punto de respawn
@onready var punto_respawn_enemigo = $PuntoRespawnEnemigo

var jugador: CharacterBody2D  # Referencia al jugador
var sniper: CharacterBody2D
var enemy: StaticBody2D # Referencia al dummy

var player_respawning = false # Flag para evitar múltiples respawns
var sniper_respawning = false
var enemy_respawning = false

const PLAYER_ID_START = 0
const ENEMY_ID_START = 1000000
var next_player_id = PLAYER_ID_START
var next_enemy_id = ENEMY_ID_START
var max_players = 4

func get_next_player_id() -> int:
	next_player_id += 1
	if next_player_id <= max_players:
		return next_player_id
	else:
		return 0

func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id

func spawnear_jugador() -> void:
	# Comprobar si hay un ID guardado
	var id_a_usar = GameManager.obtener_id_jugador_eliminado()
	if id_a_usar != -1:
		# Si existe un ID guardado, lo usamos para el nuevo jugador
		jugador = JugadorEscena.instantiate()
		jugador.player_id = id_a_usar


	else:
		# Si no hay ID guardado, asignamos un nuevo ID
		jugador = JugadorEscena.instantiate()
		jugador.player_id = get_next_player_id()

		GameManager.registrar_jugador(jugador.player_id)

	jugador.collision_layer = 1 << jugador.player_id
	jugador.collision_mask = 1
	
	# Asignamos la posición global del respawn y le añadimos un pequeño offset vertical
	# para que no se solape con el suelo.
	jugador.global_position = punto_respawn.global_position + Vector2(0, -20)
	add_child(jugador)
	print("¡Ha aparecido el soldado %d!" % [jugador.player_id])


func spawnear_sniper() -> void:
	var id_a_usar = GameManager.obtener_id_jugador_eliminado()

	if id_a_usar != -1:
		sniper = SniperEscena.instantiate()
		sniper.player_id = id_a_usar

	else:
		sniper = SniperEscena.instantiate()
		sniper.player_id = get_next_player_id()

	# Igualamos capas y máscaras si lo necesitas:
	sniper.collision_layer = 1 << sniper.player_id
	sniper.collision_mask  = 1
	GameManager.registrar_jugador(sniper.player_id)

	sniper.global_position = punto_respawn.global_position + Vector2(100, -10)
	add_child(sniper)
	print("¡Ha aparecido el sniper %d!" % [sniper.player_id])


func spawnear_dummy():
	enemy = EnemigoEscena.instantiate()
	enemy.enemy_id = get_next_enemy_id()

	# Asigna la posición global del spawn, con un pequeño offset si lo necesitas.
	enemy.global_position = punto_respawn_enemigo.global_position + Vector2(0, -10)
	enemy.tipo_enemigo = "Dummy"
	add_child(enemy)

func _ready():
	var devices = Input.get_connected_joypads()
	for id in devices:
		print("Mando detectado en slot:", id, "-", Input.get_joy_name(id))
	spawnear_jugador()
	#spawnear_sniper()
	spawnear_dummy()

func _process(_delta: float) -> void:
	if not is_instance_valid(jugador) and not player_respawning:
		player_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_jugador()
		player_respawning = false
	
	if not is_instance_valid(sniper) and not sniper_respawning and (Input.get_connected_joypads().size() > 1):
		sniper_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_sniper()
		sniper_respawning = false
		
	if not is_instance_valid(enemy) and not enemy_respawning:
		enemy_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_dummy()
		enemy_respawning = false

	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
