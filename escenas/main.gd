extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador

@onready var punto_respawn = $PuntoRespawn  # Un marcador para el punto de respawn
var jugador: CharacterBody2D  # Referencia al jugador

func _ready():
	spawnear_jugador()

# Cuando se muere el jugador spawnean muchos (Solucionar)
func _process(delta):
	if not is_instance_valid(jugador):
		await get_tree().create_timer(2.0).timeout  # Espera 2 segundos antes del respawn
		spawnear_jugador()

	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func spawnear_jugador():
	jugador = JugadorEscena.instantiate()
	jugador.global_position = punto_respawn.global_position  # Ubicación de respawn
	add_child(jugador)
