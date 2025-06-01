extends CharacterBody2D

@export var speed := 200.0
var parar : bool = false
var direction := Vector2.ZERO
var id : int = -1
var player_id : int = -1
var tp_cooldown : bool = false
var colocados: bool = false

const DEADZONE := 0.2
var dispositivo := 0  # cambia si tienes varios mandos conectados

var player = null

func _ready() -> void:
	match player_id:
		1:
			dispositivo = 0
		2:
			dispositivo = 1
		3:
			dispositivo = 2
		4:
			dispositivo = 3
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not parar:
		update_direction()
		
		if direction.length() > 0.1:
			velocity = direction.normalized() * speed
		else:
			velocity = Vector2.ZERO
			
		move_and_slide()
	
func update_direction():
	if len(GameManager.player_devices) == 0:
		var mouse_target = get_global_mouse_position()
		direction = mouse_target - global_position
	else:
		var axis_x = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_X)
		var axis_y = Input.get_joy_axis(dispositivo, JOY_AXIS_RIGHT_Y)
		
		if abs(axis_x) > DEADZONE or abs(axis_y) > DEADZONE:
			direction = Vector2(axis_x, axis_y)
		else:
			direction = Vector2.ZERO


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("teletransportar"):
		if not tp_cooldown and body.colocados:
			body.tepear = true
			body.id_tp = id
			tp_cooldown = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.has_method("teletransportar") and id == 1:
		player = null
		#print("SALGO")
		body.tepear = false
