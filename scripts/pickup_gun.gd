# pickup_arma.gd
extends Node2D

@export var weapon_name: String = "gun"    # "shotgun" o "pistol"
@onready var ItemRange     = $ItemRange       # Área que detecta al jugador
@onready var sprite        = $Sprite2D        # Sprite del pickup
@onready var RespawnTimer  = $RespawnTimer    # Timer de 10s para respawn

var is_taken = false  # Control interno para no procesar múltiples veces

func _ready() -> void:
	# Conectar señal al área
	ItemRange.body_entered.connect(Callable(self, "_on_body_entered"))
	# Configurar el timer
	RespawnTimer.one_shot = true
	RespawnTimer.wait_time = 10.0
	RespawnTimer.timeout.connect(Callable(self, "_on_respawn_timeout"))

func _on_body_entered(body: Node) -> void:
	# Solo jugadores, solo una vez
	if is_taken:
		return

	if not body.is_in_group("player"):
		return

	is_taken = true

	# 1) Cambiar el arma del jugador
	body.add_weapon(weapon_name)

	# 2) Notificar al GameManager
	#    (capitalizamos para que coincida con "Shotgun" o "Pistol")
	# GameManager.arma_agarrada( weapon_name.capitalize() )

	# 3) Ocultar y desactivar el pickup
	sprite.visible       = false
	ItemRange.set_deferred("monitoring", false)

	# 4) Arrancar el timer de respawn
	RespawnTimer.start()

func _on_respawn_timeout() -> void:

	is_taken = false
	sprite.visible = true
	ItemRange.set_deferred("monitoring", true)
	RespawnTimer.start()
