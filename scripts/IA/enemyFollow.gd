extends State
class_name EnemyFollow

@export var enemy: CharacterBody2D
@export var move_speed := 40.0

var player: CharacterBody2D
var padre : CharacterBody2D

func Enter():
	padre = get_parent().get_parent()

# Es como el physics process normal, pero para maquinas finitas
#Lo que hace esto es simplemente seguir al jugador si hay un body en el area2D del enemigo
# hasta que sale del area2D y pasa a modo idle
# Esta puesto para que si el enemigo esta cerca del jugador, se quede en modo idle
func Physics_Update(_delta: float):
	player = padre.player_game
	
	if padre.cuerpo_dentro and player:
		var direction = player.global_position - enemy.global_position
		enemy.velocity = direction.normalized() * move_speed
		
	else:
		enemy.velocity = Vector2()
		
	if !padre.cuerpo_dentro:
		Transitioned.emit(self, "idle")
	if player:
		var direction = player.global_position - enemy.global_position
		if direction.length() < 50:
			Transitioned.emit(self,"idle")
