extends Node2D

var en: bool = false
const TOTAL_LOGROS = 5

func load_language_setting():
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var json_as_dict = JSON.parse_string(json_as_text)
		en = json_as_dict["english"]
		return
	en = false

func update_language_scores_screen():
	$Logros.text = "Achievements" if en else "Logros"

func _ready():
	load_language_setting()
	update_language_scores_screen()
	update_logros()

func update_logros():
	var total = Score.get_unlocked_achievements_count()
	$NumLogros.text = str(total) + "/" + str(TOTAL_LOGROS)

	_set_logro_sprite($LogroPuzzle, "puzzle")
	_set_logro_sprite($LogroMatchIt, "match")
	_set_logro_sprite($LogroOrderIt, "order")
	_set_logro_sprite($LogroSpeed, "speed")
	_set_logro_sprite($LogroPerfect, "perfect")

func _set_logro_sprite(sprite: Sprite2D, logro_id: String) -> void:
	var texture_path = Score.get_unknown_achievement_texture_path()
	if Score.is_achievement_unlocked(logro_id):
		texture_path = Score.get_achievement_texture_path(logro_id)
	if texture_path != "":
		sprite.texture = load(texture_path)

func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")
