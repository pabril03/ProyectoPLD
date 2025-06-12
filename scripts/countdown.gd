extends Control

@onready var label: Label = $CenterContainer/LabelCountdown

# Tiempo entre cada número
var interval := 1.0
var countdown_numbers := ["3", "2", "1", "¡GO!"]

func _ready():
	visible = false
	label.visible = false

func start_countdown():
	# Pausamos TODO el árbol de escenas
	get_tree().paused = true

	visible = true
	label.visible = true
	label.modulate = Color.WHITE
	label.text = ""
	call_deferred("_run_countdown")


func _run_countdown() -> void:
	for text in countdown_numbers:
		label.text = text
		label.scale = Vector2(1.5, 1.5)
		# Animación de zoom rápido
		var tween = create_tween()
		tween.tween_property(label, "scale", Vector2(1, 1), interval * 0.8).set_trans(Tween.TRANS_BACK)
		# Esperamos el intervalo completo
		await get_tree().create_timer(interval).timeout
	# Ocultamos el contador
	hide()
	# Despausamos el juego
	get_tree().paused = false
