# GameManager.gd
extends Node

var spawn_markers: Array[Marker2D] = []
var player_viewports: Array = []

# Variable global para el número de jugadores
var num_jugadores: int = 1
var jugadores_eliminados: Array = [] # Guardamos los ID de los jugadores eliminnados en orden
var jugadores: Array = []
var spawn_states = []  # 0 = libre para reponer, 1 = ocupado Potenciadores

# Índices de player: 0 = jugador1, 1 = jugador2
var device_for_player := []
var player_devices := {}
var jugadores_vivos := 0
var max_players := 4
var soloplay = false

var clases: Array = [null,null,null,null]

var scores := {}
var kill_log: Array = []
var vidas : int = 1
var mapa : String = ""

var dead_players_count = 0

func _ready() -> void:
	scores[0] = 0
	configurar_dispositivos()

func configurar_dispositivos() -> void:
	# Obtener lista de joypads conectados
	var joypads = Input.get_connected_joypads()

	if !device_for_player.is_empty():
		print("Joypads: ", joypads)
		device_for_player.clear()
		player_devices.clear()

	if soloplay:
		device_for_player.append(null)

	else:
		match joypads.size():
			0:
				# Sin mandos: se juega 1 solo jugador con teclado y ratón
				device_for_player.append(null) # Jugador 1

			1:
				# Un mando: Jugador 1 usa teclado+ratón, Jugador 2 usa mando
				device_for_player.append(null)      # Jugador 1
				device_for_player.append(joypads[0]) # Jugador 2

			2:
				device_for_player.append(null)      # Jugador 1
				device_for_player.append(joypads[0]) # Jugador 2
				device_for_player.append(joypads[1]) # Jugador 3

			3:
				device_for_player.append(null)      # Jugador 1
				device_for_player.append(joypads[0]) # Jugador 2
				device_for_player.append(joypads[1]) # Jugador 3
				device_for_player.append(joypads[2]) # Jugador 4

func registrar_jugador(id_jugador: int) -> void:
	if jugadores.size() > max_players:
		return

	jugadores.append(id_jugador)
	
	var player_index := jugadores.size() - 1
	if player_index < device_for_player.size():
		player_devices[id_jugador] = device_for_player[player_index]
	else:
		player_devices[id_jugador] = null

	print("Jugador %d registrado con dispositivo %s" % [id_jugador, str(player_devices[id_jugador])])

	scores[id_jugador] = 0

	return jugadores.size()  # Devuelve un player_id único (1, 2, 3, ...)

func get_devices() -> Variant:
	return player_devices

func get_device_for_player(id_jugador: int) -> Variant:
	return player_devices.get(id_jugador, null)

func get_player_id_for_device(device: int) -> int:
	for id_jugador in player_devices.keys():
		if player_devices[id_jugador] == device:
			return id_jugador
	return -1

# Método para actualizar el número de jugadores
func set_num_jugadores(nuevo_num: int):
	num_jugadores = nuevo_num

# Método para obtener el número de jugadores
func get_num_jugadores() -> int:
	return num_jugadores

# Método para guardar el player_id cuando un jugador muere
func guardar_id_jugador(id: int) -> void:
	#id_jugador_eliminado = id
	jugadores_eliminados.append(id)

# Método para obtener el player_id guardado
func obtener_id_jugador_eliminado() -> int:

	#return id_jugador_eliminado
	if jugadores_eliminados.is_empty():
		return -1

	else:
		var id_jugador_eliminado = jugadores_eliminados.front()
		jugadores_eliminados.pop_front()
		return id_jugador_eliminado

func get_jugadores_vivos() -> int:
	return jugadores_vivos

func jugador_vivo() -> void:
	jugadores_vivos += 1

func jugador_muerto() -> void:
	jugadores_vivos -= 1

# Devuelve una Array de nodos CharacterBody2D con player_id en jugadores[]
func get_vivos_nodes() -> Array:
	var vivos = []
	# Recorre todos los nodos hijos de la escena principal
	for node in get_tree().get_current_scene().get_children():
		if node is CharacterBody2D and jugadores.has(node.player_id):
			vivos.append(node)

	return vivos

func initialize_spawns(count):
	spawn_states = []
	for i in range(count):
		spawn_states.append(0)  # Al inicio todos están libres

func _init_player_spawns() -> void:
	var parent 
	if mapa == "mapa1" or mapa == "":
		parent = get_tree().current_scene.get_node("SplitScreen2D/Spawns-J-E")
	if mapa == "mapa2":
		parent = get_tree().current_scene.get_node("SplitScreen2D/Spawns-J-E-Mapa2")
	if mapa == "mapa3":
		parent = get_tree().current_scene.get_node("SplitScreen2D/Spawns-J-Mapa3")

	for m in parent.get_children():
		if m is Marker2D:
			spawn_markers.append(m)

func get_spawn_point() -> Vector2:
	var idx = randi() % spawn_markers.size()
	return spawn_markers[idx].global_position

func resetearStats() -> void:
	spawn_markers = []

	# Variable global para el número de jugadores
	num_jugadores = 1
	jugadores_eliminados = [] # Guardamos los ID de los jugadores eliminnados en orden
	jugadores = []
	spawn_states = []  # 0 = libre para reponer, 1 = ocupado Potenciadores

	# Índices de player: 0 = jugador1, 1 = jugador2
	device_for_player = []
	player_devices = {}
	jugadores_vivos = 0
	clases = [null,null,null,null]
	
	scores = {}
	kill_log = []
	dead_players_count = 0
	
func asignarClase(clase: String, player: int) -> void:
	clases[player] = clase
	print(clases)

func add_viewport(viewport: SubViewport) -> void:
	if viewport == null:
		push_error("Intentaste añadir un viewport nulo.")
		return

	player_viewports.append(viewport)

func register_kill(shooter_id: int, victim_id: int) -> void:

	# 1) Asegurarnos de que el shooter ya exista en el diccionario
	if not scores.has(shooter_id):
		scores[shooter_id] = 0

	# 2) Sumar 1 kill a ese shooter
	scores[shooter_id] += 1

	# 3) Añadir al historial
	kill_log.append({ "shooter": shooter_id, "victim": victim_id })

	# 4) Guardar al victim como eliminado (si te sirve)
	guardar_id_jugador(victim_id)

	# Ejemplo de log en consola:
	if shooter_id != 0 and shooter_id != 5:
		print("Jugador %d ha matado a Jugador %d (Kills totales: %d)" %
			  [shooter_id, victim_id, scores[shooter_id]])

func dead_player() -> void:
	dead_players_count += 1

func finished_game() -> bool:
	if soloplay and dead_players_count == 1:
		return true
	if dead_players_count >= num_jugadores-1 and not soloplay:
		return true
	else:
		return false
