extends Node2D
var nombreEscenaDificultad = "DificultadOracion1.tscn"

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false
	
func update_language_nivel_finalizado():        # tablero
	var lbl   := $Label           # texto “Nivel completado”
	var lbl2   := $Label2         # botón continuar (o el nodo que uses)

	if en:
		lbl.text = "Time's out!"
		lbl2.text = "Try again?"
	else:
		lbl.text = "¡Se acabó el tiempo!"
		lbl2.text = "Intentar de nuevo?"

# Called when the node enters the scene tree for the first time.
func _ready():
	en = load_language_setting()
	update_language_nivel_finalizado()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_casa_button_pressed():
	get_tree().paused = false
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")


func _on_reiniciar_button_pressed():
	get_tree().paused = false
	ButtonClick.button_click()
	get_tree().reload_current_scene()
	pass # Replace with function body.


func _on_niveles_button_pressed():
	get_tree().paused = false
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/"+nombreEscenaDificultad)
	
