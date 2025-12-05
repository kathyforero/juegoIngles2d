extends Node2D

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false
	

func update_language_victoria():        # tablero
	var lbl   := $Label          # texto “Nivel completado”
	var btn   := $Button3         # botón continuar (o el nodo que uses)

	if en:
		lbl.text = "CONGRATULATIONS!
YOU HAVE SUCCESFULLY
COMPLETED THE LEVEL"
		btn.icon = load("res://Sprites/buttons/Boton_Next.png")
	else:
		lbl.text = "FELICIDADES!
HAS COMPLETADO CON
ÉXITO EL NIVEL"
		btn.icon = load("res://Sprites/buttons/Boton_Next_es.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	en = load_language_setting()
	update_language_victoria()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_button_continue_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/PuntajeScreen.tscn")
