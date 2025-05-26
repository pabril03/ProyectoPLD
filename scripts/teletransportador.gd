extends CharacterBody2D

@export var speed := 200.0
var parar : bool = false
var direction := Vector2.ZERO
var id : int = -1
var tp_cooldown : bool = false
var colocados: bool = false

var player = null

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
	var mouse_target = get_global_mouse_position()
	direction = mouse_target - global_position


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
