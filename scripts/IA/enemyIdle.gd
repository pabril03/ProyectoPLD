extends State
class_name EnemyIdle

@export var enemy: CharacterBody2D
@export var move_speed := 10.0

var player: CharacterBody2D
var padre: CharacterBody2D
var move_direction : Vector2
var wander_time : float

#Funcion que randomiza las variables
func randomize_wander():
	move_direction = Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	wander_time = randf_range(1,3)

func Enter():
	randomize_wander()
	padre = get_parent().get_parent()

#Movimiento aleatorio (es como el process)
func Update(delta: float):
	if wander_time > 0:
		wander_time -= delta
	
	else:
		randomize_wander()

# Es como el physics process normal, pero para maquinas finitas
#Lo que hace esto es simplemente seguir al jugador si hay un body en el area2D del enemigo
func Physics_Update(_delta: float):
	player = padre.player_game
	
	if enemy:
		enemy.velocity = move_direction * move_speed
		
	if padre.cuerpo_dentro and player:
		# var direction = player.global_position - enemy.global_position
		Transitioned.emit(self, "Follow")
