extends Node2D

var score = 0
var bonus = 0
var fastBonus = 0
var perfectBonus = 0

func _ready():
	updateScore()
	score = 0
	fastBonus = 0
	perfectBonus = 0

	if Score.perfectBonus < 80:
		$Perfecto.text = "Buen trabajo"
	elif Score.perfectBonus < 100:
		$Perfecto.text = "Casi perfecto"

	if Score.fastBonus < 80:
		$"Bonus de velocidad".text = "Veloz"

	$NewBestLabel.visible = false  # nuevo
	
func updateScore():
	bonus+=Score.fastBonus+Score.perfectBonus
	await get_tree().create_timer(1).timeout
	var tempScore = score
	$AudioStreamPlayer2D.play(0.0)
	while(score<(tempScore+Score.newScore)):
		await get_tree().create_timer(0.01).timeout
		score+=5
	$AudioStreamPlayer2D.stop()
	await get_tree().create_timer(0.8).timeout
	$AudioStreamPlayer2D.play(0.0)
	while(fastBonus<Score.fastBonus):
		await get_tree().create_timer(0.01).timeout
		fastBonus+=5
	$AudioStreamPlayer2D.stop()
	await get_tree().create_timer(0.8).timeout
	$AudioStreamPlayer2D.play(0.0)
	while(perfectBonus<Score.perfectBonus):
		await get_tree().create_timer(0.01).timeout
		perfectBonus+=5
	$AudioStreamPlayer2D.stop()
	await get_tree().create_timer(0.5).timeout
	$AudioStreamPlayer2D.play(0.0)
	while(score<(tempScore+Score.newScore+bonus)):
		await get_tree().create_timer(0.01).timeout
		score+=5
		$AudioStreamPlayer2D.stop()
	if Score.is_new_best:
		$NewBestLabel.text = "NEW BEST!"
		$NewBestLabel.visible = true
		await get_tree().create_timer(0.6).timeout

		$BestNameDialog.visible = true

		var name_edit = $BestNameDialog/CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit
		name_edit.text = ""
		name_edit.grab_focus()
	else:
		$NewBestLabel.visible = false

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _process(delta):
	$Puntaje.text = str(score)
	$Puntaje2.text = "+"+str(fastBonus)
	$Puntaje3.text = "+"+str(perfectBonus)

func _get_score_file_path() -> String:
	var base = Global.rutaArchivos + "/Scores/"
	match Score.LatestGame:
		Score.Games.Puzzle:
			return base + "puntajesPuzzle.dat"
		Score.Games.MatchIt:
			return base + "puntajesMatch.dat"
		Score.Games.OrderIt:
			return base + "puntajesOrder.dat"
		_:
			return ""

func _save_best_name(player_name: String) -> void:
	var path = _get_score_file_path()
	if path == "" or not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	var diff_key = Score.actualDifficult  # "easy" / "medium" / "hard"
	if not data.has(diff_key):
		return

	data[diff_key]["name"] = player_name

	var filew = FileAccess.open(path, FileAccess.WRITE)
	filew.store_var(data)
	filew.close()

func _on_BestNameDialog_confirmed():
	var name_edit = $BestNameDialog/CenterContainer/Panel/MarginContainer/VBox/NameRow/NameEdit
	var name = name_edit.text.strip_edges()
	if name == "":
		name = "Player"

	_save_best_name(name)
	$BestNameDialog.visible = false
	
func _on_button_pressed():
	ButtonClick.button_click()
	Score.is_new_best = false  # reseteamos flag
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")

func _on_BestNameDialog_cancelled():
	$BestNameDialog.visible = false
