extends Node2D

@onready var death_sprites: Array = [
	$Death1, $Death2, $Death3,
	$Death4, $Death5, $Death6, $Death7
]

var rng := RandomNumberGenerator.new()
var chosen_sprite: AnimatedSprite2D

func _enter_tree() -> void:

	# Reconstruye el Array cuando ya existan los nodos hijos
	death_sprites = [
		$Death1, $Death2, $Death3,
		$Death4, $Death5, $Death6, $Death7
	]
	if death_sprites.is_empty():
		return

	# Se ejecuta en cuanto el nodo se añade, antes que _ready()
	rng.randomize()
	# Oculta todas
	for s in death_sprites:
		s.visible = false
	# Elige y muestra una
	var idx = rng.randi_range(0, death_sprites.size() - 1)
	chosen_sprite = death_sprites[idx]
	chosen_sprite.visible = true
	# Asegura que no haga loop
	chosen_sprite.sprite_frames.set_animation_loop(chosen_sprite.animation, false)
	# Conecta la señal a la función que ocultará TODO el nodo
	chosen_sprite.animation_finished.connect(_on_anim_finished)
	chosen_sprite.play(chosen_sprite.animation)

func _on_anim_finished() -> void:
	# Oculta toda la escena de muerte de una vez
	visible = false
	set_process(false)
