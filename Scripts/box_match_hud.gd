extends Node2D

# Rutas de las imágenes del juego
const PATH_IMAGE_GAME = "res://Sprites/images_games/match/"
const EXTENTION_IMAGE_GAME = ".png"

# Tiempo inicial para el cronómetro (en segundos)
var time_seconds = 120

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
@onready var cronometro: Sprite2D = $Cronometro
@onready var pause_button = $btns_inside_box_game/btn_pausa

@onready var ta_score_label: Label = $TimeAttackScore
@onready var ta_delta_label: Label = $ScoreDelta

const PAUSE_MENU_SCENE := preload("res://Escenas/Global/pause_menu.tscn")

func _open_pause_menu() -> void:
	# Si ya está pausado, no apiles menús (evita Inception de pausas)
	if get_tree().paused:
		return

	# Evita duplicados si ya existe uno en escena
	if not get_tree().get_nodes_in_group("pause_menu").is_empty():
		return

	var pm := PAUSE_MENU_SCENE.instantiate()
	pm.add_to_group("pause_menu")

	# Asegura que se añada al root de la escena actual (overlay real)
	get_tree().current_scene.add_child(pm)


var _score_prefix := "SCORE: "
var _delta_base_pos: Vector2

var _display_score: float = 0.0 : set = _set_display_score
var _score_tween: Tween
var _delta_tween: Tween

func _set_display_score(v: float) -> void:
	_display_score = v
	if ta_score_label:
		ta_score_label.text = _score_prefix + str(int(round(v)))

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
		
	var is_practice := (Score.current_mode == Score.Mode.PRACTICE)

	if is_practice:
		level_label.text = "Practice" if en else "Práctica"
		level_value.visible = false
		temporizador.visible = false
		cronometro.visible = false
		pause_button.visible = false
		timer.stop()
	else:
		level_value.visible = true
		cronometro.visible = true
		pause_button.visible = true
	
	# Al inicio se ocultan ciertos elementos y se detiene el cronómetro
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
	#get_parent().connect("set_visible_word", Callable(self, "_on_set_visible_word"))
	
	_setup_time_attack_ui()
	set_process_unhandled_input(true)

# Función para actualizar el título del juego
func _on_update_title(new_title):
	title.text = new_title
	
func _on_update_difficulty(new_difficulty):
	if en:
		difficulty_value.text = new_difficulty
	else:
		match new_difficulty:
			"Easy":
				difficulty_value.text = "Fácil"
			"Medium":
				difficulty_value.text = "Medio"
			"Difficult":
				difficulty_value.text = "Difícil"
			_:
				difficulty_value.text = new_difficulty


# Función para actualizar el nivel del juego
func _on_update_level(new_level):
	if Score.current_mode == Score.Mode.PRACTICE:
		return
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
#func _on_set_visible_word(new_word):
	#word.visible = true
	#phrase_text.visible = true
	#phrase_text.add_theme_font_size_override("font_size", 50)
	#phrase_text.text = new_word
	
# Función que activa el cronómetro del juego
func _on_set_timer():
	if Score.current_mode == Score.Mode.PRACTICE:
		temporizador.visible = false
		cronometro.visible = false
		timer.stop()
		return

	temporizador.visible = true
	cronometro.visible = true
	temporizador.text = str(time_seconds)
	timer.start()


# Función que se ejecuta cuando el cronómetro llega a su fin
func _on_timer_timeout():
	if Score.current_mode == Score.Mode.PRACTICE:
		return

	if time_seconds > 0:
		time_seconds -= 1
	else:
		if Score.current_mode == Score.Mode.TIME_ATTACK and get_parent().has_method("finish_time_attack"):
			get_parent().finish_time_attack()
		else:
			get_parent().lose()
	temporizador.text = str(time_seconds)

# Función que se ejecuta al presionar el botón de inicio (btn_home)
func _on_btn_home_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")
	

# Función que se ejecuta al presionar el botón de instrucciones (btn_instructions)
func _on_btn_instructions_pressed():
	ButtonClick.button_click()
	var padre = get_parent()
	if padre and padre.has_method("_dar_pista"):
		padre._dar_pista()
	else:
		print("No se encontró la función en el nodo padre.")
		
func _setup_time_attack_ui() -> void:
	var is_ta := (Score.current_mode == Score.Mode.TIME_ATTACK)

	# Idioma (ya lo usas arriba)
	if en:
		_score_prefix = "SCORE: "
	else:
		_score_prefix = "PUNTAJE: "

	ta_score_label.visible = is_ta
	ta_delta_label.visible = false
	_delta_base_pos = ta_delta_label.position

	# valor por defecto (lo actualizará el padre)
	_display_score = 0.0
	_set_display_score(_display_score)


# Llamado por MatchEasy/Medium/Hard cuando cambie el score
func set_time_attack_score(new_score: int, delta: int = 0) -> void:
	if Score.current_mode != Score.Mode.TIME_ATTACK:
		return

	ta_score_label.visible = true

	# Tween de conteo (suave)
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	_score_tween = create_tween()
	_score_tween.set_trans(Tween.TRANS_QUAD)
	_score_tween.set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(self, "_display_score", float(new_score), 0.20)

	# “Pop” del label principal
	var pop := create_tween()
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)
	ta_score_label.scale = Vector2.ONE
	pop.tween_property(ta_score_label, "scale", Vector2(1.12, 1.12), 0.12)
	pop.tween_property(ta_score_label, "scale", Vector2.ONE, 0.12)

	# Delta flotante (+ / -)
	if delta != 0:
		_show_score_delta(delta)


func _show_score_delta(delta: int) -> void:
	if _delta_tween and _delta_tween.is_valid():
		_delta_tween.kill()

	ta_delta_label.visible = true
	ta_delta_label.position = _delta_base_pos
	ta_delta_label.modulate.a = 1.0

	var sign := "+" if delta > 0 else ""
	ta_delta_label.text = sign + str(delta)

	# Color rápido (si no quieres colores, bórralo)
	if delta > 0:
		ta_delta_label.modulate = Color(0.6, 1.0, 0.6, 1.0) # verde suave
	else:
		ta_delta_label.modulate = Color(1.0, 0.6, 0.6, 1.0) # rojo suave

	_delta_tween = create_tween()
	_delta_tween.set_trans(Tween.TRANS_QUAD)
	_delta_tween.set_ease(Tween.EASE_OUT)

	var dur := 1.8
	_delta_tween.tween_property(ta_delta_label, "position", _delta_base_pos + Vector2(0, -28), dur)
	_delta_tween.parallel().tween_property(ta_delta_label, "modulate:a", 0.0, dur)

	_delta_tween.finished.connect(func():
		ta_delta_label.visible = false
	)


func _on_btn_pausa_pressed() -> void:
	ButtonClick.button_click()

	# Evitar abrir muchas veces el menú
	for child in get_children():
		if child is CanvasLayer and child.get_child_count() > 0 and child.get_child(0) is Control and child.get_child(0).name == "PausaMenu":
			return  # Ya hay uno

	var pausa_instance = PAUSE_MENU_SCENE.instantiate()
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(pausa_instance)
	add_child(canvas_layer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		_open_pause_menu()
		get_viewport().set_input_as_handled()
