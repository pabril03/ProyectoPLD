extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/enemigo.tscn")
const SniperEscena = preload("res://escenas/sniper_class.tscn")
var PickUpShotgun = preload("res://escenas/PickupShotgun.tscn")
var PickUpPistol = preload("res://escenas/PickupPistol.tscn")
var PickUpSniper = preload("res://escenas/PickupSniper.tscn")
var Potenciador = preload("res://escenas/potenciador.tscn")
const FireTrapScene: PackedScene = preload("res://escenas/fire_trap.tscn")

@onready var punto_respawn = $"SplitScreen2D/Spawns-J-E/PuntoRespawn1"  # Un marcador para el punto de respawn
@onready var punto_respawn2 = $"SplitScreen2D/Spawns-J-E/PuntoRespawn2"
@onready var punto_respawn3 = $"SplitScreen2D/Spawns-J-E/PuntoRespawn3"

@onready var menu := $SplitScreen2D/UILayer/Opciones

# Parámetros de zoom
@export var min_zoom: float = 1.0
@export var max_zoom: float = 3.0
@export var zoom_speed: float = 3.0

#Pantalla dividida
@onready var split_screen: SplitScreen2D = $SplitScreen2D

var last_pauser_id = -1

var jugador: CharacterBody2D  # Referencia al jugador
#var sniper: CharacterBody2D
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

func _ready():
	# Configuración de la cámara
	#camera.make_current()
	#_set_camera_limits()

	# Configuración de los dispositivos
	var devices = Input.get_connected_joypads()

	if devices.size() == 0:
		spawnear_jugador()

	else:
		spawnear_jugador()
		spawnear_jugador()
	
	#Añadir jugadores al splitScreen2D
	
	GameManager.initialize_spawns(4)

	process_mode = Node.PROCESS_MODE_ALWAYS

	# Arrancamos el menú oculto
	menu.visible = false

	# Hacemos que procese input aún con tree.paused = true
	menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Conectar la señal del botón ‘ResumeButton’
	var btn1 = menu.get_node("VBoxContainer/Opcion1") as Button
	btn1.pressed.connect(Callable(self, "_on_Opcion1_pressed"))
	
	var btn2 = menu.get_node("VBoxContainer/Opcion2") as Button
	btn2.pressed.connect(Callable(self, "_on_Opcion2_pressed"))
	
	var btnSalir = menu.get_node("VBoxContainer/Salir") as Button
	btnSalir.pressed.connect(Callable(self, "_on_Salir_pressed"))

	#split_screen.play_area = $Mapa/TileMapLayer

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("pause"):
		last_pauser_id = 1  # asumimos teclado = jugador 1
		_toggle_pause()

	elif event is InputEventJoypadButton and event.pressed and event.is_action("pause pad"):
		var device = event.device
		last_pauser_id = GameManager.get_player_id_for_device(device)
		if last_pauser_id == -1:
			last_pauser_id = 0  # fallback al teclado si no está mapeado
		_toggle_pause()

func _toggle_pause():
	get_tree().paused = not get_tree().paused
	menu.visible = get_tree().paused
	
	if get_tree().paused:
		print("Jugador %d ha pausado la partida" % last_pauser_id)
		var resume_btn = menu.get_node("VBoxContainer/Opcion1") as Button
		resume_btn.grab_focus()

	# Opcional: mostrar/ocultar tu menú de pausa
	# if tree.paused:
	#     $CanvasLayer/PauseMenu.visible = true
	# else:
	#     $CanvasLayer/PauseMenu.visible = false

# Resume game
func _on_Opcion1_pressed() -> void:
	# Fuerza la reanudación
	var tree = Engine.get_main_loop() as SceneTree
	tree.paused = false
	menu.visible = false

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
	# LÓGICA DE RESPAWN ANTIGUA, NO ELIMINAR:
	#var devices = Input.get_connected_joypads()
	#if devices.size() == 0 and GameManager.jugadores_vivos == 0 and not player_respawning:
		#player_respawning = true
		#await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		#spawnear_jugador()
		#player_respawning = false
	#if devices.size() >= 1 and GameManager.jugadores_vivos <= 1 and not player_respawning:
		#player_respawning = true
		#await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		#spawnear_jugador()
		#player_respawning = false

# Respawn de jugadores: siempre que haya menos vivos que max_players
	if not player_respawning and GameManager.jugadores_vivos < GameManager.jugadores.size():
		player_respawning = true
		# Crea un timer de 2s sin node extra
		await get_tree().create_timer(2.0).timeout
		spawnear_jugador()
		player_respawning = false

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
	jugador.process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Asignamos la posición global del respawn y le añadimos un pequeño offset vertical
	# para que no se solape con el suelo.
	match randi_range(1,3):
		1:
			jugador.global_position = punto_respawn.global_position
		2:
			jugador.global_position = punto_respawn2.global_position
		3:
			jugador.global_position = punto_respawn3.global_position

	var new_cam = split_screen.get_player_camera(jugador)
	split_screen.make_camera_track_player(new_cam, jugador)

	var world = get_tree().current_scene.get_node("SplitScreen2D").play_area
	world.add_child(jugador)
	split_screen.add_player(jugador)

	GameManager.jugador_vivo()
	print("¡Ha aparecido el soldado %d!" % [jugador.player_id])
