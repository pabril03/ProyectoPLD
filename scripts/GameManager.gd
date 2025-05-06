# GameManager.gd
extends Node

var spawn_markers: Array[Marker2D] = []

# Armas:
var shotgun_count: int = 0
var pistol_count: int = 0

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

func _ready() -> void:
		# Obtener lista de joypads conectados
	var joypads = Input.get_connected_joypads()
	
	match joypads.size():
		0:
			# Sin mandos: se juega 1 solo jugador con teclado y ratón
			device_for_player.append(null) # Jugador 1

		1:
			# Un mando: Jugador 1 usa teclado+ratón, Jugador 2 usa mando
			device_for_player.append(null)      # Jugador 1
			device_for_player.append(joypads[0]) # Jugador 2

		_:
			# Dos o más mandos: asigna los dos primeros
			device_for_player.append(joypads[0]) # Jugador 1
			device_for_player.append(joypads[1]) # Jugador 2

func registrar_jugador(id_jugador: int) -> void:
	if jugadores.size() >= max_players:
		return

	jugadores.append(id_jugador)
	
	var player_index := jugadores.size() - 1
	if player_index < device_for_player.size():
		player_devices[id_jugador] = device_for_player[player_index]
	else:
		player_devices[id_jugador] = null

	print("Jugador %d registrado con dispositivo %s" % [id_jugador, str(player_devices[id_jugador])])

	# El nuevo player coge una pistola
	arma_agarrada("Gun")

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

func arma_soltada(tipo_arma: String) -> void:
	if tipo_arma == "Shotgun":
		shotgun_count -= 1

	elif tipo_arma == "Gun":
		pistol_count -= 1

func arma_agarrada(tipo_arma: String) -> void:
	if tipo_arma == "Shotgun":
		shotgun_count += 1
	
	elif tipo_arma == "Gun":
		pistol_count += 1

func _init_player_spawns() -> void:
	var parent = get_tree().current_scene.get_node("SplitScreen2D/Spawns-J-E")
	for m in parent.get_children():
		if m is Marker2D:
			spawn_markers.append(m)

func get_spawn_point() -> Vector2:
	var idx = randi() % spawn_markers.size()
	return spawn_markers[idx].global_position
