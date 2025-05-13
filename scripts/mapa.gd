extends Node2D

const JugadorEscena = preload("res://escenas/Modelos base (mapas y player)/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/Modelos base (mapas y player)/enemigo.tscn")
var PickUpShotgun = preload("res://escenas/Spawns Armas y Powerups/PickupShotgun.tscn")
var PickUpPistol = preload("res://escenas/Spawns Armas y Powerups/PickupPistol.tscn")
var PickUpSniper = preload("res://escenas/Spawns Armas y Powerups/PickupSniper.tscn")
var Potenciador = preload("res://escenas/Spawns Armas y Powerups/potenciador.tscn")
const FireTrapScene: PackedScene = preload("res://escenas/Trampas/fire_trap.tscn")
const GasTrapScene: PackedScene = preload("res://escenas/Trampas/gas_trap.tscn")
const EnemigoFuego = preload("res://escenas/Modelos base (mapas y player)/enemigo_fuego.tscn")
const EnemigoDagas = preload("res://escenas/Modelos base (mapas y player)/enemigo_dagas.tscn")

@onready var split_screen: SplitScreen2D
@onready var puntos_respawn_enemigo_fuego = [
	$PuntoRespawnEnemigoFuego,
	$PuntoRespawnEnemigoFuego2,
	$PuntoRespawnEnemigoFuego3,
	$PuntoRespawnEnemigoFuego4,
	$PuntoRespawnEnemigoFuego5
]

@onready var puntos_respawn_enemigo_dagas = [
	$PuntoRespawnEnemigoDagas,
	$PuntoRespawnEnemigoDagas2,
	$PuntoRespawnEnemigoDagas3,
	$PuntoRespawnEnemigoDagas4,
	$PuntoRespawnEnemigoDagas5
]

@onready var spawn_points = [
	$"Spawns-PowerUp/Pot1",
	$"Spawns-PowerUp/Pot2",
	$"Spawns-PowerUp/Pot3",
	$"Spawns-PowerUp/Pot4"
]

@onready var spawn_pistol = [
	$"Spawns-pistol/PistolRestock1",
	$"Spawns-pistol/PistolRestock2"
]

@onready var spawn_shotgun = [
	$"Spawns-shotgun/ShotgunRestock1",
	$"Spawns-shotgun/ShotgunRestock2"
]

@onready var spawn_sniper = [
	$"Spawns-sniper/SniperRestock1",
	$"Spawns-shotgun/ShotgunRestock2"
]

@onready var trap_points := [
	$"Spawn-fire-traps/Firetrap1",
	$"Spawn-fire-traps/Firetrap2",
	$"Spawn-fire-traps/Firetrap3",
	$"Spawn-fire-traps/Firetrap4",
	$"Spawn-fire-traps/Firetrap5",
	$"Spawn-fire-traps/Firetrap6",
	$"Spawn-fire-traps/Firetrap7",
	$"Spawn-fire-traps/Firetrap8",
	$"Spawn-fire-traps/Firetrap9",
	$"Spawn-fire-traps/Firetrap10"
]

@onready var gas_points := [
	$"Spawn-poison-traps/Poisontrap",
	$"Spawn-poison-traps/Poisontrap2",
	$"Spawn-poison-traps/Poisontrap3",
	$"Spawn-poison-traps/Poisontrap4",
	$"Spawn-poison-traps/Poisontrap5",
	$"Spawn-poison-traps/Poisontrap6",
	$"Spawn-poison-traps/Poisontrap7",
	$"Spawn-poison-traps/Poisontrap8",
	$"Spawn-poison-traps/Poisontrap9",
	$"Spawn-poison-traps/Poisontrap10",
	$"Spawn-poison-traps/Poisontrap11",
	$"Spawn-poison-traps/Poisontrap12",
	$"Spawn-poison-traps/Poisontrap13",
	$"Spawn-poison-traps/Poisontrap14",
	$"Spawn-poison-traps/Poisontrap15",
	$"Spawn-poison-traps/Poisontrap16",
	$"Spawn-poison-traps/Poisontrap17"
]

var last_pauser_id = -1
var jugador: CharacterBody2D  # Referencia al jugador
var player_respawning = false # Flag para evitar múltiples respawns
var sniper_respawning = false
var enemy_respawning = false

const PLAYER_ID_START = 0
const ENEMY_ID_START = 1000000
var next_player_id = PLAYER_ID_START
var next_enemy_id = ENEMY_ID_START
var max_players = 4

var toggled_on = false

func _ready():

	spawnear_dummy()

	#Añadir jugadores al splitScreen2D
	GameManager.initialize_spawns(4)
	
	for i in range(spawn_points.size()):
		spawnear_potenciador(i)

	spawn_pistola()
	spawn_escopeta()
	spawn_francotirador()
	spawn_fire_traps()
	spawn_gas_traps()

	process_mode = Node.PROCESS_MODE_ALWAYS

# Aquí podrías abrir un sub-menú de ajustes
func _on_Opcion2_pressed() -> void:
	print("Pulso Opcion2: abre opciones avanzadas…")
	# TODO: implementa tu lógica de ajustes

# Salir al menú principal
func _on_Salir_pressed() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	tree.paused = false
	tree.change_scene_to_file("res://UI/inicio.tscn")

func _process(_delta: float) -> void:
	pass

func get_next_enemy_id() -> int:
	var id = next_enemy_id
	next_enemy_id += 1
	return id

func spawnear_dummy():
	
	for index in puntos_respawn_enemigo.size():
		#var enemy = EnemigoFuego.instantiate()
		var enemy = EnemigoDagas.instantiate()   
		
		enemy.global_position = puntos_respawn_enemigo[index].global_position + Vector2(0, -10)
		enemy.tipo_enemigo = "Fueboca"
		enemy.set_damage_on_touch(3)
		enemy.add_to_group("enemy")
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(enemy)

	for index in puntos_respawn_enemigo_dagas.size():
		var enemy = EnemigoFuego.instantiate()   
		enemy.global_position = puntos_respawn_enemigo_dagas[index].global_position + Vector2(0, -10)
		enemy.tipo_enemigo = "FuebocaPacifico"
		enemy.set_damage_on_touch(0)
		enemy.add_to_group("enemy")
		enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	for index in spawn_pistol.size():
		var pistola = PickUpPistol.instantiate()   
		pistola.global_position = spawn_pistol[index].global_position
		add_child(pistola)

func spawn_escopeta():
	for index in spawn_shotgun.size():
		var escopeta = PickUpSniper.instantiate()   
		escopeta.global_position = spawn_shotgun[index].global_position
		add_child(escopeta)

func spawn_francotirador():
	for index in spawn_sniper.size():
		var francotirador = PickUpSniper.instantiate()    # Crea una instancia de la trampa :contentReference[oaicite:6]{index=6}
		francotirador.global_position = spawn_sniper[index].global_position  # La sitúa en el marcador :contentReference[oaicite:7]{index=7}
		add_child(francotirador)

func spawn_fire_traps() -> void:
	for index in trap_points.size():
		var trap = FireTrapScene.instantiate()    # Crea una instancia de la trampa :contentReference[oaicite:6]{index=6}
		trap.global_position = trap_points[index].global_position  # La sitúa en el marcador :contentReference[oaicite:7]{index=7}
		add_child(trap)                            # La añade al árbol de escena :contentReference[oaicite:8]{index=8}

func spawn_gas_traps() -> void:
	for index in gas_points.size():
		var trap = GasTrapScene.instantiate()    # Crea una instancia de la trampa :contentReference[oaicite:6]{index=6}
		trap.global_position = gas_points[index].global_position  # La sitúa en el marcador :contentReference[oaicite:7]{index=7}
		add_child(trap)                            # La añade al árbol de escena :contentReference[oaicite:8]{index=8}
