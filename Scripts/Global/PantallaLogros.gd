extends Node2D

var en: bool = false
# Called when the node enters the scene tree for the first time.

func load_language_setting():
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var json_as_dict = JSON.parse_string(json_as_text)
		en = json_as_dict["english"]
		return
	en = false
	
func update_language_scores_screen():
	if en:
		$Logros.text = "Achievements"
	else:
		$Logros.text = "Logros"

func _ready():
	#Leer archivo
	load_language_setting()
	update_language_scores_screen()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")
	pass # Replace with function body.
