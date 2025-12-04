extends Control

# Señal que se emite para actualizar la escena, en este caso el menú principal.
signal update_scene(path)

var en: bool = false

# Función que se llama cuando el nodo entra en la escena por primera vez.
# Emite una señal para indicar que se debe mostrar el menú principal.
	
func update_language_buttons():
	if en:
		# Modo inglés: botones en inglés
		$TextureButton.texture_normal  = load("res://Sprites/buttons/btnIngles_en.png")
		$TextureButton2.texture_normal = load("res://Sprites/buttons/btnEspañol_en.png")
	else:
		# Modo español: botones en español (los originales)
		$TextureButton.texture_normal  = load("res://Sprites/buttons/btnIngles.png")
		$TextureButton2.texture_normal = load("res://Sprites/buttons/btnEspaño.png")


func _ready():
	print("ok")
	en = load_language_setting()          # lee el idioma guardado
	update_language_buttons()             # pone los botones correctos
	emit_signal("update_scene", "menu_principal") 
 
# Función que se ejecuta cuando el botón del juego de puzzles es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de Puzzles.
func _on_btn_puzzle_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadOracion1.tscn")

func _on_texturebutton_pressed(): 
	save_language_setting(true)  # Guardar configuración para inglés
	en = load_language_setting()
	update_language_buttons()
	print("Idioma guardado: Inglés") 

func _on_texturebutton2_pressed():
	save_language_setting(false)  # Guardar configuración para español
	en = load_language_setting()
	update_language_buttons()
	print("Idioma guardado: Español")
	
func save_language_setting(is_english: bool):
	var save_data = {"english": is_english} 
	var file = FileAccess.open("res://language_setting.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close() 
	
	
func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	
	return false   # por defecto español

# Función que se ejecuta cuando el botón del juego 'Match It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Match It'.
func _on_btn_match_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadUnir1.tscn")

# Función que se ejecuta cuando el botón del juego 'Order It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Order It'.
func _on_btn_order_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadPalabra1.tscn")
