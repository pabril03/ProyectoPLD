extends ColorRect
class_name AbilityButton

@onready var time_label = $TextureRect/Counter/Value

@export var cooldown = 1.0


func _ready():
	time_label.hide()
	$TextureRect/Sweep.value = 0
	$TextureRect/Sweep.texture_progress = $TextureRect.texture
	#$Timer.wait_time = cooldown
	set_process(false)
	
func _process(_delta):
	time_label.text = "%3.1f" % $Timer.time_left
	$TextureRect/Sweep.value = int(($Timer.time_left / $Timer.wait_time) * 100)

func abilityUsed():
	set_process(true)
	$Timer.start()
	time_label.show()

func _on_timer_timeout() -> void:
	$TextureRect/Sweep.value = 0
	time_label.hide()
	set_process(false)
