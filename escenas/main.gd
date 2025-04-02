extends Node2D

const JugadorEscena = preload("res://escenas/player.tscn")  # Ruta de la escena del jugador
const EnemigoEscena = preload("res://escenas/enemigo.tscn")

@onready var punto_respawn = $PuntoRespawn  # Un marcador para el punto de respawn
@onready var punto_respawn_enemigo = $PuntoRespawnEnemigo

var jugador: CharacterBody2D  # Referencia al jugador
var enemy: StaticBody2D # Referencia al dummy

var player_respawning = false # Flag para evitar múltiples respawns
var enemy_respawning = false

func spawnear_jugador():
	jugador = JugadorEscena.instantiate()
	
	# Asignamos la posición global del respawn y le añadimos un pequeño offset vertical
	# para que no se solape con el suelo.
	jugador.global_position = punto_respawn.global_position + Vector2(0, -10)
	
	add_child(jugador)
	
func spawnear_dummy():
	enemy = EnemigoEscena.instantiate()
	
	# Asigna la posición global del spawn, con un pequeño offset si lo necesitas.
	enemy.global_position = punto_respawn_enemigo.global_position + Vector2(0, -10)
	add_child(enemy)
	

func _ready():
	spawnear_jugador()
	spawnear_dummy()


func _process(delta):
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
