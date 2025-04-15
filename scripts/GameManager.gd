# GameManager.gd
extends Node

# Variable global para el número de jugadores
var num_jugadores: int = 1
var id_jugador_eliminado = -1  # Variable para almacenar el player_id del jugador eliminado
var jugadores: Array = []

func registrar_jugador(jugador: Node) -> int:
	jugadores.append(jugador)
	return jugadores.size()  # Devuelve un player_id único (1, 2, 3, ...)

# Método para actualizar el número de jugadores
func set_num_jugadores(nuevo_num: int):
	num_jugadores = nuevo_num

# Método para obtener el número de jugadores
func get_num_jugadores() -> int:
	return num_jugadores

# Método para guardar el player_id cuando un jugador muere
func guardar_id_jugador(id: int) -> void:
	id_jugador_eliminado = id
	#print(id_jugador_eliminado)

# Método para obtener el player_id guardado
func obtener_id_jugador_eliminado() -> int:
	return id_jugador_eliminado
