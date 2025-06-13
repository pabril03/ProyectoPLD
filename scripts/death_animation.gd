extends Node2D

@onready var death_sprites: Array = [
	$Death1, $Death2, $Death3,
	$Death4, $Death5, $Death6
]

@onready var audio_explosion := AudioStreamPlayer.new()

var rng := RandomNumberGenerator.new()
var chosen_sprite: AnimatedSprite2D

func _ready() -> void:
	add_child(audio_explosion)
	audio_explosion.stream = preload("res://audio/sonido_explosion.mp3")
	audio_explosion.bus = "SFX"
	audio_explosion.volume_db = -5.0

func _enter_tree() -> void:
	_ready()

	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Reconstruye el Array cuando ya existan los nodos hijos
	death_sprites = [
		$Death1, $Death2, $Death3,
		$Death4, $Death5, $Death6
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
	audio_explosion.play()

func _on_anim_finished() -> void:
	# Oculta toda la escena de muerte de una vez
	visible = false
	set_process(false)

func _exit_tree():
	if chosen_sprite:
		chosen_sprite.animation_finished.disconnect(_on_anim_finished)

func _play_vfx(index: int) -> void:
	# Oculta todas primero
	for s in death_sprites:
		s.visible = false
		s.stop()
		# Desconecta la señal si estaba conectada
		if s.animation_finished.is_connected(_on_anim_finished):
			s.animation_finished.disconnect(_on_anim_finished)

	# Si el índice es válido, selecciona y reproduce
	if index >= 0 and index < death_sprites.size():
		chosen_sprite = death_sprites[index]
		chosen_sprite.visible = true
		chosen_sprite.sprite_frames.set_animation_loop(chosen_sprite.animation, false)
		chosen_sprite.animation_finished.connect(_on_anim_finished)
		chosen_sprite.play(chosen_sprite.animation)
		audio_explosion.play()
