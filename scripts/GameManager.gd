# GameManager.gd
extends Node

# Variable global para el número de jugadores
var num_jugadores: int = 1
var jugadores_eliminados: Array = [] # Guardamos los ID de los jugadores eliminnados en orden
var jugadores: Array = []

# Índices de player: 0 = jugador1, 1 = jugador2
var device_for_player := []
var player_devices := {}

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
	print("Asignación de dispositivos:", device_for_player)

func registrar_jugador(id_jugador: int) -> void:
	jugadores.append(id_jugador)
	
	var player_index := jugadores.size() - 1
	if player_index < device_for_player.size():
		player_devices[id_jugador] = device_for_player[player_index]
	else:
		player_devices[id_jugador] = null

	print("Jugador %d registrado con dispositivo %s" % [id_jugador, str(player_devices[id_jugador])])

	return jugadores.size()  # Devuelve un player_id único (1, 2, 3, ...)

func get_devices() -> Variant:
	return player_devices

func get_device_for_player(id_jugador: int) -> Variant:
	return player_devices.get(id_jugador, null)

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
