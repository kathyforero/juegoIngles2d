extends Node2D

# Carpeta base de las imágenes de Order It
const PATH_IMAGE_GAME := "res://Sprites/images_games/order/"
const PLACEHOLDER_IMAGE := "placeholder.png"  # <-- tu placeholder

var time_seconds := 120

@onready var title = $Title
@onready var difficulty_value = $Difficulty_value
@onready var level_label = $HBoxContainer2/Level
@onready var level_value = $HBoxContainer2/Level_value
@onready var image = $image
#@onready var sentence = $TextureRect2/Sentence
@onready var sentense = $Sentense
@onready var word = $word
@onready var phrase_text = $phrase_text
@onready var temporizador = $Temporizador
@onready var timer = $Temporizador/Timer
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

	word.visible = false
	sentense.visible = false
	phrase_text.visible = false
	temporizador.visible = false
	timer.stop()

	get_parent().connect("update_title", Callable(self, "_on_update_title"))
	get_parent().connect("update_difficulty", Callable(self, "_on_update_difficulty"))
	get_parent().connect("update_level", Callable(self, "_on_update_level"))
	get_parent().connect("set_timer", Callable(self, "_on_set_timer"))
	get_parent().connect("set_visible_word", Callable(self, "_on_set_visible_word"))
	# señal para cambiar imagen:
	get_parent().connect("uptate_imagen_game", Callable(self, "_on_uptate_imagen_game"))
	_setup_time_attack_ui()
	set_process_unhandled_input(true)
	
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

func _on_update_level(new_level):
	if Score.current_mode == Score.Mode.PRACTICE:
		return
	level_value.text = new_level


func _on_uptate_imagen_game(rel_path):
	# rel_path viene del JSON: "Easy/bird.png", "Easy/bird.jpg", etc.
	var path_str := str(rel_path)
	var url_image := PATH_IMAGE_GAME + path_str

	var tex: Texture2D = load(url_image)

	if tex == null:
		# Fallback a placeholder
		var placeholder_path := PATH_IMAGE_GAME + PLACEHOLDER_IMAGE
		tex = load(placeholder_path)
		if tex == null:
			push_warning("No se pudo cargar imagen ni placeholder: " + url_image)
			return

	var parent_node := get_parent()
	if parent_node == null:
		push_warning("box_order_hud no tiene padre, no se puede colocar la imagen.")
		return

	var imagenes_node: Node2D = null
	if parent_node.has_node("Imagenes"):
		imagenes_node = parent_node.get_node("Imagenes") as Node2D

	var ref_sprite: Sprite2D = null
	if parent_node.has_node("ImagenJuegoVacio"):
		ref_sprite = parent_node.get_node("ImagenJuegoVacio") as Sprite2D
	elif image != null:
		ref_sprite = image

	if imagenes_node == null or ref_sprite == null or ref_sprite.texture == null:
		image.texture = tex
		return

	var target_tex_size: Vector2 = ref_sprite.texture.get_size()
	var target_world_size: Vector2 = target_tex_size * ref_sprite.scale

	var src_size: Vector2 = tex.get_size()
	if src_size.x <= 0.0 or src_size.y <= 0.0:
		push_warning("Textura con tamaño inválido: " + url_image)
		return

	var sx: float = target_world_size.x / src_size.x
	var sy: float = target_world_size.y / src_size.y
	var scale_factor: float = minf(sx, sy)

	for child in imagenes_node.get_children():
		child.queue_free()

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = ref_sprite.position
	imagenes_node.add_child(sprite)


func _on_set_not_visible_image():
	image.visible = false

func _on_set_visible_sentence(new_sentence):
	sentense.visible = true
	phrase_text.visible = true
	phrase_text.text = new_sentence

func _on_set_visible_word(new_word):
	word.visible = true
	phrase_text.visible = true
	phrase_text.add_theme_font_size_override("font_size", 50)
	phrase_text.text = new_word

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

func _on_btn_home_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")


func _on_btn_instructions_pressed():
	ButtonClick.button_click()
	var padre = get_parent()
	if padre and padre.has_method("_dar_pista"):
		padre._dar_pista()
	else:
		print("No se encontró la función en el nodo padre.")

func _setup_time_attack_ui() -> void:
	var is_ta := (Score.current_mode == Score.Mode.TIME_ATTACK)

	if en:
		_score_prefix = "SCORE: "
	else:
		_score_prefix = "PUNTAJE: "

	ta_score_label.visible = is_ta
	ta_delta_label.visible = false
	_delta_base_pos = ta_delta_label.position

	_display_score = 0.0
	_set_display_score(_display_score)

func set_time_attack_score(new_score: int, delta: int = 0) -> void:
	if Score.current_mode != Score.Mode.TIME_ATTACK:
		return

	ta_score_label.visible = true

	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	_score_tween = create_tween()
	_score_tween.set_trans(Tween.TRANS_QUAD)
	_score_tween.set_ease(Tween.EASE_OUT)
	_score_tween.tween_property(self, "_display_score", float(new_score), 0.20)

	var pop := create_tween()
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)
	ta_score_label.scale = Vector2.ONE
	pop.tween_property(ta_score_label, "scale", Vector2(1.12, 1.12), 0.12)
	pop.tween_property(ta_score_label, "scale", Vector2.ONE, 0.12)

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

	if delta > 0:
		ta_delta_label.modulate = Color(0.6, 1.0, 0.6, 1.0)
	else:
		ta_delta_label.modulate = Color(1.0, 0.6, 0.6, 1.0)

	_delta_tween = create_tween()
	_delta_tween.set_trans(Tween.TRANS_QUAD)
	_delta_tween.set_ease(Tween.EASE_OUT)

	# 👇 aquí ya sabes: ajusta hold/fade si quieres más duración
	var up_time := 0.35
	var hold_time := 1.2
	var fade_time := 0.6

	_delta_tween.tween_property(ta_delta_label, "position", _delta_base_pos + Vector2(0, -28), up_time)
	_delta_tween.tween_interval(hold_time)
	_delta_tween.tween_property(ta_delta_label, "modulate:a", 0.0, fade_time)

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
