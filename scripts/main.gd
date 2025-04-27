extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/enemigo.tscn")
const SniperEscena = preload("res://escenas/sniper.tscn")
var PickUpShotgun = preload("res://escenas/PickupShotgun.tscn")
var PickUpPistol = preload("res://escenas/PickupPistol.tscn")
var Potenciador = preload("res://escenas/potenciador.tscn")

@onready var punto_respawn = $"Spawns-J-E/PuntoRespawn1"  # Un marcador para el punto de respawn
@onready var punto_respawn2 = $"Spawns-J-E/PuntoRespawn2"
@onready var punto_respawn3 = $"Spawns-J-E/PuntoRespawn3"
@onready var punto_respawn_enemigo = $"Spawns-J-E/PuntoRespawnEnemigo"
@onready var spawn_points = [
	$"Spawns-PowerUp/Pot1",
	$"Spawns-PowerUp/Pot2",
	$"Spawns-PowerUp/Pot3",
	$"Spawns-PowerUp/Pot4"
]

@onready var spawn_pistol = [
	$"Spawns-pistol/PistolRestock1"
]

@onready var spawn_shotgun = [
	$"Spawns-shotgun/ShotgunRestock1"
]


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

var toggled_on = false

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
	match randi_range(1,3):
		1:
			jugador.global_position = punto_respawn.global_position
		2:
			jugador.global_position = punto_respawn2.global_position
		3:
			jugador.global_position = punto_respawn3.global_position
		
		
	add_child(jugador)
	GameManager.jugador_vivo()
	print("¡Ha aparecido el soldado %d!" % [jugador.player_id])


func spawnear_sniper() -> void:
	var id_a_usar = GameManager.obtener_id_jugador_eliminado()

	if id_a_usar != -1:
		sniper = SniperEscena.instantiate()
		sniper.player_id = id_a_usar
		
	else:
		sniper = SniperEscena.instantiate()
		sniper.player_id = get_next_player_id()
		
		GameManager.registrar_jugador(sniper.player_id)
		
	# Igualamos capas y máscaras si lo necesitas:
	sniper.collision_layer = 1 << sniper.player_id
	sniper.collision_mask  = 1

	sniper.global_position = punto_respawn.global_position + Vector2(100, -10)
	add_child(sniper)
	GameManager.jugador_vivo()
	print("¡Ha aparecido el sniper %d!" % [sniper.player_id])


func spawnear_dummy():
	enemy = EnemigoEscena.instantiate()
	enemy.enemy_id = get_next_enemy_id()

	# Asigna la posición global del spawn, con un pequeño offset si lo necesitas.
	enemy.global_position = punto_respawn_enemigo.global_position + Vector2(0, -10)
	enemy.tipo_enemigo = "Dummy"
	enemy.set_damage_on_touch(5)
	add_child(enemy)

#Spawnear potenciadores en el spawn que haya hueco
func spawnear_potenciador(index):
	if GameManager.spawn_states[index] == 1:
		return  # Ya hay un potenciador aquí

	var potenciador_scene = tipoPotenciador() # Elige uno aleatorio
	var potenciador = Potenciador.instantiate()
	potenciador.tipo_potenciador = potenciador_scene
	potenciador.global_position = spawn_points[index].global_position
	potenciador.spawn_index = index  # GUARDAMOS en qué spawn está
	add_child(potenciador)
	GameManager.spawn_states[index] = 1

func tipoPotenciador():
	match randi_range(1,3):
		1:
			return "speed"
		2:
			return "health"
		3:
			return "damage"

func reponer_potenciador(index:int):
	await get_tree().create_timer(15.0).timeout
	if GameManager.spawn_states[index] == 0:
		spawnear_potenciador(index)

func liberar_spawn(index):
	GameManager.spawn_states[index] = 0  # Marcar spawn libre
	reponer_potenciador(index)

func spawn_pistola():
	var pistola = PickUpPistol.instantiate()
	pistola.global_position = spawn_pistol[0].global_position
	add_child(pistola)

func reponer_pistola():
	await get_tree().create_timer(10.0).timeout
	spawn_pistola()

func reponer_escopeta():
	await get_tree().create_timer(10.0).timeout
	spawn_escopeta()


func spawn_escopeta():
	var escopeta = PickUpShotgun.instantiate()
	escopeta.global_position = spawn_shotgun[0].global_position
	add_child(escopeta)

func _ready():
	var devices = Input.get_connected_joypads()

	if devices.size() == 0:
		spawnear_jugador()

	else:
		spawnear_jugador()
		spawnear_jugador()

	spawnear_dummy()
	
	GameManager.initialize_spawns(4)
	
	for i in range(spawn_points.size()):
		spawnear_potenciador(i)

	spawn_pistola()
	spawn_escopeta()

func _process(_delta: float) -> void:
	var devices = Input.get_connected_joypads()
	
	if devices.size() == 0 and GameManager.jugadores_vivos == 0 and not player_respawning:
		player_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_jugador()
		player_respawning = false
		
	elif devices.size() >= 1 and GameManager.jugadores_vivos <= 1 and not player_respawning:
		player_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_jugador()
		player_respawning = false
	
	#if GameManager.jugadores_vivos <= 1 and not sniper_respawning:
		#sniper_respawning = true
		#await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		#spawnear_sniper()
		#sniper_respawning = false
		
	if not is_instance_valid(enemy) and not enemy_respawning:
		enemy_respawning = true
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_dummy()
		enemy_respawning = false

	if Input.is_action_just_pressed("exit"):
		#Hacer pausa del juego
		get_tree().quit()
