# ScoreBoard.gd
extends Control

const SCORE_ROW_SCENE: PackedScene = preload("res://UI/ScoreRow.tscn")
@onready var scores_list := $MarginContainer/ScoresList
@onready var again_button := $Button
@onready var back_button := $Button2

func _ready() -> void:
	again_button.grab_focus()
	GlobalSettings.set_music_enabled(true)

	# ── 1) Crear la fila de encabezado ───────────────────────────────────
	var header = HBoxContainer.new()
	header.name = "HeaderRow"

	var lbl_id = Label.new()
	lbl_id.text = "Id Jugador"
	lbl_id.add_theme_font_size_override("font_size", 20)
	lbl_id.add_theme_color_override("font_color", Color(1, 1, 1))

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_kills = Label.new()
	lbl_kills.text = "Asesinatos"
	lbl_kills.add_theme_font_size_override("font_size", 20)
	lbl_kills.add_theme_color_override("font_color", Color(1, 1, 1))

	header.add_child(lbl_id)
	header.add_child(spacer)
	header.add_child(lbl_kills)
	scores_list.add_child(header)

	# ── 2) Tomar el diccionario de puntajes del GameManager ───────────────
	var array := []
	for pid in GameManager.scores.keys():
		array.append({ "player_id": pid, "kills": GameManager.scores[pid] })

	# ── 3) Ordenar por kills descendente ───────────────────────────────────
	array.sort_custom(func(a, b):
		return b["kills"] - a["kills"]
	)

	# ── 4) Instanciar cada fila ───────────────────────────────────────────
	for entry in array:
		var fila = SCORE_ROW_SCENE.instantiate() as HBoxContainer

		var pid = entry["player_id"]
		if pid == 0:
			fila.get_node("PlayerLabel").text = "Monstruos"
		elif pid == 5:
			fila.get_node("PlayerLabel").text = "Trampas"
		else:
			fila.get_node("PlayerLabel").text = "Jugador %d" % pid

		fila.get_node("KillsLabel").text = "%d" % entry["kills"]
		scores_list.add_child(fila)
	
	array.sort_custom(func(a, b):
		return b["kills"] - a["kills"]
	)

func _orden_por_kills_desc(a, b) -> int:
	return b["kills"] - a["kills"]

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/numJugadores.tscn")

func _on_button2_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/inicio.tscn")
