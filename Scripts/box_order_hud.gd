extends Node2D

# Carpeta base de las imágenes de Order It
const PATH_IMAGE_GAME := "res://Sprites/images_games/order/"
const PLACEHOLDER_IMAGE := "placeholder.png"  # <-- tu placeholder

var time_seconds := 120

@onready var title = $Title
@onready var difficulty_value = $Difficulty_value
@onready var level_value = $HBoxContainer2/Level_value
@onready var image = $image
@onready var sentense = $Sentense
@onready var word = $word
@onready var phrase_text = $phrase_text
@onready var temporizador = $Temporizador
@onready var timer = $Temporizador/Timer

func _ready():
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

func _on_update_title(new_title):
	title.text = new_title

func _on_update_difficulty(new_difficulty):
	difficulty_value.text = new_difficulty

func _on_update_level(new_level):
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
	temporizador.visible = true
	temporizador.text = str(time_seconds)
	timer.start()

func _on_timer_timeout():
	if time_seconds > 0:
		time_seconds -= 1
	else:
		get_parent().lose()
	temporizador.text = str(time_seconds)

func _on_btn_home_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")

func _on_btn_help_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/Dificultad_OrderIt.tscn")

func _on_btn_instructions_pressed():
	ButtonClick.button_click()
	var padre = get_parent()
	if padre and padre.has_method("_dar_pista"):
		padre._dar_pista()
	else:
		print("No se encontró la función en el nodo padre.")
