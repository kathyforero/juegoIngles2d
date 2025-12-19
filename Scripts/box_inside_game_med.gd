extends Node2D

# Rutas de las imágenes del juego
const PATH_IMAGE_GAME = "res://Sprites/images_games/"
const EXTENTION_IMAGE_GAME = ".png"
var pausa_menu_scene := preload("res://Escenas/Global/pause_menu.tscn")

# Tiempo inicial para el cronómetro (en segundos)
var time_seconds = 90

# Referencias a los nodos de la interfaz de usuario
@onready var title = $Title  # Nodo de título del juego
@onready var difficulty_value = $Difficulty_value  # Nodo que muestra el valor de la dificultad
@onready var level_label = $HBoxContainer2/Level
@onready var level_value = $HBoxContainer2/Level_value  # Nodo que muestra el nivel actual
@onready var image = $image  # Nodo de imagen dentro del juego
@onready var sentense = $Sentense  # Nodo de frase (que se utiliza cuando se muestra una oración)
@onready var word = $word  # Nodo de palabra
@onready var phrase_text = $phrase_text  # Nodo que muestra texto
@onready var temporizador = $Temporizador  # Nodo de temporizador
@onready var timer = $Temporizador/Timer  # Nodo de Timer que gestiona el cronómetro
@onready var pause_button = $btns_inside_box_game/btn_pausa
@onready var cronometro = $Cronometro

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false

func _ready():
	# Al inicio se ocultan ciertos elementos y se detiene el cronómetro
	en = load_language_setting()
	
	if en:
		level_label.text = "LEVEL:"
	else:
		level_label.text = "NIVEL:"

	if Score.practice_mode:
		if en:
			level_label.text = "Practice"
		else:
			level_label.text = "Práctica"
		cronometro.visible = false
		level_value.visible = false
		pause_button.visible = false
	else:
		level_label.visible = true
		level_value.visible = true
		pause_button.visible = true

	word.visible = false
	sentense.visible = false
	phrase_text.visible = false
	temporizador.visible = false
	timer.stop()

	# Conectar señales para actualizar el título, dificultad, nivel, y manejar el temporizador
	get_parent().connect("update_title", Callable(self, "_on_update_title"))
	get_parent().connect("update_difficulty", Callable(self, "_on_update_difficulty"))
	get_parent().connect("update_level", Callable(self, "_on_update_level"))
	get_parent().connect("set_timer", Callable(self, "_on_set_timer"))

# Función para actualizar el título del juego
func _on_update_title(new_title):
	title.text = new_title
	
# Función para actualizar el valor de la dificultad
func _on_update_difficulty(new_difficulty):
	if en:
		difficulty_value.text = new_difficulty
	else:
		match new_difficulty:
			"Easy":
				difficulty_value.text = "Fácil"
			"Medium":
				difficulty_value.text = "Medio"
			"Hard":
				difficulty_value.text = "Difícil"
			_:
				difficulty_value.text = new_difficulty
	
# Función para actualizar el nivel del juego
func _on_update_level(new_level):
	if Score.practice_mode:
		return   # no actualizamos nada en modo práctica
	level_value.text = new_level
	
# Función para actualizar la imagen del juego
func _on_uptate_imagen_game(new_image):
	var url_image = PATH_IMAGE_GAME + new_image + EXTENTION_IMAGE_GAME
	image.texture = load(url_image)

# Función para ocultar la imagen del juego
func _on_set_not_visible_image():
	image.visible = false
	
# Función para mostrar una frase o oración en el juego
func _on_set_visible_sentence(new_sentence):
	sentense.visible = true
	phrase_text.visible = true
	phrase_text.text = new_sentence
	
# Función para mostrar una palabra en el juego
func _on_set_visible_word(new_word):
	word.visible = true
	phrase_text.visible = true
	phrase_text.add_theme_font_size_override("font_size", 50)
	phrase_text.text = new_word
	
# Función que activa el cronómetro del juego
func _on_set_timer():
	if Score.practice_mode:
		# En modo práctica no hay límite de tiempo
		temporizador.visible = false   # si quieres, también puedes dejarlo visible con "∞"
		return
	temporizador.visible = true
	timer.start()

func _on_timer_timeout():
	if Score.practice_mode:
		# No contamos tiempo ni disparamos lose()
		return

	if time_seconds > 0:
		time_seconds -= 1
	else:
		get_parent().lose()
	temporizador.text = str(time_seconds)

# Función que se ejecuta al presionar el botón de inicio (btn_home)
func _on_btn_home_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")
	
# Función que se ejecuta al presionar el botón de ayuda (btn_help)
func _on_btn_help_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadUnir1.tscn")

# Función que se ejecuta al presionar el botón de instrucciones (btn_instructions)
func _on_btn_instructions_pressed():
	ButtonClick.button_click()
	var padre = get_parent()
	if padre and padre.has_method("_dar_pista"):
		padre._dar_pista()
	else:
		print("No se encontró la función en el nodo padre.")
		
func _on_btn_pausa_pressed() -> void:
	ButtonClick.button_click()

	# Evitar abrir muchas veces el menú
	for child in get_children():
		if child is CanvasLayer and child.get_child_count() > 0 and child.get_child(0) is Control and child.get_child(0).name == "PausaMenu":
			return  # Ya hay uno

	var pausa_instance = pausa_menu_scene.instantiate()
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(pausa_instance)
	add_child(canvas_layer)
