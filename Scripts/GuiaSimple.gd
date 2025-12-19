extends Node2D

const SUBJECTS := [
	"El nino",
	"La nina",
	"El estudiante",
	"La maestra",
	"El medico",
	"La familia",
	"El equipo",
	"Mi amiga",
	"El cientifico",
	"La exploradora"
]

const VERBS := [
	"corre",
	"salta",
	"lee",
	"escribe",
	"juega",
	"baila",
	"canta",
	"conduce",
	"explora",
	"observa"
]

const PREDICATES := [
	"en el parque",
	"en la escuela",
	"en casa",
	"en el laboratorio",
	"en el museo",
	"en la ciudad",
	"en el escenario",
	"en el jardin",
	"en la biblioteca",
	"en la playa"
]

const MAX_CARDS := 9

const CATEGORY_DEFINITIONS := [
	{
		"label": "Animales 1",
		"sprites": [
			"res://Sprites/images_games/match/medium/Armadillo.png",
			"res://Sprites/images_games/match/medium/Beaver.png",
			"res://Sprites/images_games/match/medium/Cheetah.png",
			"res://Sprites/images_games/match/medium/Dingo.png",
			"res://Sprites/images_games/match/medium/Emu.png",
			"res://Sprites/images_games/match/medium/Gazelle.png",
			"res://Sprites/images_games/match/medium/Hedgehog.png",
			"res://Sprites/images_games/match/medium/Ibex.png",
			"res://Sprites/images_games/match/medium/Jackal.png"
		]
	},
	{
		"label": "Depredadores",
		"sprites": [
			"res://Sprites/images_games/match/medium/Cheetah.png",
			"res://Sprites/images_games/match/medium/Jackal.png",
			"res://Sprites/images_games/match/medium/Dingo.png",
			"res://Sprites/images_games/match/medium/Ocelot.png",
			"res://Sprites/images_games/match/medium/Gazelle.png"
		]
	},
	{
		"label": "Fauna Exótica",
		"sprites": [
			"res://Sprites/images_games/match/easy/Yellow crowned Night Heron.png",
			"res://Sprites/images_games/match/easy/Woodpecker.png",
			"res://Sprites/images_games/match/easy/Turquoise Butterfly.png",
			"res://Sprites/images_games/match/easy/Squirrel.png",
			"res://Sprites/images_games/match/easy/Squirrel cuckoo.png",
			"res://Sprites/images_games/match/easy/Sloth.png",
			"res://Sprites/images_games/match/easy/Red-crowned parrot.png",
			"res://Sprites/images_games/match/easy/Iguana.png",
			"res://Sprites/images_games/match/easy/Howler monkey.png"
		]
	},
	{
		"label": "Actividades",
		"sprites": [
			"res://Sprites/images_games/puzzle/JUGAR.png",
			"res://Sprites/images_games/puzzle/CANTAR.png",
			"res://Sprites/images_games/puzzle/DIBUJAR.png",
			"res://Sprites/images_games/puzzle/PASEAR_PERRO.png",
			"res://Sprites/images_games/puzzle/PESCA.png",
			"res://Sprites/images_games/puzzle/futbol1.png",
			"res://Sprites/images_games/puzzle/barre.png"
		]
	},
	{
		"label": "Acciones",
		"sprites": [
			"res://Sprites/images_games/puzzle/COCINAR.png",
			"res://Sprites/images_games/puzzle/LAVAR.png",
			"res://Sprites/images_games/puzzle/CLASE.png",
			"res://Sprites/images_games/puzzle/LEER_LIBRO.png",
			"res://Sprites/images_games/puzzle/mates.png",
			"res://Sprites/images_games/puzzle/pesca.png",
			"res://Sprites/images_games/puzzle/PLANTAS.png",
			"res://Sprites/images_games/puzzle/JUGAR.png"
		]
	},
	{
		"label": "Escuela",
		"sprites": [
			"res://Sprites/images_games/puzzle/MOCHILA.png",
			"res://Sprites/images_games/puzzle/LEER_LIBRO.png",
			"res://Sprites/images_games/puzzle/CLASE.png",
			"res://Sprites/images_games/puzzle/PALABRAS.png",
			"res://Sprites/images_games/puzzle/leehoja.png",
			"res://Sprites/images_games/puzzle/UNIVERSO.png"
		]
	},
	{
		"label": "Objetos",
		"sprites": [
			"res://Sprites/images_games/order/Medium/barrio-edificios-arquitectura-forma-casa-png_53876-801494-removebg-preview.png",
			"res://Sprites/images_games/order/Hard/cartel-coche-bicicleta-ciudad-fondo_1307601-5798.jpg",
			"res://Sprites/images_games/order/Hard/dia-mundial-ciudades_1263326-73349-removebg-preview.png",
			"res://Sprites/images_games/order/Hard/ventana-pixelada-escena-flores_603843-977.jpg",
			"res://Sprites/images_games/order/Medium/ChatGPT_Image_15_ago_2025__10_38_09-removebg-preview.png",
			"res://Sprites/images_games/order/Medium/7246619-removebg-preview.png",
			"res://Sprites/images_games/order/Medium/icono-hombre-sonriente-fondo-blanco_1270124-12992-removebg-preview.png",
			"res://Sprites/images_games/order/Medium/papel-viejo-estilo-pixel-art_505135-75-removebg-preview.png",
			"res://Sprites/images_games/order/Medium/ilustracion-pixel-art-miel-pixelada-miel-icono-miel-pixelado-pixel-art_1038602-219-removebg-preview.png"
		]
	}
]

var rng := RandomNumberGenerator.new()
var card_defaults := {}
var category_button_defaults := {}
var selected_category_index := -1
var card_label_texts_by_category := {}
var current_card_label_texts := []
var last_pressed_card := -1
var card_texture_defaults := {}

const CARD_LABELS_PATH := "res://JsonJuegos/CardLabels.json"
const CARD_PRESSED_TEXTURE := preload("res://Sprites/global/cards_pressed.png")

@export var next_scene_path: String = ""
@export var prev_scene_path: String = ""
@export var title_text: String = ""
@export var content_text: String = ""

@onready var title_label: Label = $TitleLabel if has_node("TitleLabel") else null
@onready var content_label: Label = $ContentLabel if has_node("ContentLabel") else null
@onready var next_button: TextureButton = $SiguienteButton if has_node("SiguienteButton") else null
@onready var prev_button: TextureButton = $RetrocederButton if has_node("RetrocederButton") else null
@onready var exit_button: TextureButton = $SalirButton if has_node("SalirButton") else null
@onready var generate_button: TextureButton = $SalirButton2 if has_node("SalirButton2") else null
@onready var subject_label: Label = $Sujeto_txt if has_node("Sujeto_txt") else null
@onready var verb_label: Label = $Verbo_txt if has_node("Verbo_txt") else null
@onready var predicate_label: Label = $Predicado_txt if has_node("Predicado_txt") else null

func _ready():
	rng.randomize()
	_load_card_labels()
	if title_label:
		title_label.text = title_text if title_text != "" else title_label.text
	if content_label:
		content_label.text = content_text if content_text != "" else content_label.text
	if next_button:
		next_button.visible = next_scene_path != ""
	if prev_button:
		prev_button.visible = prev_scene_path != ""
	var generate_handler = Callable(self, "_on_generate_button_pressed")
	if generate_button and not generate_button.is_connected("pressed", generate_handler):
		generate_button.connect("pressed", generate_handler)
	if subject_label and verb_label and predicate_label:
		_generate_sentence()
	_setup_category_system()

func _on_siguiente_button_pressed():
	ButtonClick.button_click()
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)

func _on_retroceder_button_pressed():
	ButtonClick.button_click()
	if prev_scene_path != "":
		get_tree().change_scene_to_file(prev_scene_path)

func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")

func _on_generate_button_pressed():
	ButtonClick.button_click()
	_generate_sentence()

func _generate_sentence():
	if not subject_label or not verb_label or not predicate_label:
		return
	subject_label.text = SUBJECTS[_rand_index(SUBJECTS)]
	verb_label.text = VERBS[_rand_index(VERBS)]
	predicate_label.text = PREDICATES[_rand_index(PREDICATES)]

func _rand_index(list):
	return rng.randi_range(0, max(list.size() - 1, 0))

func _load_card_labels():
	var file = FileAccess.open(CARD_LABELS_PATH, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) != OK:
		return
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return
	var categories = data.get("categories", null)
	if categories and typeof(categories) == TYPE_DICTIONARY:
		card_label_texts_by_category = categories.duplicate()

func _setup_category_system():
	if not _has_category_buttons():
		return
	_record_card_defaults()
	_init_category_buttons()
	_init_card_interactions()
	_update_category_tags()
	_apply_category(0)

func _has_category_buttons() -> bool:
	for i in range(1, CATEGORY_DEFINITIONS.size() + 1):
		if has_node("Categoria%d" % i):
			return true
	return false

func _init_category_buttons():
	for i in range(CATEGORY_DEFINITIONS.size()):
		var button_name = "Categoria%d" % (i + 1)
		if not has_node(button_name):
			continue
		var button = get_node(button_name)
		category_button_defaults[button_name] = button.texture_normal
		var handler = Callable(self, "_on_category_pressed").bind(i)
		if not button.is_connected("pressed", handler):
			button.connect("pressed", handler)

func _init_card_interactions():
	for i in range(1, MAX_CARDS + 1):
		var card = _get_card_node(i)
		if not card:
			continue
		if not card_texture_defaults.has(card.name):
			card_texture_defaults[card.name] = card.texture_normal
		if CARD_PRESSED_TEXTURE:
			card.texture_pressed = CARD_PRESSED_TEXTURE
		var handler = Callable(self, "_on_card_pressed").bind(i)
		if not card.is_connected("pressed", handler):
			card.connect("pressed", handler)

func _update_category_tags():
	for i in range(CATEGORY_DEFINITIONS.size()):
		var button_name = "Categoria%d" % (i + 1)
		if not has_node(button_name):
			continue
		var button = get_node(button_name)
		if not button.has_node("Tag1"):
			continue
		var label = button.get_node("Tag1")
		if label and label is Label:
			label.text = CATEGORY_DEFINITIONS[i]["label"]

func _on_category_pressed(index):
	_apply_category(index)

func _apply_category(index):
	if index < 0 or index >= CATEGORY_DEFINITIONS.size():
		return
	_update_category_selection(index)
	last_pressed_card = -1
	var definitions = CATEGORY_DEFINITIONS[index]["sprites"]
	var visible_count = min(definitions.size(), MAX_CARDS)
	current_card_label_texts = []
	for i in range(MAX_CARDS):
		current_card_label_texts.append("")
	for card_index in range(1, MAX_CARDS + 1):
		var sprite = _get_card_sprite(card_index)
		var card_node = _get_card_node(card_index)
		var label = _get_card_label(card_index)
		if card_index <= visible_count:
			if not sprite:
				if card_node:
					card_node.visible = false
				if label:
					label.visible = false
				continue
			if card_node:
				card_node.visible = true
			var path_index = card_index - 1
			var texture_path = definitions[path_index]
			sprite.texture = load(texture_path)
			current_card_label_texts[card_index - 1] = _label_for_category_label(index, path_index, texture_path)
			sprite.visible = true
			if label:
				label.visible = false
			_set_card_pressed_state(card_index, false)
			_match_card_image(sprite, card_index)
		else:
			if card_node:
				card_node.visible = false
			if label:
				label.visible = false
			_set_card_pressed_state(card_index, false)

func _on_card_pressed(card_index):
	if last_pressed_card != -1 and last_pressed_card != card_index:
		_restore_card(last_pressed_card)
	var sprite = _get_card_sprite(card_index)
	var label = _get_card_label(card_index)
	if sprite:
		sprite.visible = false
	if label:
		label.visible = true
		var text_index = card_index - 1
		if text_index >= 0 and text_index < current_card_label_texts.size():
			label.text = current_card_label_texts[text_index]
	last_pressed_card = card_index
	_set_card_pressed_state(card_index, true)

func _match_card_image(sprite: Sprite2D, card_index: int):
	var card_name = "Card%d" % card_index
	var defaults = card_defaults.get(card_name, null)
	if not defaults:
		var card_node = get_node_or_null(card_name)
		if card_node and card_node is Control:
			sprite.centered = true
			sprite.scale = Vector2.ONE
			sprite.position = card_node.get_size() * 0.5
		return
	sprite.centered = defaults.centered
	sprite.position = defaults.position
	var texture = sprite.texture
	if texture:
		var texture_size = texture.get_size()
		if texture_size.x > 0 and texture_size.y > 0 and defaults.display_size.x > 0 and defaults.display_size.y > 0:
			sprite.scale = Vector2(
				defaults.display_size.x / texture_size.x,
				defaults.display_size.y / texture_size.y
			)
		else:
			sprite.scale = defaults.scale
	else:
		sprite.scale = defaults.scale

func _record_card_defaults():
	for card_index in range(1, MAX_CARDS + 1):
		var sprite = _get_card_sprite(card_index)
		if not sprite:
			continue
		var texture = sprite.texture
		var display_size = Vector2.ZERO
		if texture:
			var texture_size = texture.get_size()
			display_size = Vector2(
				texture_size.x * sprite.scale.x,
				texture_size.y * sprite.scale.y
			) if texture_size.x > 0 and texture_size.y > 0 else Vector2.ZERO
		card_defaults["Card%d" % card_index] = {
			"scale": sprite.scale,
			"position": sprite.position,
			"centered": sprite.centered,
			"display_size": display_size
		}

func _get_card_sprite(card_index):
	var card_name = "Card%d" % card_index
	if not has_node(card_name):
		return null
	var card_node = get_node(card_name)
	if not card_node.has_node("imagen"):
		return null
	var sprite = card_node.get_node("imagen")
	return sprite if sprite is Sprite2D else null

func _get_card_label(card_index):
	var card_node = _get_card_node(card_index)
	if not card_node:
		return null
	var label = card_node.get_node_or_null("Tag1")
	return label if label and label is Label else null

func _get_card_node(card_index):
	var card_name = "Card%d" % card_index
	var node = get_node_or_null(card_name)
	return node if node and node is Control else null

func _set_card_visibility(card_index, visible):
	var card_node = _get_card_node(card_index)
	if not card_node:
		return
	card_node.visible = visible

func _set_card_pressed_state(card_index, pressed):
	var card = _get_card_node(card_index)
	if not card:
		return
	var default_texture = card_texture_defaults.get(card.name, null)
	if pressed and CARD_PRESSED_TEXTURE:
		card.texture_normal = CARD_PRESSED_TEXTURE
	elif default_texture:
		card.texture_normal = default_texture
func _restore_card(card_index):
	if card_index < 1 or card_index > MAX_CARDS:
		return
	var sprite = _get_card_sprite(card_index)
	var label = _get_card_label(card_index)
	if sprite:
		sprite.visible = true
	if label:
		label.visible = false
	_set_card_pressed_state(card_index, false)

func _label_for_category_label(category_index, sprite_index, sprite_path):
	var category_name = CATEGORY_DEFINITIONS[category_index]["label"] if category_index >= 0 and category_index < CATEGORY_DEFINITIONS.size() else ""
	var text_list = card_label_texts_by_category.get(category_name, null)
	if text_list and typeof(text_list) == TYPE_ARRAY and sprite_index < text_list.size():
		return text_list[sprite_index]
	return _derive_label_from_path(sprite_path)

func _derive_label_from_path(sprite_path):
	var name = sprite_path.get_file().get_basename()
	name = name.replace("_", " ").replace("-", " ")
	return name.capitalize()

func _update_category_selection(index):
	selected_category_index = index
	for i in range(CATEGORY_DEFINITIONS.size()):
		var button_name = "Categoria%d" % (i + 1)
		if not has_node(button_name):
			continue
		var button = get_node(button_name)
		var default_normal = category_button_defaults.get(button_name, null)
		if i == index:
			if button.texture_hover:
				button.texture_normal = button.texture_hover
		elif default_normal:
			button.texture_normal = default_normal
